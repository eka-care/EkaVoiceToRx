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
  case processing
  case resultDisplay(success: Bool)
  
  public static func == (lhs: RecordConsultationState, rhs: RecordConsultationState) -> Bool {
    switch (lhs, rhs) {
    case
      (.retry, .retry),
      (.startRecording, .startRecording),
      (.processing, .processing):
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
  case conversation
  case dictation
}

public protocol VoiceToRxViewModelDelegate: AnyObject {
  func onReceiveStructuredRx(id: UUID, transcriptText: String)
  func errorReceivingPrescription(
    id: UUID,
    errorCode: VoiceToRxErrorCode,
    transcriptText: String
  )
  func updateAppointmentsData(appointmentID: String, voiceToRxID: String)
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
  
  @Published public var screenState: RecordConsultationState = .startRecording
  /// Don't add duplicates in the set
  @Published public var filesProcessed: Set<String> = []
  @Published public var uploadedFiles: Set<String> = []
  
  private var docOid: String?
  
  private let audioChunkProcessor = AudioChunkProcessor()
  private let vadAudioChunker = VADAudioChunker()
  lazy var audioChunkUploader = AudioChunkUploader(
    delegate: self,
    s3FileUploaderService: s3FileUploader
  )
  lazy var statusJSONFileMaker = StatusFileMaker(
    delegate: self,
    s3FileUploaderService: s3FileUploader
  )
  let s3FileUploader = AmazonS3FileUploaderService()
  private let fileRetryService = VoiceToRxFileUploadRetry()
  public var sessionID: UUID?
  /// Raw int bytes accumulated till now
  private var pcmBuffersListRaw: [Int16] = []
  private var lastClipIndex: Int = 0
  private var chunkIndex: Int = 1
  private var recordingSession: AVAudioSession?
  private var audioEngine = AVAudioEngine()
  private var filesProcessedListenerReference: (any ListenerRegistration)?
  private var listenerReference: (any ListenerRegistration)?
  
  public var contextParams: VoiceToRxContextParams?
  public weak var delegate: VoiceToRxViewModelDelegate?
  
  public init() {
    setupRecordSession()
    setupDependencies()
    setupContextParams()
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
      )
    )
  }
  
  private func setupDependencies() {
    docOid = V2RxInitConfigurations.shared.ownerOID
  }
  
  deinit {
    filesProcessedListenerReference?.remove()
    listenerReference?.remove()
  }
  
  public func startRecording(conversationType: VoiceConversationType) {
    /// Clear any previous sessions if present
    clearSession()
    /// Change the screen state to listening
    screenState = .listening(conversationType: conversationType)
    /// Session id is set here
    setupSessionInDatabase()
    
    guard let sessionID else { return }
    /// Setup Audio Engine asynchronously
    Task {
      do {
        uploadStatusOfMessageFile(
          conversationType: conversationType,
          sessionID: sessionID,
          fileType: .som
        )
        /// To be uncommented if not testing
        try await setupAudioEngineAsync(sessionID: sessionID)
      } catch {
        debugPrint("Audio Engine did not start \(error)")
      }
    }
  }
  
  private func setupAudioEngineAsync(sessionID: UUID) async throws {
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
      audioChunkProcessor.processAudioChunk(
        audioEngine: audioEngine,
        buffer: pcmBuffer,
        vadAudioChunker: vadAudioChunker,
        sessionID: sessionID,
        lastClipIndex: &lastClipIndex,
        chunkIndex: &chunkIndex,
        audioChunkUploader: audioChunkUploader,
        pcmBufferListRaw: &pcmBuffersListRaw
      )
    }
    
    audioEngine.prepare()
    try audioEngine.start()
  }
  
  public func stopRecording() {
    guard let sessionID else { return }
    /// Change screen state to processing
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      screenState = .processing
    }
    DispatchQueue.global().async { [weak self] in
      guard let self else { return }
      /// Stop audio engine
      audioEngine.stop()
      audioEngine.inputNode.removeTap(onBus: 0)
      
      /// Process whatever is remaining
      audioChunkProcessor.processAudioChunk(
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
      
      /// To be shown for steps in processing
      listenForFilesProcessed()
      /// Upload EOF File
      statusJSONFileMaker.uploadStatusFile(
        docOid: docOid ?? "",
        uploadedFilesKeys: audioChunkUploader.uploadedFileKeys,
        fileUploadMapper: audioChunkUploader.fileUploadMapper,
        domainName: s3FileUploader.domainName,
        bucketName: s3FileUploader.bucketName,
        dateFolderName: s3FileUploader.dateFolderName,
        sessionId: sessionID.uuidString,
        conversationType: nil,
        fileChunksInfo: audioChunkUploader.fileChunksInfo,
        contextData: contextParams,
        fileType: .eof
      )
      /// Listend for structured rx from firebase
      listenForStructuredRx()
    }
  }
}

// MARK: - Helper Functions

extension VoiceToRxViewModel {
  private func setupRecordSession() {
    recordingSession = AVAudioSession.sharedInstance()
    /// Form recording configuration using device information
    do {
      try recordingSession?.setCategory(.playAndRecord, mode: .voiceChat, options: [.duckOthers])
      try recordingSession?.setPreferredSampleRate(Double(RecordingConfiguration.shared.requiredSampleRate))
      //      try recordingSession?.setInputGain(<#T##gain: Float##Float#>)
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
  
  private func uploadStatusOfMessageFile(
    conversationType: VoiceConversationType,
    sessionID: UUID,
    fileType: StatusFileType
  ) {
    statusJSONFileMaker.uploadStatusFile(
      docOid: docOid ?? "",
      uploadedFilesKeys: audioChunkUploader.uploadedFileKeys,
      fileUploadMapper: audioChunkUploader.fileUploadMapper,
      domainName: s3FileUploader.domainName,
      bucketName: s3FileUploader.bucketName,
      dateFolderName: s3FileUploader.dateFolderName,
      sessionId: sessionID.uuidString,
      conversationType: conversationType,
      contextData: contextParams,
      fileType: fileType
    )
  }
  
  /// Setup VoiceToRx Model
  private func setupSessionInDatabase() {
    let model = VoiceConversationModel(fileURL: nil, date: .now, transcriptionText: "")
    sessionID = model.id
    createDirectoryForGivenSessionId(sessionId: model.id.uuidString)
    Task {
      try await VoiceConversationAggregator.shared.saveVoice(model: model)
    }
  }
}

// MARK: - AudioChunkUploaderDelegate

extension VoiceToRxViewModel: AudioChunkUploaderDelegate {
  func fileUploadMapperDidChange(_ updatedMap: [String]) {}
}

// MARK: - StatusFileDelegate

extension VoiceToRxViewModel: StatusFileDelegate {
  func statusFileUrlsMapChanged(statusFileUrls: [URL]) {
    guard let lastUrlAppended = statusFileUrls.last?.lastPathComponent else { return }
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      uploadedFiles.insert(lastUrlAppended)
    }
  }
}

// MARK: - Listener

extension VoiceToRxViewModel {
  private func listenForFilesProcessed() {
    guard let sessionID else { return }
    VoiceToRxFirestoreManager.shared.listenForFilesProcessed(
      sessionID: sessionID.uuidString
    ) { [weak self] documentsProcessed, listenerReference in
      guard let self else { return }
      filesProcessedListenerReference = listenerReference
      /// UI changes in main thread
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        filesProcessed = documentsProcessed
        uploadedFiles = uploadedFiles.union(audioChunkUploader.uploadedFileKeys)
      }
    }
  }
  
  func listenForStructuredRx() {
    guard let sessionID else { return }
    /// Listen for structured rx
    VoiceToRxFirestoreManager.shared.listenForStructuredRx(
      sessionId: sessionID.uuidString
    ) { [weak self] transcriptionString, prescriptionString, errorStructuredRx, listenerReference in
      guard let self else { return }
      self.listenerReference = listenerReference
      updateAppointmentIdWithVoiceToRxId()
      if let errorStructuredRx, errorStructuredRx == .smallTranscript {
        screenState = .resultDisplay(success: false)
        delegate?.errorReceivingPrescription(id: sessionID, errorCode: errorStructuredRx, transcriptText: transcriptionString ?? "")
      } else {
        screenState = .resultDisplay(success: true)
        delegate?.onReceiveStructuredRx(id: sessionID, transcriptText: transcriptionString ?? "")
      }
      /// Once we have the parsed text stop listener reference
      stopListenerReference()
    }
  }
  
  // TODO: - Once we have appointments context
  /// In Appointments Firebase update the voice to rx id against the appointment id
  private func updateAppointmentIdWithVoiceToRxId() {
        guard let apptId = contextParams?.visitId,
        let sessionIdString = sessionID?.uuidString else { return }
    delegate?.updateAppointmentsData(appointmentID: apptId, voiceToRxID: sessionIdString)
  }
  
  private func stopListenerReference() {
    listenerReference?.remove()
    filesProcessedListenerReference?.remove()
  }
}

extension VoiceToRxViewModel {
  /// Used to setup session id
  public func setupSessionID(sessionID: UUID?) {
    self.sessionID = sessionID
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
        /// listen for files processed
        listenForFilesProcessed()
        listenForStructuredRx()
      }
    }
  }
}

// MARK: - Clear session

extension VoiceToRxViewModel {
  public func deleteAllData() {
    Task {
      await VoiceConversationAggregator.shared.deleteAll()
    }
  }
  
  /// Reinitialize all the values to make sure nothing from previouse session remains
  public func clearSession() {
    vadAudioChunker.reset()
    audioChunkUploader.reset()
    pcmBuffersListRaw = []
    lastClipIndex = 0
    chunkIndex = 1
    sessionID = nil
  }
}
