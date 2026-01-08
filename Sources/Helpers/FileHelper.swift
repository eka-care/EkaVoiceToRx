//
//  FileHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import Foundation

final class FileHelper {
  public static func getDocumentDirectoryURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
  
  public static func removeFile(at url: URL) {
    do {
      try FileManager.default.removeItem(at: url)
    } catch {
      debugPrint("Error deleting temporary files: \(error)")
    }
  }
  
  public static func getFileURLs(in directory: URL) -> [URL]? {
    let fileManager = FileManager.default
    do {
      let fileURLs = try fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: nil
      )
      return fileURLs.isEmpty ? nil : fileURLs
    } catch {
      print("Error while enumerating files \(directory.path): \(error.localizedDescription)")
      return nil
    }
  }
  
  public static func deleteOldFullAudioFiles(for ownerId: String) async -> Int {
    guard !ownerId.isEmpty else {
      return 0
    }
    
    let fileManager = FileManager.default
    let documentsDirectory = getDocumentDirectoryURL()
    var deletedCount = 0
    
    do {
      let sessionDirectories = try fileManager.contentsOfDirectory(
        at: documentsDirectory,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
      
      let sessionIdsForOwner = await VoiceToRxRepo.shared.getSessionIds(for: ownerId)
      
      for sessionDir in sessionDirectories {
        let resourceValues = try? sessionDir.resourceValues(forKeys: [.isDirectoryKey])
        guard resourceValues?.isDirectory == true else { continue }
        
        let sessionIdString = sessionDir.lastPathComponent
        let fullAudioPath = sessionDir.appendingPathComponent("full_audio.m4a_")
        
        if sessionIdsForOwner.contains(sessionIdString),
           fileManager.fileExists(atPath: fullAudioPath.path) {
          removeFile(at: fullAudioPath)
          deletedCount += 1
          
          if let remainingFiles = getFileURLs(in: sessionDir), remainingFiles.isEmpty {
            do {
              try fileManager.removeItem(at: sessionDir)
            } catch {
              print("Error deleting empty session directory: \(error.localizedDescription)")
            }
          }
        }
      }
    } catch {
      debugPrint("Error deleting old full audio files: \(error.localizedDescription)")
    }
    
    return deletedCount
  }
}
