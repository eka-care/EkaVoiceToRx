# EkaVoiceToRx



A Swift package for voice-to-prescription functionality with floating UI components, audio recording, and real-time transcription capabilities for medical consultation applications.

## Overview

EkaVoiceToRx empowers healthcare applications with advanced voice recording and transcription capabilities. It provides a seamless integration for medical consultation workflows, enabling doctors to record patient interactions and automatically generate prescriptions through AI-powered voice analysis.

## Requirements

- **iOS**: 17.0+
- **Swift**: 5.10+
- **Xcode**: 15.0+

### System Permissions

Add the following permissions to your app's `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record medical consultations</string>
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs network access to upload and process audio recordings</string>
```

## Installation

### Swift Package Manager

Add EkaVoiceToRx to your project using Swift Package Manager:

1. In Xcode, select **File → Add Package Dependencies**

2. Enter the repository URL:

   ```
   https://github.com/eka-care/EkaVoiceToRx.git
   ```

3. Choose the version or branch

4. Add to your target

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/eka-care/EkaVoiceToRx.git", from: "1.0.0")
]
```

## Quick Start

Here's a minimal example to get you started:

```swift
import EkaVoiceToRx
import SwiftUI

class ConsultationViewController: UIViewController {
    private var viewModel: VoiceToRxViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVoiceToRx()
    }

    private func setupVoiceToRx() {
        // Configure the package
        configureEkaVoiceToRx()

        // Initialize view model
        viewModel = VoiceToRxViewModel(
            voiceToRxInitConfig: V2RxInitConfigurations.shared,
            voiceToRxDelegate: self
        )

        // Show floating interface
        Task {
            await showFloatingRecordingInterface()
        }
    }

    private func configureEkaVoiceToRx() {
        // Configure authentication
        configureAuthentication()

        // Configure session parameters
        let config = V2RxInitConfigurations.shared
        config.ownerName = "Dr. Smith"
        config.ownerOID = "doctor123"
        config.ownerUUID = "doctor-uuid-123"
        config.subOwnerName = "John Doe"
        config.subOwnerOID = "patient456"
        config.appointmentID = "appointment789"
        config.name = "John Doe" // Name for backend
        config.clientId = "your-client-id"
        config.awsS3BucketName = "your-s3-bucket-name"

        // Configure database context (SwiftData)
        config.modelContainer = SwiftDataRepoContext.modelContext.container
    }

    private func configureAuthentication() {
        // Set up authentication tokens
        AuthTokenHolder.shared.authToken = KeychainHelper.fetchAuthToken()
        AuthTokenHolder.shared.refreshToken = KeychainHelper.fetchRefreshToken()
        AuthTokenHolder.shared.bid = JWTDecoder.shared.businessId
    }

    private func showFloatingRecordingInterface() async {
        let templates = [
            OutputFormatTemplate(
                templateID: "template-id-here",
                templateType: .defaultType,
                templateName: "SOAP Note"
            )
        ]

        let error = await FloatingVoiceToRxViewController.shared.showFloatingButton(
            viewModel: viewModel!,
            conversationType: "consultation",
            inputLanguage: ["en-IN"],
            templates: templates,
            modelType: "pro",
            liveActivityDelegate: nil
        )

        if let error = error {
            print("Error showing floating button: \(error)")
        }
    }
}

// MARK: - FloatingVoiceToRxDelegate

extension ConsultationViewController: FloatingVoiceToRxDelegate {
    func onCreateVoiceToRxSession(id: UUID?, params: VoiceToRxContextParams?, error: APIError?) {
        if let error = error {
            print("Error creating session: \(error)")
            return
        }
        print("Session created with ID: \(id?.uuidString ?? "unknown")")
    }

    func moveToDeepthoughtPage(id: UUID) {
        // Navigate to prescription results page
        print("Moving to results page for session: \(id)")
    }

    func errorReceivingPrescription(id: UUID, errorCode: VoiceToRxErrorCode, transcriptText: String) {
        print("Error in session \(id): \(errorCode)")
    }

    func updateAppointmentsData(appointmentID: String, voiceToRxID: String) {
        print("Updated appointment \(appointmentID) with voice session \(voiceToRxID)")
    }

    func onVoiceToRxRecordingStarted() {
        print("Recording started")
    }

    func onVoiceToRxRecordingEnded() {
        print("Recording ended")
    }

    func onResultValueReceived(value: String) {
        print("Result value received: \(value)")
    }
}
```

## Core Components

### VoiceToRxViewModel

The central view model that manages the entire voice recording and processing workflow.

```swift
public class VoiceToRxViewModel: ObservableObject {
    @Published public var screenState: RecordConsultationState
    @Published public var filesProcessed: Set<String>
    @Published public var uploadedFiles: Set<String>
    @Published public var amplitude: Float

    public var sessionID: UUID?
    public var contextParams: VoiceToRxContextParams?
    public var voiceConversationType: VoiceConversationType?
}
```

### Recording States

```swift
public enum RecordConsultationState: Equatable {
    case retry                          // Ready to retry after error
    case startRecording                 // Initial state, ready to start
    case listening(conversationType: VoiceConversationType) // Currently recording
    case paused                        // Recording paused
    case processing                    // Processing audio/generating prescription
    case resultDisplay(success: Bool, value: String?)  // Showing results with optional value
    case deletedRecording             // Recording deleted
}
```

### Conversation Types

```swift
public enum VoiceConversationType: String {
    case conversation = "consultation"  // Doctor-patient conversation
    case dictation = "dictation"        // Direct prescription dictation
}
```

### FloatingVoiceToRxViewController

Provides a system-wide floating interface for recording control, similar to FaceTime's picture-in-picture.

```swift
public class FloatingVoiceToRxViewController: UIViewController {
    public static let shared = FloatingVoiceToRxViewController()

    public var isFloatingWindowBusy: Bool { get }

    public func showFloatingButton(
        viewModel: VoiceToRxViewModel,
        conversationType: String,
        inputLanguage: [String],
        templates: [OutputFormatTemplate],
        modelType: String = "pro",
        liveActivityDelegate: LiveActivityDelegate?
    ) async -> Error?

    public func showFloatingButtonSafely(
        viewModel: VoiceToRxViewModel,
        conversationType: String,
        inputLanguage: [String],
        templates: [OutputFormatTemplate],
        modelType: String,
        liveActivityDelegate: LiveActivityDelegate?,
        completion: @escaping (Bool) -> Void
    )

    public func hideFloatingButton()
}
```

### Configuration Classes

### V2RxInitConfigurations

Central configuration object for session parameters:

```swift
public class V2RxInitConfigurations {
    public static let shared = V2RxInitConfigurations()

    public var clientId: String?
    public var awsS3BucketName: String?
    public var ownerName: String?          // Doctor name
    public var ownerOID: String?           // Doctor ID
    public var ownerUUID: String?          // Doctor UUID
    public var subOwnerOID: String?        // Patient ID
    public var appointmentID: String?      // Appointment identifier
    public var subOwnerName: String?       // Patient name
    public var name: String?               // Name for backend
    public var modelContainer: ModelContainer!  // SwiftData model container
    public weak var delegate: EventLoggerProtocol?  // Event logging delegate
}
```

### OutputFormatTemplate

Output template configuration:

```swift
public struct OutputFormatTemplate: Codable {
    public enum TemplateType: String {
        case defaultType = "default"
        case customType = "custom"
    }

    public let templateID: String
    public let templateType: String
    public let templateName: String

    public init(
        templateID: String,
        templateType: TemplateType,
        templateName: String
    )
}
```

### PatientDetails

Patient information for session context:

```swift
public struct PatientDetails: Codable {
    public let oid: String?
    public let age: Int?
    public let biologicalSex: String?
    public let username: String?
}
```

**Note**: `PatientDetails` is automatically created from `V2RxInitConfigurations` if `subOwnerOID` is provided. You typically don't need to create this manually.

## Integration Guide

### Step 1: Configure Dependencies

Set up authentication and core configurations:

```swift
private func configureAuthentication() {
    // Set up authentication tokens
    AuthTokenHolder.shared.authToken = KeychainHelper.fetchAuthToken()
    AuthTokenHolder.shared.refreshToken = KeychainHelper.fetchRefreshToken()
    AuthTokenHolder.shared.bid = JWTDecoder.shared.businessId
}

private func configureSessionParameters() {
    let config = V2RxInitConfigurations.shared

    // Doctor information
    config.ownerName = doctorName
    config.ownerOID = doctorOID
    config.ownerUUID = doctorUUID

    // Patient information
    config.subOwnerName = patientName
    config.subOwnerOID = patientOID
    config.name = patientName  // Name for backend

    // Appointment context
    config.appointmentID = appointmentID

    // AWS Configuration
    config.clientId = "your-client-id"
    config.awsS3BucketName = "your-s3-bucket-name"

    // Database context (SwiftData)
    config.modelContainer = SwiftDataRepoContext.modelContext.container
}
```

### Step 2: Implement Required Delegates

### FloatingVoiceToRxDelegate (Required)

```swift
extension YourViewController: FloatingVoiceToRxDelegate {
    func onCreateVoiceToRxSession(id: UUID?, params: VoiceToRxContextParams?, error: APIError?) {
        guard let sessionId = id,
              let patientId = params?.patient?.id else {
            print("Failed to create session - missing required parameters")
            return
        }

        // Create local database entry
        createLocalSessionRecord(sessionId: sessionId, patientId: patientId)

        // Update UI to reflect active session
        updateUIForActiveSession(sessionId)
    }

    func moveToDeepthoughtPage(id: UUID) {
        // Navigate to prescription review/edit page
        let storyboard = UIStoryboard(name: "Prescription", bundle: nil)
        guard let prescriptionVC = storyboard.instantiateViewController(
            withIdentifier: "PrescriptionViewController"
        ) as? PrescriptionViewController else { return }

        prescriptionVC.sessionID = id
        prescriptionVC.isEditMode = true
        navigationController?.pushViewController(prescriptionVC, animated: true)
    }

    func errorReceivingPrescription(id: UUID, errorCode: VoiceToRxErrorCode, transcriptText: String) {
        handleTranscriptionError(
            sessionId: id,
            error: errorCode,
            transcript: transcriptText
        )
    }

    func updateAppointmentsData(appointmentID: String, voiceToRxID: String) {
        // Update appointment record with voice session reference
        Task {
            await AppointmentService.shared.updateAppointment(
                id: appointmentID,
                voiceSessionId: voiceToRxID
            )
        }
    }

    func onVoiceToRxRecordingStarted() {
        // Handle recording started event
        print("Recording started")
    }

    func onVoiceToRxRecordingEnded() {
        // Handle recording ended event
        print("Recording ended")
    }

    func onResultValueReceived(value: String) {
        // Handle result value received
        print("Result value: \(value)")
    }
}
```

### LiveActivityDelegate (Optional)

For iOS Live Activities support during recording:

```swift
extension YourViewController: LiveActivityDelegate {
    func startLiveActivity(patientName: String) async {
        guard #available(iOS 16.1, *) else { return }

        let attributes = RecordingActivityAttributes(patientName: patientName)
        let initialState = RecordingActivityState(
            status: "Recording consultation...",
            startTime: Date()
        )

        do {
            let activity = try Activity<RecordingActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func endLiveActivity() async {
        guard #available(iOS 16.1, *) else { return }

        for activity in Activity<RecordingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
```

### Step 3: Initialize and Control Recording

```swift
class ConsultationViewController: UIViewController {
    private var viewModel: VoiceToRxViewModel?
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVoiceToRx()
        observeRecordingStates()
    }

    private func setupVoiceToRx() {
        viewModel = VoiceToRxViewModel(
            voiceToRxInitConfig: V2RxInitConfigurations.shared,
            voiceToRxDelegate: self
        )
    }

    private func observeRecordingStates() {
        viewModel?.$screenState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }

    private func handleStateChange(_ state: RecordConsultationState) {
        switch state {
        case .startRecording:
            updateUI(status: "Ready to record")
        case .listening(let conversationType):
            updateUI(status: "Recording \(conversationType.rawValue)...")
        case .paused:
            updateUI(status: "Recording paused")
        case .processing:
            updateUI(status: "Processing audio...")
            showProcessingIndicator()
        case .resultDisplay(let success, let value):
            hideProcessingIndicator()
            if success {
                showSuccessMessage()
                if let value = value {
                    print("Result value: \(value)")
                }
            } else {
                showErrorMessage()
            }
        case .deletedRecording:
            updateUI(status: "Recording deleted")
        case .retry:
            updateUI(status: "Ready to retry")
        }
    }

    // MARK: - Recording Controls

    @IBAction func startRecordingTapped(_ sender: UIButton) {
        Task {
            await startRecording()
        }
    }

    @IBAction func pauseRecordingTapped(_ sender: UIButton) {
        viewModel?.pauseRecording()
    }

    @IBAction func resumeRecordingTapped(_ sender: UIButton) {
        do {
            try viewModel?.resumeRecording()
        } catch {
            showError("Failed to resume recording: \(error.localizedDescription)")
        }
    }

    @IBAction func stopRecordingTapped(_ sender: UIButton) {
        Task {
            await viewModel?.stopRecording()
        }
    }

    private func startRecording() async {
        // Prepare templates
        let templates = [
            OutputFormatTemplate(
                templateID: "template-id-here",
                templateType: .defaultType,
                templateName: "SOAP Note"
            )
        ]

        // Start recording - this will automatically show the floating interface
        let error = await viewModel?.startRecording(
            conversationType: "consultation",
            inputLanguage: ["en-IN"],
            templates: templates,
            modelType: "pro"
        )

        if let error = error {
            showError("Failed to start recording: \(error.localizedDescription)")
        }
    }
}
```

## Configuration

### Audio Configuration

EkaVoiceToRx automatically configures optimal audio settings. The SDK uses:

- **Sample Rate**: 48kHz (device-dependent, automatically configured)
- **Processing Rate**: 16kHz (required for VAD and processing)
- **Buffer Size**: Automatically calculated based on device sample rate
- **Audio Format**: PCM 16-bit

Audio configuration is handled automatically by the `RecordingConfiguration` class.

### Network Configuration

Network configuration is handled automatically by the SDK. The SDK uses the configured base URL and authentication tokens from `AuthTokenHolder`.

## Authentication & Token Management

The SDK uses `AuthTokenHolder` for authentication. Configure it before initializing the SDK:

```swift
// Set up authentication tokens
AuthTokenHolder.shared.authToken = KeychainHelper.fetchAuthToken()
AuthTokenHolder.shared.refreshToken = KeychainHelper.fetchRefreshToken()
AuthTokenHolder.shared.bid = JWTDecoder.shared.businessId
```

The SDK automatically handles token refresh when tokens expire. Ensure `AuthTokenHolder` is updated with refreshed tokens when your app refreshes them.

### Session Management

```swift
// Clear session data
viewModel.clearSession()

// Retry failed operations (retries uploading failed files)
viewModel.retryIfNeeded()

// Delete all voice data (use with caution)
viewModel.deleteAllData()

// Stop audio recording (stops the audio engine)
viewModel.stopAudioRecording()

// Delete a specific recording
viewModel.deleteRecording(id: sessionID)
```

**Note**: Session results are delivered through the `FloatingVoiceToRxDelegate` callbacks:

- `onCreateVoiceToRxSession` - Called when session is created
- `moveToDeepthoughtPage` - Called when results are ready
- `onResultValueReceived` - Called when result value is received
- `errorReceivingPrescription` - Called if there's an error

### Custom UI Integration

```swift
// Create custom SwiftUI view with EkaVoiceToRx
struct CustomRecordingView: View {
    @ObservedObject var viewModel: VoiceToRxViewModel

    var body: some View {
        VStack {
            // Recording status
            Text(recordingStatusText)
                .font(.headline)
                .foregroundColor(statusColor)

            // Control buttons
            HStack {
                Button(action: startRecording) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                }

                Button(action: pauseRecording) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                }

                Button(action: stopRecording) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                }
            }

            // Progress indicator
            if case .processing = viewModel.screenState {
                ProgressView("Processing audio...")
                    .padding()
            }
        }
        .padding()
    }

    private var recordingStatusText: String {
        switch viewModel.screenState {
        case .startRecording: return "Ready to Record"
        case .listening(let type): return "Recording \(type.rawValue.capitalized)"
        case .paused: return "Paused"
        case .processing: return "Processing..."
        case .resultDisplay(let success, _): return success ? "Complete" : "Error"
        case .deletedRecording: return "Deleted"
        case .retry: return "Ready to Retry"
        }
    }

    private var statusColor: Color {
        switch viewModel.screenState {
        case .listening: return .red
        case .paused: return .orange
        case .processing: return .blue
        case .resultDisplay(let success, _): return success ? .green : .red
        default: return .primary
        }
    }
}
```

## Advanced Features

### Real-time Amplitude Monitoring

Monitor real-time audio amplitude during recording:

```swift
import Combine

class RecordingMonitor {
    private var cancellables = Set<AnyCancellable>()

    func observeAmplitude(viewModel: VoiceToRxViewModel) {
        viewModel.$amplitude
            .receive(on: DispatchQueue.main)
            .sink { [weak self] amplitude in
                self?.handleAmplitude(amplitude)
            }
            .store(in: &cancellables)
    }

    private func handleAmplitude(_ amplitude: Float) {
        // Update UI with amplitude indicators
        updateAmplitudeIndicator(amplitude: amplitude)
    }
}
```
## Best Practices

### Memory Management

```swift
class ConsultationViewController: UIViewController {
    private var viewModel: VoiceToRxViewModel?
    private var cancellables = Set<AnyCancellable>()

    deinit {
        // Clean up resources
        viewModel?.clearSession()
        cancellables.removeAll()

        // Hide floating interface
        Task {
            FloatingVoiceToRxViewController.shared.hideFloatingButton()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause recording when leaving screen
        if case .listening = viewModel?.screenState {
            viewModel?.pauseRecording()
        }
    }
}
```

### Network Optimization

```swift
private func setupNetworkMonitoring() {
    // Monitor network connectivity for reliable uploads
    let monitor = NWPathMonitor()
    monitor.pathUpdateHandler = { [weak self] path in
        DispatchQueue.main.async {
            if path.status == .satisfied {
                // Network available - retry failed uploads
                self?.viewModel?.retryIfNeeded()
            } else {
                // Network unavailable - inform user
                self?.showNetworkUnavailableWarning()
            }
        }
    }

    let queue = DispatchQueue(label: "NetworkMonitor")
    monitor.start(queue: queue)
}
```

### Performance Optimization

```swift
// Optimize for long recording sessions
private func optimizeForLongSessions() {
    // Configure audio session for extended use
    let audioSession = AVAudioSession.sharedInstance()
    try? audioSession.setCategory(
        .playAndRecord,
        mode: .voiceChat,
        options: [.defaultToSpeaker, .allowBluetooth]
    )

    // Enable low-power mode optimizations
    ProcessInfo.processInfo.performActivity(
        options: .automaticTerminationDisabled,
        reason: "Recording medical consultation"
    ) { /* recording activity */ }
}
```

## API Reference

### VoiceToRxViewModel

### Properties

```swift
// Published properties for UI binding
@Published public var screenState: RecordConsultationState
@Published public var filesProcessed: Set<String>
@Published public var uploadedFiles: Set<String>
@Published public var amplitude: Float

// Session information
public var sessionID: UUID?
public var contextParams: VoiceToRxContextParams?
public var voiceConversationType: VoiceConversationType?
```

### Methods

```swift
// Core recording methods
public func startRecording(
    conversationType: String,           // "consultation" or "dictation"
    inputLanguage: [String],            // Language codes like ["en-IN"]
    templates: [OutputFormatTemplate],  // Output format templates
    modelType: String                   // "pro" or "lite"
) async -> Error?

public func stopRecording() async
public func stopAudioRecording()
public func pauseRecording()
public func resumeRecording() throws

// Session management
public func retryIfNeeded()
public func deleteAllData()
public func clearSession()
public func deleteRecording(id: UUID?)

// Initialization
public init(
    voiceToRxInitConfig: V2RxInitConfigurations,
    voiceToRxDelegate: FloatingVoiceToRxDelegate?
)
```

### FloatingVoiceToRxViewController

### Properties

```swift
public static let shared: FloatingVoiceToRxViewController
public var isFloatingWindowBusy: Bool { get }
public var viewModel: VoiceToRxViewModel?
public weak var liveActivityDelegate: LiveActivityDelegate?
```

### Methods

```swift
// Show/hide floating interface
public func showFloatingButton(
    viewModel: VoiceToRxViewModel,
    conversationType: String,
    inputLanguage: [String],
    templates: [OutputFormatTemplate],
    modelType: String = "pro",
    liveActivityDelegate: LiveActivityDelegate?
) async -> Error?

public func showFloatingButtonSafely(
    viewModel: VoiceToRxViewModel,
    conversationType: String,
    inputLanguage: [String],
    templates: [OutputFormatTemplate],
    modelType: String,
    liveActivityDelegate: LiveActivityDelegate?,
    completion: @escaping (Bool) -> Void
)

public func hideFloatingButton()
```

### Delegate Protocols

### FloatingVoiceToRxDelegate

```swift
protocol FloatingVoiceToRxDelegate: AnyObject {
    func onCreateVoiceToRxSession(id: UUID?, params: VoiceToRxContextParams?, error: APIError?)
    func moveToDeepthoughtPage(id: UUID)
    func errorReceivingPrescription(id: UUID, errorCode: VoiceToRxErrorCode, transcriptText: String)
    func updateAppointmentsData(appointmentID: String, voiceToRxID: String)
    func onVoiceToRxRecordingStarted()
    func onVoiceToRxRecordingEnded()
    func onResultValueReceived(value: String)
}
```

### LiveActivityDelegate

```swift
protocol LiveActivityDelegate: AnyObject {
    func startLiveActivity(patientName: String) async
    func endLiveActivity() async
}
```

### Configuration Classes

### V2RxInitConfigurations

```swift
public class V2RxInitConfigurations {
    public static let shared: V2RxInitConfigurations

    // Core identifiers
    public var clientId: String?
    public var awsS3BucketName: String?
    public var ownerName: String?      // Doctor name
    public var ownerOID: String?       // Doctor OID
    public var ownerUUID: String?     // Doctor UUID
    public var subOwnerOID: String?    // Patient OID
    public var subOwnerName: String?   // Patient name
    public var name: String?           // Name for backend
    public var appointmentID: String?  // Appointment ID

    // Data context
    public var modelContainer: ModelContainer!
    public weak var delegate: EventLoggerProtocol?
}
```

### AuthTokenHolder

```swift
public class AuthTokenHolder {
    public static let shared: AuthTokenHolder
    public var authToken: String?
    public var refreshToken: String?
    public var bid: String?
}
```
### VoiceToRxRepo

The `VoiceToRxRepo` class is the central repository for managing voice-to-prescription sessions. It handles session lifecycle, database operations, API calls, and provides access to templates and configuration.

```swift
public final class VoiceToRxRepo {
    public static let shared: VoiceToRxRepo
}
```
#### Status and Results Methods

##### Fetch Result Status Response

Fetches the full status response for a session, including all template results, transcript data, structured Rx, and metadata. This provides comprehensive information about the processing status of all templates in a session.

```swift
public func fetchResultStatusResponse(
    sessionID: String,
    completion: @escaping (Result<VoiceToRxStatusResponse, Error>) -> Void
)
```

**Parameters:**
- `sessionID`: String representation of the session UUID
- `completion`: Completion handler with full status response

**Response Structure:**
The response includes:
- `data.templateResults.custom`: Array of custom template outputs with status, value, and errors
- `data.templateResults.transcript`: Array of transcript outputs
- `data.audioMatrix`: Audio quality metrics
- Each template result contains:
  - `templateID`: Template identifier
  - `name`: Template name
  - `status`: Processing status (`success`, `in-progress`, `failure`)
  - `value`: Processed output content
  - `errors`: Array of error messages if processing failed

**Example:**

```swift
VoiceToRxRepo.shared.fetchResultStatusResponse(sessionID: sessionID.uuidString) { result in
    switch result {
    case .success(let response):
        // Access custom template results
        if let customTemplates = response.data?.templateResults?.custom {
            for template in customTemplates {
                print("Template ID: \(template.templateID ?? "N/A")")
                print("Template Name: \(template.name ?? "N/A")")
                print("Status: \(template.status ?? "N/A")")
                
                if let value = template.value {
                    print("Output: \(value)")
                }
                
                if !template.errors.isEmpty {
                    print("Errors:")
                    for error in template.errors {
                        print("  - \(error.msg ?? "Unknown error")")
                    }
                }
            }
        }
        
        // Access transcript results
        if let transcripts = response.data?.templateResults?.transcript {
            for transcript in transcripts {
                print("Transcript: \(transcript.value ?? "")")
            }
        }
        
        // Access audio quality metrics
        if let audioMatrix = response.data?.audioMatrix {
            print("Audio Quality: \(audioMatrix.quality ?? 0.0)")
        }
    case .failure(let error):
        print("Error fetching status: \(error.localizedDescription)")
    }
}
```

#### History Methods

##### Get EkaScribe History

Retrieves the history of all voice-to-prescription sessions for the current user. This API returns a list of all past sessions with their status, patient details, and metadata.

```swift
public func getEkaScribeHistory(
    completion: @escaping (Result<EkaScribeHistoryResponse, Error>) -> Void
)
```

**Response Structure:**
- `status`: Overall status of the response (`success`, `cancelled`, `in-progress`, `system_failure`)
- `data`: Array of `ScribeData` objects containing session information
- `retrievedCount`: Number of sessions retrieved

**ScribeData Properties:**
- `uuid`: Unique session identifier
- `txnID`: Transaction ID
- `bID`: Business ID
- `oid`: Owner ID
- `createdAt`: Session creation timestamp
- `processingStatus`: Current processing status (`success`, `in-progress`, `system_failure`, `request_failure`, `cancelled`)
- `userStatus`: User action status (`init`, `stopped`, `commit`, `cancelled`)
- `mode`: Session mode (`consultation`, `dictation`)
- `flavour`: Platform flavour (`scribe-ios`, `scribe-android`, `web`, etc.)
- `patientDetails`: Patient information (oid, age, biologicalSex, username)
- `version`: API version used

**Example:**

```swift
VoiceToRxRepo.shared.getEkaScribeHistory { result in
    switch result {
    case .success(let response):
        print("Retrieved \(response.retrievedCount ?? 0) sessions")
        print("Overall status: \(response.status.rawValue)")
        
        for session in response.data {
            print("Session UUID: \(session.uuid ?? "N/A")")
            print("Transaction ID: \(session.txnID ?? "N/A")")
            print("Processing Status: \(session.processingStatus?.rawValue ?? "N/A")")
            print("User Status: \(session.userStatus?.rawValue ?? "N/A")")
            print("Mode: \(session.mode?.rawValue ?? "N/A")")
            print("Created At: \(session.createdAt ?? "N/A")")
            
            if let patient = session.patientDetails {
                print("Patient: \(patient.username ?? "N/A"), Age: \(patient.age ?? 0)")
            }
        }
    case .failure(let error):
        print("Error fetching history: \(error.localizedDescription)")
    }
}
```

##### Get Session IDs

Retrieves all session IDs for a specific owner (doctor).

```swift
public func getSessionIds(for ownerId: String) async -> Set<String>
```

**Example:**

```swift
let sessionIds = await VoiceToRxRepo.shared.getSessionIds(for: doctorOID)
print("Found \(sessionIds.count) sessions")
```

#### Template Management Methods

##### Get Templates

Retrieves all available templates that can be used for voice-to-prescription sessions. This includes both default templates and custom templates created by the user.

```swift
public func getTemplates(
    completion: @escaping (Result<TemplateResponse, Error>) -> Void
)
```

**Response Structure:**
- `items`: Array of `Template` objects

**Template Properties:**
- `id`: Unique template identifier
- `title`: Template title/name
- `desc`: Template description
- `sectionIds`: Array of section IDs included in the template
- `defaultTemplate`: Boolean indicating if this is a default template
- `isFavorite`: Boolean indicating if the template is marked as favorite

**Example:**

```swift
VoiceToRxRepo.shared.getTemplates { result in
    switch result {
    case .success(let response):
        print("Found \(response.items.count) templates")
        
        for template in response.items {
            print("Template ID: \(template.id)")
            print("Title: \(template.title)")
            print("Description: \(template.desc ?? "No description")")
            print("Is Default: \(template.defaultTemplate)")
            print("Is Favorite: \(template.isFavorite ?? false)")
            
            if let sectionIds = template.sectionIds {
                print("Sections: \(sectionIds.joined(separator: ", "))")
            }
        }
    case .failure(let error):
        print("Error fetching templates: \(error.localizedDescription)")
    }
}
```

##### Create Template

Creates a new template.

```swift
public func createTemplate(
    title: String,
    desc: String,
    completion: @escaping (Result<TemplateCreationResponse, Error>) -> Void
)
```

**Example:**

```swift
VoiceToRxRepo.shared.createTemplate(
    title: "Custom SOAP Note",
    desc: "A custom SOAP note template"
) { result in
    switch result {
    case .success(let response):
        print("Template created: \(response.id)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

##### Save Edited Template

Saves changes to an existing template. Updates the template's title, description, and associated section IDs.

```swift
public func saveEditedTemplate(
    templateID: String,
    title: String,
    sessionID: [String],
    desc: String,
    completion: @escaping (Result<TemplateCreationResponse, Error>) -> Void
)
```

**Parameters:**
- `templateID`: The ID of the template to update
- `title`: New title for the template
- `sessionID`: Array of section IDs to associate with the template (these are section identifiers, not session IDs)
- `desc`: New description for the template
- `completion`: Completion handler with the updated template response

**Example:**

```swift
VoiceToRxRepo.shared.saveEditedTemplate(
    templateID: "template-123",
    title: "Updated SOAP Note Template",
    sessionID: ["section-subjective", "section-objective", "section-assessment", "section-plan"],
    desc: "Updated SOAP note template with all sections"
) { result in
    switch result {
    case .success(let response):
        print("Template updated successfully")
        print("Updated Template ID: \(response.id)")
    case .failure(let error):
        print("Error updating template: \(error.localizedDescription)")
    }
}
```

##### Delete Template

Deletes a template permanently. This action cannot be undone. Only custom templates can be deleted; default templates cannot be removed.

```swift
public func deleteTemplate(
    templateID: String,
    completion: @escaping (Result<Void, Error>) -> Void
)
```

**Parameters:**
- `templateID`: The ID of the template to delete
- `completion`: Completion handler indicating success or failure

**Note:** Default templates cannot be deleted. Attempting to delete a default template will result in an error.

**Example:**

```swift
VoiceToRxRepo.shared.deleteTemplate(templateID: "template-123") { result in
    switch result {
    case .success:
        print("Template deleted successfully")
        // Refresh template list
        VoiceToRxRepo.shared.getTemplates { result in
            // Handle updated template list
        }
    case .failure(let error):
        print("Error deleting template: \(error.localizedDescription)")
        // Check if it's a default template error
    }
}
```

##### Switch Template

Switches the template for an active session. This allows you to change the output format template for a session that is currently in progress. After switching, the session will be reprocessed with the new template.

```swift
public func switchTemplate(
    templateID: String,
    sessionID: String,
    completion: @escaping (Result<VoiceToRxStatusResponse, Error>) -> Void
)
```

**Parameters:**
- `templateID`: The ID of the new template to use
- `sessionID`: String representation of the session UUID
- `completion`: Completion handler with the updated status response

**Note:** This operation will trigger reprocessing of the session with the new template. The response includes the updated status with the new template results.

**Example:**

```swift
VoiceToRxRepo.shared.switchTemplate(
    templateID: "new-template-id",
    sessionID: sessionID.uuidString
) { result in
    switch result {
    case .success(let response):
        print("Template switched successfully")
        
        // Check the updated template results
        if let customTemplates = response.data?.templateResults?.custom {
            for template in customTemplates {
                print("New Template: \(template.name ?? ""), Status: \(template.status ?? "")")
            }
        }
    case .failure(let error):
        print("Error switching template: \(error.localizedDescription)")
    }
}
```

#### Configuration Methods

##### Get Config

Retrieves the current configuration including supported languages, templates, user preferences, settings, and maximum selection limits. This is useful for populating UI dropdowns and validating user selections.

```swift
public func getConfig(
    completion: @escaping (Result<ConfigResponse, Error>) -> Void
)
```

**Response Structure:**
- `data.supportedLanguages`: Array of supported language options
- `data.supportedOutputFormats`: Array of supported output format options
- `data.consultationModes`: Array of available consultation modes
- `data.maxSelection`: Maximum number of items that can be selected for each category
- `data.settings`: User settings including model training consent
- `data.selectedPreferences`: Currently selected user preferences
- `data.myTemplates`: User's favorite/custom templates
- `data.userDetails`: User profile information

**Example:**

```swift
VoiceToRxRepo.shared.getConfig { result in
    switch result {
    case .success(let response):
        let config = response.data
        
        // Get supported languages
        if let languages = config.supportedLanguages {
            print("Supported Languages:")
            for language in languages {
                print("  - \(language.name) (ID: \(language.id))")
            }
        }
        
        // Get supported output formats
        if let formats = config.supportedOutputFormats {
            print("Supported Output Formats:")
            for format in formats {
                print("  - \(format.name) (ID: \(format.id))")
            }
        }
        
        // Get consultation modes
        if let modes = config.consultationModes {
            print("Consultation Modes:")
            for mode in modes {
                print("  - \(mode.name) (ID: \(mode.id))")
            }
        }
        
        // Get maximum selection limits
        if let maxSelection = config.maxSelection {
            print("Max Selection Limits:")
            print("  Languages: \(maxSelection.supportedLanguages ?? 0)")
            print("  Output Formats: \(maxSelection.supportedOutputFormats ?? 0)")
            print("  Consultation Modes: \(maxSelection.consultationModes ?? 0)")
        }
        
        // Get user's selected preferences
        if let preferences = config.selectedPreferences {
            print("Selected Preferences:")
            print("  Auto Download: \(preferences.autoDownload ?? false)")
            print("  Model Type: \(preferences.modelType ?? "N/A")")
            print("  Consultation Mode: \(preferences.consultationMode ?? "N/A")")
        }
        
        // Get user's favorite templates
        if let myTemplates = config.myTemplates {
            print("My Templates:")
            for template in myTemplates {
                print("  - \(template.name) (ID: \(template.id))")
            }
        }
        
        // Get user details
        if let userDetails = config.userDetails {
            print("User Details:")
            print("  Business ID: \(userDetails.bID ?? "N/A")")
            print("  Is Paid Doctor: \(userDetails.isPaidDoc ?? false)")
        }
    case .failure(let error):
        print("Error fetching config: \(error.localizedDescription)")
    }
}
```

##### Get Template From Config

Retrieves templates from the user's configuration. This returns only the templates that are configured in the user's preferences (favorite templates), as opposed to `getTemplates()` which returns all available templates.

```swift
public func getTemplateFromConfig(
    completion: @escaping (Result<TemplateResponse, Error>) -> Void
)
```

**Difference from `getTemplates()`:**
- `getTemplates()`: Returns ALL available templates (default + custom)
- `getTemplateFromConfig()`: Returns only templates from user's configuration (favorite/selected templates)

**Example:**

```swift
VoiceToRxRepo.shared.getTemplateFromConfig { result in
    switch result {
    case .success(let response):
        print("Found \(response.items.count) templates in configuration")
        
        for template in response.items {
            print("Template: \(template.title)")
            print("  ID: \(template.id)")
            print("  Is Default: \(template.defaultTemplate)")
            print("  Is Favorite: \(template.isFavorite ?? false)")
        }
    case .failure(let error):
        print("Error fetching templates from config: \(error.localizedDescription)")
    }
}
```

##### Update Config

Updates the user's configuration, particularly their favorite/selected templates. This allows users to customize which templates appear in their template list.

```swift
public func updateConfig(
    templates: [String],
    completion: @escaping (Result<String, Error>) -> Void
)
```

**Parameters:**
- `templates`: Array of template IDs to set as user's favorite templates
- `completion`: Completion handler with success message or error

**Note:** This updates the `myTemplates` field in the user's configuration. The templates array should contain valid template IDs that exist in the system.

**Example:**

```swift
// Update user's favorite templates
VoiceToRxRepo.shared.updateConfig(
    templates: ["template-id-1", "template-id-2", "template-id-3"]
) { result in
    switch result {
    case .success(let message):
        print("Configuration updated successfully: \(message)")
        
        // Refresh config to see updated templates
        VoiceToRxRepo.shared.getConfig { configResult in
            if case .success(let config) = configResult {
                if let myTemplates = config.data.myTemplates {
                    print("Updated favorite templates:")
                    for template in myTemplates {
                        print("  - \(template.name)")
                    }
                }
            }
        }
    case .failure(let error):
        print("Error updating config: \(error.localizedDescription)")
    }
}
```

#### Helper Methods

##### Get Template ID

Retrieves the template ID associated with a session from the local database. This is a helper method that queries the local CoreData store for the transcription/template ID stored with a session.

```swift
public func getTemplateID(for sessionID: UUID) -> String
```

**Parameters:**
- `sessionID`: UUID of the session to query

**Returns:**
- `String`: The template ID stored in the session's transcription field, or an empty string if not found

**Note:** This method queries the local database, not the API. If the session doesn't exist locally or doesn't have a template ID stored, it returns an empty string.

**Example:**

```swift
let templateID = VoiceToRxRepo.shared.getTemplateID(for: sessionID)

if !templateID.isEmpty {
    print("Template ID for session: \(templateID)")
    
    // Use the template ID to fetch template details
    VoiceToRxRepo.shared.getTemplates { result in
        if case .success(let response) = result {
            if let template = response.items.first(where: { $0.id == templateID }) {
                print("Template found: \(template.title)")
            }
        }
    }
} else {
    print("No template ID found for this session")
}
```

### Error Types

### EkaScribeError

```swift
public enum EkaScribeError: Error {
    case microphonePermissionDenied
    case floatingButtonAlreadyPresented
    case freeSessionLimitReached
    case audioEngineStartFailed
}
```

### VoiceToRxErrorCode

```swift
public enum VoiceToRxErrorCode: Int {
    case noIssues = 1
    case apiError = 2
    case smallTranscript = 3
    case unassigned = 4
}
```

### APIError

```swift
public struct APIError: Decodable, Error {
    public let status: String?
    public let error: APIErrorDetail?
    public let txn_id: String?
    public let b_id: String?
}

public struct APIErrorDetail: Decodable {
    public let code: String?
    public let message: String?
    public let display_message: String?
}
```

## Troubleshooting

### Common Issues

### 1. Authentication Failures

**Symptoms**: API calls return 401 Unauthorized errors

**Solutions**:

```swift
// Verify token storage implementation
let accessToken = AuthTokenHolder.shared.authToken
assert(accessToken != nil, "Access token must not be nil")

// Verify AuthTokenHolder is updated
assert(AuthTokenHolder.shared.authToken != nil, "AuthTokenHolder must have access token")
assert(AuthTokenHolder.shared.bid != nil, "Business ID must be set")
```

### 2. Template Configuration Errors

**Symptoms**: Template ID not found or invalid template type

**Solutions**:

```swift
// Ensure template IDs are valid and exist in your system
// Use correct template type (defaultType or customType)
let templates = [
    OutputFormatTemplate(
        templateID: "valid-template-id",
        templateType: .defaultType,  // or .customType
        templateName: "Template Name"
    )
]

// Maximum 2 templates allowed
assert(templates.count <= 2, "Maximum 2 templates allowed")
```

### 3. Language Configuration Errors

**Symptoms**: Invalid language codes or empty language array

**Solutions**:

```swift
// Use valid language codes (e.g., "en-IN", "hi-IN")
let languages = ["en-IN"]

// Ensure at least one language
assert(!languages.isEmpty, "At least one language required")

// Maximum 2 languages allowed
assert(languages.count <= 2, "Maximum 2 languages allowed")
```

### 4. Session Creation Failures

**Symptoms**: `onCreateVoiceToRxSession` not called or called with nil values

**Solutions**:

```swift
// Verify all required configurations are set
let config = V2RxInitConfigurations.shared
assert(config.ownerOID != nil, "Doctor OID is required")
assert(config.subOwnerOID != nil, "Patient OID is required")
assert(config.appointmentID != nil, "Appointment ID is required")
assert(config.modelContainer != nil, "Model container is required")

// Check authentication
assert(AuthTokenHolder.shared.authToken != nil, "Auth token is required")

// Verify network connectivity
let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    if path.status != .satisfied {
        print("Network not available")
    }
}
```

### 5. Audio Quality Issues

**Symptoms**: Poor transcription accuracy

**Solutions**:

```swift
// Monitor amplitude in real-time
viewModel.$amplitude
    .sink { amplitude in
        if amplitude < 0.1 {
            // Warn user about low audio input
            showAudioInputWarning()
        }
    }

// Optimize audio session
let audioSession = AVAudioSession.sharedInstance()
try? audioSession.setCategory(
    .playAndRecord,
    mode: .voiceChat,
    options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
)
try? audioSession.setActive(true)
```

### 6. Upload Failures

**Symptoms**: Audio files not uploading, processing stuck

**Solutions**:

```swift
// Retry failed uploads
viewModel.retryIfNeeded()

// Check network connectivity before starting recording
let monitor = NWPathMonitor()
let queue = DispatchQueue(label: "NetworkMonitor")
monitor.start(queue: queue)

monitor.pathUpdateHandler = { [weak self] path in
    if path.status == .satisfied {
        // Network available, proceed with recording
    } else {
        // Show network unavailable warning
        self?.showNetworkUnavailableWarning()
    }
}
```

### 7. Floating Button Already Presented

**Symptoms**: Error when trying to show floating button multiple times

**Solutions**:

```swift
// Check if floating window is busy before showing
if FloatingVoiceToRxViewController.shared.isFloatingWindowBusy {
    print("Floating window is already active")
    return
}

// Use showFloatingButtonSafely for safer handling
FloatingVoiceToRxViewController.shared.showFloatingButtonSafely(
    viewModel: viewModel,
    conversationType: "consultation",
    inputLanguage: ["en-IN"],
    templates: templates,
    modelType: "pro",
    liveActivityDelegate: nil
) { success in
    if !success {
        print("Failed to show floating button")
    }
}
```

### Debug Mode

Enable detailed logging for troubleshooting:

```swift
#if DEBUG
// EkaVoiceToRx provides debug prints automatically
// Check Xcode console for detailed logs including:
// - Audio engine status
// - Upload progress
// - Session lifecycle
// - Error details
#endif
```

### Support Resources

- **GitHub Issues**: [Report bugs or request features](https://github.com/eka-care/EkaVoiceToRx/issues)
- **Documentation**: Check this guide and inline code documentation
- **Sample Project**: Request access to the sample integration project
- **Technical Support**: Contact the EkaVoiceToRx team for integration assistance
