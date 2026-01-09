# EkaVoiceToRx

A Swift package for voice-to-prescription functionality with floating UI components, audio recording, and real-time transcription capabilities for medical consultation applications.

![Swift Version](https://img.shields.io/badge/Swift-5.10+-orange.svg)

![Platform](https://img.shields.io/badge/Platform-iOS%2017.0+-blue.svg)

![License](https://img.shields.io/badge/License-MIT-green.svg)

## Overview

EkaVoiceToRx empowers healthcare applications with advanced voice recording and transcription capabilities. It provides a seamless integration for medical consultation workflows, enabling doctors to record patient interactions and automatically generate prescriptions through AI-powered voice analysis.

### Key Features

- 🎙️ **Voice Activity Detection (VAD)** - Intelligent audio recording with automatic speech detection

- 🔄 **Real-time Transcription** - Live audio-to-text conversion during consultations

- 📱 **Floating UI Interface** - Picture-in-picture recording interface that stays accessible

- 🏥 **Medical Context Aware** - Specialized for healthcare terminology and prescription generation

- 📊 **Session Management** - Complete recording session lifecycle management

- ☁️ **Cloud Integration** - Automatic audio upload and processing via Amazon S3

- 🔐 **Token Management** - Secure authentication with automatic token refresh

- 📋 **Template Support** - Multiple output format templates (SOAP, Prescription, etc.)

- 🌐 **Multi-language Support** - Support for multiple languages (up to 2 per session)

- 📈 **Real-time Monitoring** - Live audio quality metrics and voice activity flows

- 📚 **Session History** - Access to past recording sessions

- 🎯 **Model Selection** - Choose between Pro and Lite models for different use cases

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Components](#core-components)
- [Integration Guide](#integration-guide)
- [Configuration](#configuration)
- [Authentication & Token Management](#authentication--token-management)
- [Usage Examples](#usage-examples)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)

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

## Usage Examples

### Basic Recording Session

```swift
// Prepare output format templates
let templates = [
    OutputFormatTemplate(
        templateID: "template-id-here",
        templateType: .defaultType,
        templateName: "SOAP Note"
    )
]

// Start a consultation recording
let error = await viewModel.startRecording(
    conversationType: "consultation",
    inputLanguage: ["en-IN"],
    templates: templates,
    modelType: "pro"
)

if let error = error {
    print("Error starting recording: \(error)")
}
```

### Recording with Multiple Templates

```swift
// Select multiple templates (max 2)
let templates = [
    OutputFormatTemplate(
        templateID: "soap-template-id",
        templateType: .defaultType,
        templateName: "SOAP Note"
    ),
    OutputFormatTemplate(
        templateID: "prescription-template-id",
        templateType: .customType,
        templateName: "Prescription"
    )
]

await viewModel.startRecording(
    conversationType: "consultation",
    inputLanguage: ["en-IN", "hi-IN"], // Multiple languages (max 2)
    templates: templates,
    modelType: "pro"
)
```

### Dictation Mode

```swift
// For direct prescription dictation
let dictationTemplates = [
    OutputFormatTemplate(
        templateID: "prescription-template-id",
        templateType: .defaultType,
        templateName: "Prescription"
    )
]

await viewModel.startRecording(
    conversationType: "dictation",
    inputLanguage: ["en-IN"],
    templates: dictationTemplates,
    modelType: "lite" // Lite model is faster for dictation
)

// This mode is optimized for single-speaker medical dictation
// Less background noise filtering, more focused on medical terminology
```

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

### Model Selection

Choose between Pro and Lite models based on your needs:

```swift
// Pro Model - Higher accuracy, slower processing
// Best for: Final consultations, complex cases, high-quality requirements
await viewModel.startRecording(
    conversationType: "consultation",
    inputLanguage: ["en-IN"],
    templates: templates,
    modelType: "pro"
)

// Lite Model - Faster processing, good accuracy
// Best for: Quick notes, dictation, real-time requirements
await viewModel.startRecording(
    conversationType: "dictation",
    inputLanguage: ["en-IN"],
    templates: templates,
    modelType: "lite"
)
```

### Multi-language Support

Record sessions in multiple languages (up to 2):

```swift
// Start recording with multiple languages
let templates = [
    OutputFormatTemplate(
        templateID: "template-id",
        templateType: .defaultType,
        templateName: "SOAP Note"
    )
]

await viewModel.startRecording(
    conversationType: "consultation",
    inputLanguage: ["en-IN", "hi-IN"], // English and Hindi (max 2)
    templates: templates,
    modelType: "pro"
)
```

### Multiple Output Formats

Generate multiple document formats simultaneously (up to 2):

```swift
// Select multiple templates
let templates = [
    OutputFormatTemplate(
        templateID: "soap-template-id",
        templateType: .defaultType,
        templateName: "SOAP Note"
    ),
    OutputFormatTemplate(
        templateID: "prescription-template-id",
        templateType: .customType,
        templateName: "Prescription"
    )
]

await viewModel.startRecording(
    conversationType: "consultation",
    inputLanguage: ["en-IN"],
    templates: templates,
    modelType: "pro"
)

// Results are delivered through delegate callbacks
// Check FloatingVoiceToRxDelegate.onResultValueReceived
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


