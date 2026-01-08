//
//  RecordConsultationViewModel.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 29/07/24.
//

import Foundation
import AVFoundation
import FirebaseFirestore
import SwiftyJSON

public enum RecordConsultationState: Equatable {
  case retry
  case startRecording
  case listening(conversationType: VoiceConversationType)
  case paused
  case processing
  case resultDisplay(success: Bool, value: String?)
  case deletedRecording
  
  public static func == (lhs: RecordConsultationState, rhs: RecordConsultationState) -> Bool {
    switch (lhs, rhs) {
    case
      (.retry, .retry),
      (.startRecording, .startRecording),
      (.processing, .processing),
      (.deletedRecording, .deletedRecording),
      (.paused, .paused):
      return true
    case (.listening(let lhsType), .listening(let rhsType)):
      return lhsType == rhsType
    case (.resultDisplay(let lhsSuccess), .resultDisplay(let rhsSuccess)):
      return lhsSuccess == rhsSuccess
    default:
      return false
    }
  }
}

public enum VoiceConversationType: String {
  case conversation = "consultation"
  case dictation = "dictation"
}

final class RecordingConfiguration {
  
  static let shared = RecordingConfiguration()
  
  var sampleRate: Int = 48000
  var audioBufferSize: Int = 4800
  var conversionFactor: Int = 1 /// Conversion factor to convert to 16khz
  let requiredSampleRate: Int = 16000
  let requiredAudioCaptureMinimumBufferSize = 1600 /// Audio capture minimum buffer size after downsample to 16khz
  let sizedDownMinimumBufferSize = 320 /// Broken down to 20ms chunks from 100ms
  
  func formDeviceConfig(deviceSampleRate: Double) {
    let intDeviceSampleRate = Int(deviceSampleRate)
    audioBufferSize = intDeviceSampleRate / 10
    conversionFactor = intDeviceSampleRate / 16000
  }
}

public final class VoiceToRxViewModel: ObservableObject {
  
  // MARK: - Properties
  
  @Published public var screenState: RecordConsultationState = .startRecording {
    didSet {
      print("Screen state is -> \(screenState)")
      switch screenState {
      case .startRecording, .deletedRecording:
        voiceToRxDelegate?.onVoiceToRxRecordingEnded()
      default:
        voiceToRxDelegate?.onVoiceToRxRecordingStarted()
        break
      }
    }
  }
  /// Don't add duplicates in the set
  @Published public var filesProcessed: Set<String> = []
  @Published public var uploadedFiles: Set<String> = []
  @Published public var amplitude: Float = 0.0
  
  private var docOid: String?
  
  private let audioChunkProcessor = AudioChunkProcessor()
  private let vadAudioChunker = VADAudioChunker()
  lazy var audioChunkUploader = AudioChunkUploader(
    s3FileUploaderService: s3FileUploader,
    voiceToRxRepo: VoiceToRxRepo.shared
  )
  var s3FileUploader = AmazonS3FileUploaderService()
  let s3Listener = AWSS3Listener()
  private let fileRetryService = VoiceToRxFileUploadRetry()
  /// Raw int bytes accumulated till now
  private var pcmBuffersListRaw: [Int16] = []
  private var lastClipIndex: Int = 0
  private var chunkIndex: Int = 1
  private var recordingSession: AVAudioSession?
  private var audioEngine = AVAudioEngine()
  private var filesProcessedListenerReference: (any ListenerRegistration)?
  private var listenerReference: (any ListenerRegistration)?
  private var pollingTimer: Timer?
  
  public var sessionID: UUID?
  public var contextParams: VoiceToRxContextParams?
  weak var voiceToRxDelegate: FloatingVoiceToRxDelegate?
  public var voiceConversationType: VoiceConversationType?
  
  private var emptyResponseCount = 0
  
   // MARK: - Init
  
  public init(
    voiceToRxInitConfig: V2RxInitConfigurations,
    voiceToRxDelegate: FloatingVoiceToRxDelegate?
  ) {
    self.voiceToRxDelegate = voiceToRxDelegate
    deleteAllDataIfDBIsStale()
    setupRecordSession()
    setupDependencies()
    setupContextParams()
    addInterruptionObserver()
  }
  
  private func deleteAllDataIfDBIsStale() {
    guard UserDefaultsHelper.fetch(valueOfType: Bool.self, usingKey: Constants.voiceToRxIsDBStale) == nil else { return }
    deleteAllData()
    UserDefaultsHelper.save(customValue: true, withKey: Constants.voiceToRxIsDBStale)
  }
  
  private func setupContextParams() {
    contextParams = VoiceToRxContextParams(
      doctor: VoiceToRxDoctorProfileInfo(
        id: V2RxInitConfigurations.shared.ownerOID,
        profile: VoiceToRxDoctorProfile(
          personal: VoiceToRxDoctorPersonal(
            name: VoiceToRxDoctorName(
              lastName: "",
              firstName: V2RxInitConfigurations.shared.ownerName
            )
          )
        )
      ),
      patient: VoiceToRxPatientProfileInfo(
        id: V2RxInitConfigurations.shared.subOwnerOID,
        profile: VoiceToRxPatientProfile(
          personal: VoiceToRxPatientPersonal(
            name: V2RxInitConfigurations.shared.subOwnerName
          )
        )
      ),
      visitId: V2RxInitConfigurations.shared.appointmentID
    )
  }
  
  private func setupDependencies() {
    docOid = V2RxInitConfigurations.shared.ownerOID
  }
  
  // MARK: - De-Init
  
  deinit {
    filesProcessedListenerReference?.remove()
    listenerReference?.remove()
    removeInterruptionObserver()
  }
  
  // MARK: - Start Recording
  
  public func startRecording(conversationType: String, inputLanguage: [String], templates: [OutputFormatTemplate], modelType: String) async -> Error? {
    
    guard MicrophoneManager.checkMicrophoneStatus() == .available  else {
      return EkaScribeError.microphonePermissionDenied
    }
    
    voiceConversationType = VoiceConversationType(rawValue: conversationType)
    /// Setup record session
    setupRecordSession()
    /// Clear any previous session data if present
    await MainActor.run { [weak self] in
      guard let self else { return }
      clearSession()
    }
    
    var patientDetails: PatientDetails? = nil
    
    if let oid = V2RxInitConfigurations.shared.subOwnerOID, oid != "" {
      patientDetails = PatientDetails(oid: oid, age: nil, biologicalSex: nil, username: V2RxInitConfigurations.shared.name)
    }
    /// Create session
    let (voiceModel, error) = await VoiceToRxRepo.shared.createVoiceToRxSession(contextParams: contextParams, conversationMode: VoiceConversationType(rawValue: conversationType) ?? .dictation, intpuLanguage: inputLanguage, templates: templates, modelType: modelType, patientDetails: patientDetails)
    guard let voiceModel else {
      /// Change the screen state to deleted recording
      await MainActor.run { [weak self] in
        guard let self else { return }
        screenState = .deletedRecording
        voiceToRxDelegate?.onCreateVoiceToRxSession(id: nil, params: contextParams, error: error)
      }
      return EkaScribeError.freeSessionLimitReached
    }
    /// Delegate to publish everywhere that a session was created
    voiceToRxDelegate?.onCreateVoiceToRxSession(id: voiceModel.sessionID, params: contextParams, error: error)
    /// Setup sessionID in view model
    await MainActor.run { [weak self] in
      guard let self else { return }
      sessionID = voiceModel.sessionID
    }
    /// Change the screen state to listening
    await MainActor.run { [weak self] in
      guard let self else { return }
      screenState = .listening(conversationType: VoiceConversationType(rawValue: conversationType) ?? .dictation)
    }
    do {
      try setupAudioEngineAsync(sessionID: voiceModel.sessionID)
    } catch {
      debugPrint("Audio Engine did not start \(error)")
      return EkaScribeError.audioEngineStartFailed
    }
    return nil
  }
  
  private func setupAudioEngineAsync(sessionID: UUID?) throws {
    guard let sessionID else { return }
    let inputNode = audioEngine.inputNode
    let inputNodeOutputFormat = inputNode.outputFormat(forBus: 0)
    let deviceSampleRate = inputNodeOutputFormat.sampleRate
    /// Set Record Config parameters
    RecordingConfiguration.shared.formDeviceConfig(deviceSampleRate: deviceSampleRate)
    /// Set Vad record config parameters
    audioChunkProcessor.setVadDetectorSampleRate()
    
    inputNode.installTap(
      onBus: 0,
      bufferSize: AVAudioFrameCount(RecordingConfiguration.shared.audioBufferSize),
      format: inputNodeOutputFormat
    ) { [weak self] (buffer, when) in
      guard let self else { return }
      /// Downsample to 16khz
      guard let pcmBuffer = AudioHelper.shared.downSample(
        toSampleRate: Double(RecordingConfiguration.shared.requiredSampleRate),
        buffer: buffer,
        inputNodeOutputFormat: inputNodeOutputFormat
      ) else { return }
      
      /// VAD processing
      Task { [weak self] in
        guard let self else { return }
        try await audioChunkProcessor.processAudioChunk(
          audioEngine: audioEngine,
          buffer: pcmBuffer,
          vadAudioChunker: vadAudioChunker,
          sessionID: sessionID,
          lastClipIndex: &lastClipIndex,
          chunkIndex: &chunkIndex,
          audioChunkUploader: audioChunkUploader,
          pcmBufferListRaw: &pcmBuffersListRaw
        ) { amplitude in
          DispatchQueue.main.async {
            self.amplitude = amplitude
          }
        }
      }
    }
    
    audioEngine.prepare()
    try audioEngine.start()
  }
  
  // MARK: - Stop Recording
  
  public func stopRecording() async {
    guard let sessionID else { return }
    /// Stop audio engine
    stopAudioRecording()
    /// Process whatever is remainingt
    do {
      try await audioChunkProcessor.processAudioChunk(
        audioEngine: audioEngine,
        vadAudioChunker: vadAudioChunker,
        sessionID: sessionID,
        lastClipIndex: &lastClipIndex,
        chunkIndex: &chunkIndex,
        audioChunkUploader: audioChunkUploader,
        pcmBufferListRaw: &pcmBuffersListRaw
      )
      /// Upload full audio
      audioChunkUploader.uploadFullAudio(
        pcmBufferListRaw: pcmBuffersListRaw,
        sessionID: sessionID
      )
      VoiceToRxRepo.shared.stopVoiceToRxSession(sessionID: sessionID) { [weak self] in
        guard let self else { return }
        /// Change screen state to processing
        DispatchQueue.main.async { [weak self] in
          guard let self else { return }
          screenState = .processing
        }
        /// Add listener after stop api
        addListenerOnUploadStatus(sessionID: sessionID)
      }
    } catch {
      debugPrint("Error in processing last audio chunk \(error.localizedDescription)")
    }
  }
  
  private func addListenerOnUploadStatus(sessionID: UUID) {
    VoiceToRxRepo.shared.observeUploadStatusChangesFor(sessionID: sessionID) { [weak self] in
      guard let self else { return }
      /// Call commit api
      VoiceToRxRepo.shared.commitVoiceToRxSession(sessionID: sessionID) { [weak self] in
        guard let self else { return }
        /// Start polling status api
        startStatusPolling()
      }
    }
  }
  
  public func stopAudioRecording() {
    /// Stop audio engine
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
  }
  
  // MARK: - Pause
  
  /// Pauses the audio engine without removing the tap from the input node.
  public func pauseRecording() {
    screenState = .paused
    audioEngine.pause()
  }
  
  // MARK: - Resume
  
  /// Resumes the audio engine and continues the tap on the input node.
  public func resumeRecording() throws {
    guard let voiceConversationType else { return }
    screenState = .listening(conversationType: voiceConversationType)
    audioEngine.prepare()
    try audioEngine.start()
  }
  
  func deleteRecording(id: UUID?) {
    guard let id else { return }
    VoiceToRxRepo.shared.deleteVoiceConversation(fetchRequest: QueryHelper.fetchRequest(for: id))
    screenState = .deletedRecording
  }
}

// MARK: - Helper Functions

extension VoiceToRxViewModel {
  private func setupRecordSession() {
    recordingSession = AVAudioSession.sharedInstance()
    /// Form recording configuration using device information
    do {
      try recordingSession?.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
      try recordingSession?.setPreferredSampleRate(Double(RecordingConfiguration.shared.requiredSampleRate))
      try recordingSession?.setActive(true)
    } catch {
      print("Failed to set up recording session: \(error.localizedDescription)")
    }
  }
  
  /// Create Directory in App Container
  func createDirectoryForGivenSessionId(sessionId: String) {
    /// Create directory with given session id
    do {
      try FileManager.default.createDirectory(at: FileHelper.getDocumentDirectoryURL().appendingPathComponent(sessionId), withIntermediateDirectories: true, attributes: nil)
    } catch {
      print("Error creating directory: \(error)")
    }
  }
}

// MARK: - Listener

extension VoiceToRxViewModel {
  // TODO: - Once we have appointments context
  /// In Appointments Firebase update the voice to rx id against the appointment id
  private func updateAppointmentIdWithVoiceToRxId() {
    guard let apptId = contextParams?.visitId,
          let sessionIdString = sessionID?.uuidString else { return }
    voiceToRxDelegate?.updateAppointmentsData(appointmentID: apptId, voiceToRxID: sessionIdString)
  }
  
  private func stopListenerReference() {
    listenerReference?.remove()
    filesProcessedListenerReference?.remove()
  }
}

// MARK: - Retry

extension VoiceToRxViewModel {
  /// Used to retry file upload if any file was missed
  public func retryIfNeeded() {
    guard let sessionID else { return }
    let directory = FileHelper.getDocumentDirectoryURL().appendingPathComponent(sessionID.uuidString)
    if let unuploadedFileUrls = FileHelper.getFileURLs(in: directory) {
      fileRetryService.retryFilesUpload(
        unuploadedFileUrls: unuploadedFileUrls,
        sessionID: sessionID.uuidString
      ) { [weak self] in
        guard let self else { return }
        /// Update the uploaded files
        uploadedFiles.formUnion(unuploadedFileUrls.map { $0.lastPathComponent })
      }
    }
  }
}

// MARK: - Clear session

extension VoiceToRxViewModel {
  public func deleteAllData() {
    VoiceToRxRepo.shared.deleteAllVoices()
  }
  
  /// Reinitialize all the values to make sure nothing from previouse session remains
  public func clearSession() {
    s3FileUploader = AmazonS3FileUploaderService()
    vadAudioChunker.reset()
    audioChunkUploader.reset()
    pcmBuffersListRaw = []
    lastClipIndex = 0
    chunkIndex = 1
    screenState = .startRecording
    emptyResponseCount = 0
  }
}

// MARK: - Amazon Credentials

extension VoiceToRxViewModel {
  func getAmazonCredentials() {
    let cognitoService = CognitoApiService()
    cognitoService.getAmazonCredentials { result, statusCode in
      switch result {
      case .success(let response):
        guard let credentials = response.credentials else { return }
        AWSConfiguration.shared.configureS3(credentials: credentials)
      case .failure(let error):
        print("Error in fetching aws credentials -> \(error.localizedDescription)")
      }
    }
  }
}

// MARK: - Status polling

extension VoiceToRxViewModel {
  func startStatusPolling() {
    pollingTimer?.invalidate()
    pollingTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] timer in
      guard let self else { return }
      VoiceToRxRepo.shared.fetchVoiceToRxSessionStatus(sessionID: sessionID) { [weak self] result in
        guard let self else { return }
        switch result {
        case .success(let isComplete, let value):
          if isComplete {
            timer.invalidate()
            self.pollingTimer = nil
            print("✅ Polling complete. All templates have status = success.")
            DispatchQueue.main.async { [weak self] in
              guard let self else { return }
              screenState = .resultDisplay(success: true, value: value)
            } 
          } else {
            self.emptyResponseCount += 1
            if self.emptyResponseCount >= 3 {
                print("Stopping polling after 3 empty responses")
                timer.invalidate()
                self.pollingTimer = nil
                DispatchQueue.main.async {
                    self.screenState = .resultDisplay(success: false, value: nil)
                }
            }
        }
          // If not complete, continue polling
        case .failure(let error):
          print("❌ Polling stopped due to API/model error: \(error.localizedDescription)")
          DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            screenState = .resultDisplay(success: false, value: nil)
          }
          timer.invalidate()
          self.pollingTimer = nil
        }
      }
    }
  }
}
