# EkaScribe iOS SDK

A Swift package for voice-to-prescription functionality with audio recording and real-time transcription capabilities for medical consultation applications.

## Overview

EkaScribe empowers healthcare applications with advanced voice recording and transcription capabilities. It provides a seamless integration for medical consultation workflows, enabling doctors to record patient interactions and automatically generate prescriptions through AI-powered voice analysis.

### Getting Started

1. **Install** the package via Swift Package Manager
2. **Configure** authentication and doctor information at app launch
3. **Initialize** `VoiceToRxViewModel` in your view
4. **Start recording** with your desired templates and languages
5. **Handle results** when processing completes

The SDK requires **iOS 17.0+** and provides a simple, straightforward API for voice-to-prescription functionality.

### Key Features

- 🎙️ **Voice Activity Detection (VAD)** - Intelligent audio recording with automatic speech detection
- 🔄 **Real-time Transcription** - Live audio-to-text conversion during consultations
- 🏥 **Medical Context Aware** - Specialized for healthcare terminology and prescription generation
- 📊 **Session Management** - Complete recording session lifecycle management
- ☁️ **Cloud Integration** - Automatic audio upload and processing
- 📝 **Template Support** - Customizable output formats (SOAP notes, prescriptions, etc.)

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Integration Guide](#integration-guide)
- [Core Components](#core-components)
- [Configuration](#configuration)
- [Recording Management](#recording-management)
- [Template Management](#template-management)
- [Session History](#session-history)
- [Result Management](#result-management)
- [Error Handling](#error-handling)
- [API Reference](#api-reference)

## Requirements

> **⚠️ Important**: This SDK requires iOS 17.0 or later.

- **iOS**: 17.0+
- **Swift**: 5.9+
- **Xcode**: 15.0+
- **Sdk Version**: 1.3.1+

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

Add EkaScribe to your project using Swift Package Manager:

1. In Xcode, select **File → Add Package Dependencies**
2. Enter the repository URL:
   ```
   https://github.com/eka-care/EkaVoiceToRx.git
   ```
   Or use SSH:
   ```
   git@github.com:eka-care/EkaVoiceToRx.git
   ```
3. Choose the version or branch
4. Add to your target

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/eka-care/EkaVoiceToRx.git", from: "1.3.1")
]
```

### Import Statement

After adding the package, import it in your Swift files:

```swift
import EkaVoiceToRx
```

## Integration Guide

Follow these steps to integrate the SDK into your app:

### Step 1: Configure Authentication and Doctor Information

Set up authentication tokens and doctor information when your app launches. This should be done once at app startup:

```swift
import SwiftUI
import EkaVoiceToRx

@main
struct YourApp: App {
    init() {
        configureEkaScribe()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureEkaScribe() {
        // 1. Set authentication tokens (required)
        AuthTokenHolder.shared.authToken = "your_auth_token"
        AuthTokenHolder.shared.refreshToken = "your_refresh_token"
        AuthTokenHolder.shared.bid = "your_business_id"
        
        // 2. Configure doctor/user information (required)
        let config = V2RxInitConfigurations.shared
        config.clientId = "your_client_id"
        config.ownerName = "Dr. Smith"
        config.ownerOID = "doctor_oid_123"
        config.ownerUUID = "doctor_uuid_456"
    }
}
```

**Important**: Make sure to set authentication tokens and doctor information before making any SDK calls.

### Step 2: Initialize the View Model

Create a `VoiceToRxViewModel` instance in your SwiftUI view or UIKit view controller:

**SwiftUI:**
```swift
@StateObject private var viewModel = VoiceToRxViewModel(
    voiceToRxInitConfig: .shared,
    voiceToRxDelegate: nil
)
```

**UIKit:**
```swift
private let viewModel = VoiceToRxViewModel(
    voiceToRxInitConfig: .shared,
    voiceToRxDelegate: nil
)
```

### Step 3: Start Recording

Start a recording session with your desired configuration:

#### Parameters

The `startRecording()` method accepts the following parameters:

- **conversationType** (`VoiceConversationType`): The type of conversation (see [Conversation Types](#conversation-types))

- **inputLanguage** (`[InputLanguageType]`): Array of supported languages (see [Input Languages](#input-languages))

- **templates** (`[OutputFormatTemplate]`): Array of output format templates (see [Template Management](#template-management))

- **modelType** (`ModelType`): The AI model to use for processing (see [Model Types](#model-types))

```swift
// Your implementation
private func startRecording() async {
    do {
        // 1. Fetch available templates (recommended)
        // See Template Management section for details on getTemplates API
        // VoiceToRxRepo.shared.getTemplates { result in ... }
        
        // 2. Configure templates
        let outputFormat: [OutputFormatTemplate] = [
            OutputFormatTemplate(
                templateID: "template-id-here",
                templateType: .defaultType,
                templateName: "SOAP Notes"
            )
        ]
        
        // 3. Set patient information (if applicable)
        V2RxInitConfigurations.shared.subOwnerOID = patientOID
        V2RxInitConfigurations.shared.subOwnerName = patientName
        
        // 4. Calling SDK function
        try await viewModel.startRecording(
            conversationType: VoiceConversationType.conversation,
            inputLanguage: [InputLanguageType.english, InputLanguageType.hindi],
            templates: outputFormat,
            modelType: ModelType.lite
        )
        
        // Successfully started recording
    } catch {
        // Handle errors
        await MainActor.run {
            handleRecordingError(error)
        }
    }
}
```

**Note**: It's recommended to use the `getTemplates()` API first to fetch available templates before creating the `OutputFormatTemplate` array. See the [Template Management](#template-management) section for details.

## Core Components

### VoiceToRxViewModel

The central view model that manages the entire voice recording and processing workflow.

```swift
public class VoiceToRxViewModel: ObservableObject {
    @Published public var screenState: RecordConsultationState
    
    public init(
        voiceToRxInitConfig: V2RxInitConfigurations,
        voiceToRxDelegate: VoiceToRxDelegate?
    )
}
```

#### Recording States

The `screenState` property tracks the current state of the recording session:

```swift
public enum RecordConsultationState {
    case retry                          // Ready to retry after error
    case startRecording                 // Initial state, ready to start
    case listening(conversationType: VoiceConversationType) // Currently recording
    case paused                         // Recording paused
    case processing                     // Processing audio/generating prescription
    case resultDisplay(success: Bool, value: String?)  // Results available
    case deletedRecording              // Recording deleted
}
```

#### Conversation Types

```swift
public enum VoiceConversationType: String, CaseIterable {
    case conversation = "consultation"  // Doctor-patient conversation
    case dictation                     // Direct prescription dictation
}
```

#### Model Types

```swift
public enum ModelType {
    case pro      // High accuracy model
    case lite     // Faster, lighter model
}
```

#### Input Languages

```swift
public enum InputLanguageType {
    case english
    case hindi
    case tamil
    case telugu
    case kannada
    case malayalam
    case bengali
    case gujarati
    case marathi
    case punjabi
    case urdu
    case odia
    case assamese
}
```

## Configuration

### App-Level Setup

Configure the SDK when your app launches. This should be done once at app startup:

```swift
import SwiftUI
import EkaVoiceToRx

@main
struct YourApp: App {
    init() {
        configureEkaScribe()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func configureEkaScribe() {
        // 1. Set authentication tokens (required)
        AuthTokenHolder.shared.authToken = KeychainHelper.fetchAuthToken()
        AuthTokenHolder.shared.refreshToken = KeychainHelper.fetchRefreshToken()
        AuthTokenHolder.shared.bid = JWTDecoder.shared.businessId
        
        // 2. Configure doctor/user information (required)
        let config = V2RxInitConfigurations.shared
        config.clientId = "your_client_id"
        config.ownerName = "Dr. Smith"
        config.ownerOID = "doctor_oid_123"
        config.ownerUUID = "doctor_uuid_456"
        
        // 3. Set up data container (optional - only if using SwiftData)
        // config.modelContainer = SwiftDataRepoContext.modelContext.container
    }
}
```

**Important**: Make sure to set authentication tokens and doctor information before making any SDK calls.

### Session-Specific Configuration

Before starting a recording session, configure patient-specific information. This should be done each time you start a new recording:

```swift
// Set patient information for the current session (required before recording)
V2RxInitConfigurations.shared.subOwnerOID = selectedPatientOid
V2RxInitConfigurations.shared.subOwnerName = patientName

// Optional: Set appointment ID for context
V2RxInitConfigurations.shared.appointmentID = appointmentID
```

**Note**: Patient information can be set to empty strings if not applicable:
```swift
V2RxInitConfigurations.shared.subOwnerOID = ""
V2RxInitConfigurations.shared.subOwnerName = ""
```

### Configuration Properties

```swift
public class V2RxInitConfigurations {
    public static let shared: V2RxInitConfigurations
    
    // Doctor/User Information
    public var ownerName: String?          // Doctor name
    public var ownerOID: String?            // Doctor OID
    public var ownerUUID: String?            // Doctor UUID
    public var clientId: String?             // Client identifier
    
    // Patient Information (set per session)
    public var subOwnerOID: String?         // Patient OID
    public var subOwnerName: String?        // Patient name
    
    // Optional Context
    public var appointmentID: String?       // Appointment identifier
    
    // Data Storage
    public var modelContainer: ModelContainer?  // SwiftData container (optional)
}
```

### Authentication

Set authentication tokens before making any SDK calls:

```swift
AuthTokenHolder.shared.authToken = "your_auth_token"
AuthTokenHolder.shared.refreshToken = "your_refresh_token"
AuthTokenHolder.shared.bid = "your_business_id"
```

## Recording Management

### Starting Recording

#### Parameters

The `startRecording()` method accepts the following parameters:

- **conversationType** (`VoiceConversationType`): The type of conversation (see [Conversation Types](#conversation-types))

- **inputLanguage** (`[InputLanguageType]`): Array of supported languages (see [Input Languages](#input-languages))

- **templates** (`[OutputFormatTemplate]`): Array of output format templates (see [Template Management](#template-management))

- **modelType** (`ModelType`): The AI model to use for processing (see [Model Types](#model-types))

```swift
// Start recording
try await viewModel.startRecording(
conversationType: VoiceConversationType.conversation,
inputLanguage: [InputLanguageType.english, InputLanguageType.hindi],
templates: templates,
modelType: ModelType.lite
 )
```

**Note**: It's recommended to use the `getTemplates()` API first to fetch available templates before creating the `OutputFormatTemplate` array. See the [Template Management](#template-management) section for details.

### Pausing and Resuming

```swift
// Pause recording
viewModel.pauseRecording()

// Resume recording
do {
    try viewModel.resumeRecording()
} catch {
    // Handle resume error
    print("Failed to resume: \(error.localizedDescription)")
}
```

### Stopping Recording

```swift
// Stop recording and process
Task {
    do {
        try await viewModel.stopRecording()
        // The viewModel will transition to .processing, then .resultDisplay
    } catch {
        // Handle error
        print("Failed to stop recording: \(error.localizedDescription)")
    }
}
```

### Handling Results

Monitor the `screenState` for result availability. Results are automatically provided when processing completes:

```swift
case .resultDisplay(success: let success, value: let value):
    if success {
        // Get the result text (base64 encoded)
        let base64EncodedText = value ?? ""
        
        // Decode base64 to get the actual result
        guard let decodedData = Data(base64Encoded: base64EncodedText),
              let resultText = String(data: decodedData, encoding: .utf8) else {
            showError("Failed to decode result")
            return
        }
        
        // Get the session ID for future reference
        let sessionID = viewModel.sessionID?.uuidString ?? ""
        // Display results to user
        showResults(resultText, sessionID: sessionID)
    } else {
        // Handle error
        showError("Failed to process recording")
    }
```

**Note**: The `value` parameter contains base64-encoded formatted output based on your selected template. You need to decode it before displaying to users. For more detailed results including multiple template outputs, use `VoiceToRxRepo.shared.fetchResultStatusResponse()`.

## Template Management

### Fetching Available Templates

Use `VoiceToRxRepo` to fetch available templates:

```swift
import EkaVoiceToRx

VoiceToRxRepo.shared.getTemplates { result in
    switch result {
    case .success(let response):
        let templates = response.items
        // Use templates
        break
    case .failure(let error):
        print("Failed to fetch templates: \(error.localizedDescription)")
        break
    }
}
```

### Updating Favorite Templates

Update user's favorite templates configuration:

```swift
let templateIDs = ["template-id-1", "template-id-2"]

VoiceToRxRepo.shared.updateConfig(
    templates: templateIDs
) { result in
    switch result {
    case .success:
        print("Templates updated successfully")
    case .failure(let error):
        print("Failed to update: \(error.localizedDescription)")
    }
}
```

### Using Templates in Recording

Pass templates when starting a recording:

```swift
// Your implementation
private func startRecordingWithTemplates() async {
    do {
        // 1. Fetch available templates first (recommended)
        // VoiceToRxRepo.shared.getTemplates { result in ... }
        
        // 2. Configure templates
        let templates: [OutputFormatTemplate] = [
            OutputFormatTemplate(
                templateID: "template-id",
                templateType: .defaultType,
                templateName: "Template Name"
            )
        ]
        
        // 3. Calling SDK function
        try await viewModel.startRecording(
            conversationType: VoiceConversationType.conversation,
            inputLanguage: [InputLanguageType.english],
            templates: templates,
            modelType: ModelType.pro
        )
    } catch {
        // Handle error
        await MainActor.run {
            handleError(error)
        }
    }
}
```

## Session History

### Fetching Session History

Retrieve past recording sessions:

```swift
VoiceToRxRepo.shared.getEkaScribeHistory { result in
    switch result {
    case .success(let response):
        let sessions = response.data
        // Display sessions
        break
    case .failure(let error):
        print("Failed to fetch history: \(error.localizedDescription)")
        break
    }
}
```
## Result Management

### Fetching Full Result Response

Get the complete result response with selected template outputs:

```swift
VoiceToRxRepo.shared.fetchResultStatusResponse(sessionID: sessionID) { result in
    switch result {
    case .success(let response):
        // Note: All values in the response are base64 encoded and need to be decoded before display
        // response.data.templateResults.custom - custom template results (base64 encoded)
        // response.data.templateResults.transcript - transcript results (base64 encoded)
        // response.data.output - general output (base64 encoded)
        // response.data.audioMatrix - audio quality metrics
        
        // Example: Decoding a result value
        if let encodedValue = response.data?.templateResults?.custom?.first?.value,
           let decodedData = Data(base64Encoded: encodedValue),
           let decodedText = String(data: decodedData, encoding: .utf8) {
            // Use decodedText for display
            print("Decoded result: \(decodedText)")
        }
        break
    case .failure(let error):
        print("Failed to fetch response: \(error.localizedDescription)")
        break
    }
}
```
**Note**: The `value` parameter returned by `fetchResultStatus` is base64 encoded and must be decoded before displaying to users.

### Switching Templates

Switch the output format for an existing session:

```swift
VoiceToRxRepo.shared.switchTemplate(
    templateID: newTemplateID,
    sessionID: sessionID
) { result in
    switch result {
    case .success(let response):
        // Updated response with new template output
        break
    case .failure(let error):
        print("Failed to switch template: \(error.localizedDescription)")
        break
    }
}
```

### Updating Results

Update edited content back to the server:

```swift
let request = UpdateResultRequest(
    // Configure request with updated content
)

VoiceToRxRepo.shared.updateResult(
    sessionID: sessionID,
    request: request
) { result, errorStatus in
    switch result {
    case .success:
        print("Result updated successfully")
    case .failure(let error):
        print("Failed to update: \(error.localizedDescription)")
    }
}
```

## Error Handling

### Common Errors

The SDK provides specific error types:

```swift
public enum EkaScribeError: Error {
    case freeSessionLimitReached
    case microphonePermissionDenied
    case microphoneIsInUse
    case vadDetectorFailed
    case noSessionId
    case audioSessionSetupFailed
}
```

### Error Handling Example

Here's a complete example of handling errors when starting a recording:

```swift
// Your implementation
private func handleRecording() async {
    do {
        let templates: [OutputFormatTemplate] = [
            // Your templates
        ]
        
        // Calling SDK function
        try await viewModel.startRecording(
            conversationType: VoiceConversationType.conversation,
            inputLanguage: [InputLanguageType.english, InputLanguageType.hindi],
            templates: templates,
            modelType: ModelType.lite
        )
        
        // Successfully started recording
    } catch let error as EkaScribeError {
        // Handle SDK-specific errors
        await MainActor.run {
            switch error {
            case .freeSessionLimitReached:
                // Show upgrade prompt
                showUpgradeAlert()
            case .microphonePermissionDenied:
                // Show permission alert
                showPermissionAlert()
            case .microphoneIsInUse:
                // Show microphone in use alert
                showMicrophoneInUseAlert()
            default:
                // Handle other SDK-specific errors
                showGenericError(error.localizedDescription)
            }
        }
    } catch {
        // Handle generic errors (network, API, etc.)
        await MainActor.run {
            showGenericError(error.localizedDescription)
        }
    }
}
```

## API Reference

### VoiceToRxViewModel

#### Properties

```swift
@Published public var screenState: RecordConsultationState
```

#### Methods

```swift
// Core recording methods
public func startRecording(
    conversationType: VoiceConversationType,
    inputLanguage: [InputLanguageType],
    templates: [OutputFormatTemplate],
    modelType: ModelType
) async throws

public func stopRecording() async throws
public func pauseRecording()
public func resumeRecording() throws

// Session management
public func deleteRecording(id: UUID)
public func clearSession()
public func retryIfNeeded()
```

### VoiceToRxRepo

#### Template Management

```swift
public func getTemplates(completion: @escaping (Result<TemplateResponse, Error>) -> Void)
public func updateConfig(templates: [String], completion: @escaping (Result<Void, Error>) -> Void)
```

#### Session History

```swift
public func getEkaScribeHistory(completion: @escaping (Result<ScribeHistoryResponse, Error>) -> Void)
```

#### Result Management

```swift
public func fetchResultStatusResponse(
    sessionID: String,
    completion: @escaping (Result<VoiceToRxStatusResponse, Error>) -> Void
)
// Note: All response values are base64 encoded. Decode before displaying.

public func switchTemplate(
    templateID: String,
    sessionID: String,
    completion: @escaping (Result<VoiceToRxStatusResponse, Error>) -> Void
)

public func updateResult(
    sessionID: String,
    request: UpdateResultRequest,
    completion: @escaping (Result<Void, ErrorStatus>) -> Void
)
```

### Configuration Classes

#### V2RxInitConfigurations

```swift
public class V2RxInitConfigurations {
    public static let shared: V2RxInitConfigurations
    
    public var modelContainer: ModelContainer?
    public var clientId: String?
    public var ownerName: String?
    public var ownerOID: String?
    public var ownerUUID: String?
    public var subOwnerOID: String?
    public var subOwnerName: String?
    public var appointmentID: String?
}
```

#### AuthTokenHolder

```swift
public class AuthTokenHolder {
    public static let shared: AuthTokenHolder
    
    public var authToken: String?
    public var refreshToken: String?
    public var bid: String?
}
```

### Data Models

#### OutputFormatTemplate

```swift
public struct OutputFormatTemplate {
    public let templateID: String
    public let templateType: TemplateType
    public let templateName: String
    
    public init(
        templateID: String,
        templateType: TemplateType,
        templateName: String
    )
}
```

#### VoiceToRxStatusResponse

```swift
public struct VoiceToRxStatusResponse {
    public let data: VoiceToRxStatusData?
}

public struct VoiceToRxStatusData {
    public let templateResults: TemplateResults?
    public let output: [VoiceToRxOutput]?
    public let audioMatrix: AudioMatrix?
}

public struct TemplateResults {
    public let custom: [VoiceToRxOutput]?
    public let transcript: [VoiceToRxOutput]?
}
```

## Best Practices

### Memory Management

```swift
class RecordingViewController: UIViewController {
    private var viewModel: VoiceToRxViewModel?
    
    deinit {
        // Clean up resources
        viewModel?.clearSession()
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

### State Management

Always observe `screenState` changes to keep your UI in sync:

```swift
.onChange(of: viewModel.screenState) { oldState, newState in
    // Update UI based on state
    handleStateChange(newState)
}
```

### Error Handling

Always handle errors from async operations using try-catch:

```swift
// Your implementation
private func startRecording() async {
    do {
        let templates: [OutputFormatTemplate] = [
            // Your templates
        ]
        
        // Calling SDK function
        try await viewModel.startRecording(
            conversationType: VoiceConversationType.conversation,
            inputLanguage: [InputLanguageType.english, InputLanguageType.hindi],
            templates: templates,
            modelType: ModelType.lite
        )
        
        // Successfully started recording
    } catch {
        // Handle error appropriately
        await MainActor.run {
            showError(error)
        }
    }
}
```

## Troubleshooting

### Microphone Permission Issues

If microphone permission is denied:

1. Check `Info.plist` has `NSMicrophoneUsageDescription`
2. Request permission programmatically if needed
3. Guide users to Settings if permission was previously denied

### Session Creation Failures

If sessions fail to create:

1. Verify `ownerOID` is set in `V2RxInitConfigurations.shared`
2. Check `AuthTokenHolder.shared.authToken` is valid
3. Ensure network connectivity
4. Check for free session limit if applicable

### Result Not Available

If results are not available after processing:

1. Check `screenState` transitions to `.resultDisplay`
2. Verify session ID is available: `viewModel.sessionID`
3. Use `VoiceToRxRepo.shared.fetchResultStatusResponse` to get full response
4. Check network connectivity for result retrieval
