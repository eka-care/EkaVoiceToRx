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
    isFullAudio: Bool = false,
    fileExtension: String = AudioFileFormat.m4aFile.extensionString
  ) async throws -> URL {
    
    print("#BB writePcmuffer is getting called")
    let documentDirectoryURL = FileHelper.getDocumentDirectoryURL()
    
    let pcmFileName = "\(fileKey)\(AudioFileFormat.coreAudioFile.extensionString)"
    let m4aFileName = "\(fileKey)\(fileExtension)"
    
    let outputPCMURL = documentDirectoryURL.appendingPathComponent(pcmFileName)
    let sessionDirectoryURL = documentDirectoryURL.appendingPathComponent(sessionId)
    let outputM4AURL = sessionDirectoryURL.appendingPathComponent(m4aFileName)
    
    cafUrlsStored.append(outputPCMURL)
    
    do {
      try FileManager.default.createDirectory(at: sessionDirectoryURL, withIntermediateDirectories: true)
      
      let outputAudioFile = try AVAudioFile(
        forWriting: outputPCMURL,
        settings: pcmBuffer.format.settings,
        commonFormat: pcmBuffer.format.commonFormat,
        interleaved: pcmBuffer.format.isInterleaved
      )
      
      try outputAudioFile.write(from: pcmBuffer)
      print("#BB PCM file written successfully at \(outputPCMURL)")
      
      try await convertToM4A(sourceURL: outputPCMURL, destinationURL: outputM4AURL)
      
      print("Removed intermediate PCM file at \(outputPCMURL)")
      FileHelper.removeFile(at: outputPCMURL)
      
      urlsStored.append(outputM4AURL)
      return outputM4AURL
      
    } catch {
      print("Error: \(error.localizedDescription)")
      throw error
    }
  }
  
  private func convertToM4A(sourceURL: URL, destinationURL: URL) async throws {
    print("Source URL -> \(sourceURL)")
    print("Destination URL -> \(destinationURL)")
    
    if FileManager.default.fileExists(atPath: destinationURL.path) {
      do {
        try FileManager.default.removeItem(at: destinationURL)
      } catch {
        print("Failed to remove existing file at destination: \(error)")
        throw error
      }
    }
    
    let asset = AVURLAsset(url: sourceURL)
    guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      throw NSError(
        domain: "AudioConversionError",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to create AVAssetExportSession."]
      )
    }
    
    exporter.outputFileType = .m4a
    exporter.outputURL = destinationURL
    
    try await withCheckedThrowingContinuation { continuation in
      exporter.exportAsynchronously {
        switch exporter.status {
        case .completed:
          print("M4A file written successfully at \(destinationURL)")
          continuation.resume()
        case .failed, .cancelled:
          let error = exporter.error ?? NSError(
            domain: "AudioConversionError",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error during M4A conversion."]
          )
          print("Error during M4A conversion: \(error.localizedDescription) (\((error as NSError).code))")
          continuation.resume(throwing: error)
        default:
          break
        }
      }
    }
  }
}
