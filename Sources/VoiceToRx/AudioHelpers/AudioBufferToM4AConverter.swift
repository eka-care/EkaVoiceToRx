import AVFoundation

enum AudioFileFormat {
  case coreAudioFile
  case m4aFile
  
  var extensionString: String {
    switch self {
    case .coreAudioFile:
      return ".caf"
    case .m4aFile:
      return ".m4a"
    }
  }
}

final class AudioBufferToM4AConverter {
  
  var urlsStored: [URL] = []
  var cafUrlsStored: [URL] = []
  
  func writePCMBufferToM4A(
    pcmBuffer: AVAudioPCMBuffer,
    fileKey: String,
    sessionId: String,
    isFullAudio: Bool = false,
    fileExtension: String = AudioFileFormat.m4aFile.extensionString,
    completion: @escaping (Result<URL, Error>) -> Void
  ) {
    let documentDirectoryURL = FileHelper.getDocumentDirectoryURL()
    
    let pcmFileName = "\(fileKey)\(AudioFileFormat.coreAudioFile.extensionString)"
    let m4aFileName = "\(fileKey)\(fileExtension)"
    
    let outputPCMURL = documentDirectoryURL.appendingPathComponent(pcmFileName)
    let sessionDirectoryURL = documentDirectoryURL.appendingPathComponent(sessionId)
    let outputM4AURL = sessionDirectoryURL.appendingPathComponent(m4aFileName)
    
    cafUrlsStored.append(outputPCMURL)
    
    do {
      // Ensure the session directory exists
      try FileManager.default.createDirectory(at: sessionDirectoryURL, withIntermediateDirectories: true)
      
      // Create AVAudioFile for writing PCM data
      let outputAudioFile = try AVAudioFile(
        forWriting: outputPCMURL,
        settings: pcmBuffer.format.settings,
        commonFormat: pcmBuffer.format.commonFormat,
        interleaved: pcmBuffer.format.isInterleaved
      )
      
      // Write the PCM buffer to the file
      try outputAudioFile.write(from: pcmBuffer)
      print("PCM file written successfully at \(outputPCMURL)")
      
      convertToM4A(
        sourceURL: outputPCMURL,
        destinationURL: outputM4AURL,
        success: { [weak self] in
          guard let self else { return }
          print("Removed file at url \(outputPCMURL)")
          FileHelper.removeFile(at: outputPCMURL)
          urlsStored.append(outputM4AURL)
          completion(.success(outputM4AURL))
        },
        failure: { error in
          completion(.failure(error ?? NSError(
            domain: "AudioConversionError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error during M4A conversion."]
          )))
        }
      )
      
    } catch {
      print("Error: \(error.localizedDescription)")
      completion(.failure(error))
    }
  }
  
  private func convertToM4A(
    sourceURL: URL,
    destinationURL: URL,
    success: (() -> Void)?,
    failure: ((Error?) -> Void)?
  ) {
    print("Source url is -> \(sourceURL)")
    print("Destination url is -> \(destinationURL)")
    
    // Remove existing file at destination if it exists
    if FileManager.default.fileExists(atPath: destinationURL.path) {
      do {
        try FileManager.default.removeItem(at: destinationURL)
      } catch {
        print("Failed to remove existing file at destination: \(error)")
      }
    }
    
    let asset = AVURLAsset(url: sourceURL)
    guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      failure?(NSError(
        domain: "AudioConversionError",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession."]
      ))
      return
    }
    
    exporter.outputFileType = .m4a
    exporter.outputURL = destinationURL
    
    exporter.exportAsynchronously {
      switch exporter.status {
      case .completed:
        print("M4A file written successfully at \(destinationURL)")
        success?()
      case .failed, .cancelled:
        if let error = exporter.error {
          print("Error during M4A conversion: \(error.localizedDescription) (\((error as NSError).code))")
        } else {
          print("Unknown error during M4A conversion")
        }
        failure?(exporter.error)
      default:
        break
      }
    }
  }
}
