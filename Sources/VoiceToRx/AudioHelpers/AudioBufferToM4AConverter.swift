//
//  AudioBufferToM4AConverter.swift
//  EkaCareDoctor
//
//  Created by Arya Vashisht on 13/08/24.
//

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
    fileExtension: String = AudioFileFormat.m4aFile.extensionString,
    completion: @escaping (Result<URL, Error>) -> Void
  ) {
    /// Temporary directory
    let documentDirectoryURL = FileHelper.getDocumentDirectoryURL()
    
    /// Unique file names
    let pcmFileName = "\(fileKey)\(AudioFileFormat.coreAudioFile.extensionString)"
    let m4aFileName = "\(fileKey)\(fileExtension)"
    
    /// File URLs
    let outputPCMURL = documentDirectoryURL
      .appendingPathComponent(sessionId)
      .appendingPathComponent(pcmFileName)
    let outputM4AURL = documentDirectoryURL
      .appendingPathComponent(sessionId)
      .appendingPathComponent(m4aFileName)
    
    cafUrlsStored.append(outputPCMURL)
    
    do {
      /// Create AVAudioFile for writing PCM data
      let outputAudioFile = try AVAudioFile(forWriting: outputPCMURL, settings: pcmBuffer.format.settings, commonFormat: pcmBuffer.format.commonFormat, interleaved: pcmBuffer.format.isInterleaved)
      
      /// Write the PCM buffer to the file
      try outputAudioFile.write(from: pcmBuffer)
      print("PCM file written successfully at \(outputPCMURL)")
      
      /// Convert the PCM file to M4A
      convertToM4A(sourceURL: outputPCMURL, destinationURL: outputM4AURL, success: { [weak self] in
        guard let self else { return }
        /// Once converted remove the PCM file
        FileHelper.removeFile(at: outputPCMURL)
        completion(.success(outputM4AURL))
        urlsStored.append(outputM4AURL)
      }, failure: { error in
        completion(.failure(error ?? NSError(domain: "AudioConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error during M4A conversion."])))
      })
    } catch {
      /// Handle the error
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
    let asset = AVURLAsset(url: sourceURL)
    guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      failure?(NSError(domain: "AudioConversionError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession."]))
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
        print("Error during M4A conversion: \(String(describing: exporter.error))")
        failure?(exporter.error)
      default:
        break
      }
    }
  }
}
