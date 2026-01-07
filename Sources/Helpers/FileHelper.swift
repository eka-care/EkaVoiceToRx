//
//  FileHelper.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 12/02/25.
//

import Foundation
import CoreData

final class FileHelper {
  public static func getDocumentDirectoryURL() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }
  
  public static func removeFile(at url: URL) {
    do {
      try FileManager.default.removeItem(at: url)
      debugPrint("Deleted File with url -> \(url)")
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

  public static func deleteOldFullAudioFiles(for ownerId: String) -> Int {
    guard !ownerId.isEmpty else {
      debugPrint("#BB Cannot delete full audio files: ownerId is empty")
      return 0
    }
    
    let fileManager = FileManager.default
    let documentsDirectory = getDocumentDirectoryURL()
    var deletedCount = 0
    
    do {
      // Get all session directories
      let sessionDirectories = try fileManager.contentsOfDirectory(
        at: documentsDirectory,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
      )
      
      // Get session IDs for this ownerId from database
      let sessionIdsForOwner = getSessionIds(for: ownerId)
      
      // Find and delete full_audio.m4a_ files for sessions belonging to this ownerId
      for sessionDir in sessionDirectories {
        let resourceValues = try? sessionDir.resourceValues(forKeys: [.isDirectoryKey])
        guard resourceValues?.isDirectory == true else { continue }
        
        let sessionIdString = sessionDir.lastPathComponent
        let fullAudioPath = sessionDir.appendingPathComponent("full_audio.m4a_")
        
        // Check if this session belongs to the ownerId and file exists
        if sessionIdsForOwner.contains(sessionIdString),
           fileManager.fileExists(atPath: fullAudioPath.path) {
          removeFile(at: fullAudioPath)
          deletedCount += 1
          debugPrint("#BB Deleted old full audio file for ownerId '\(ownerId)': \(fullAudioPath.path)")
          
          // Try to delete the session directory if it's empty
          if let remainingFiles = getFileURLs(in: sessionDir), remainingFiles.isEmpty {
            do {
              try fileManager.removeItem(at: sessionDir)
              debugPrint("#BBDeleted empty session directory: \(sessionDir.path)")
            } catch {
              debugPrint("#BB Failed to delete empty session directory: \(error.localizedDescription)")
            }
          }
        }
      }
      
      if deletedCount > 0 {
        debugPrint("Deleted \(deletedCount) old full audio file(s) for ownerId '\(ownerId)'")
      }
      
    } catch {
      debugPrint("Error deleting old full audio files: \(error.localizedDescription)")
    }
    
    return deletedCount
  }
  
  /// Gets all session IDs for a specific ownerId by querying the database
  /// - Parameter ownerId: The owner ID to find sessions for
  /// - Returns: Set of session ID strings
  private static func getSessionIds(for ownerId: String) -> Set<String> {
    var sessionIds: Set<String> = []
    
    let databaseManager = VoiceConversationDatabaseManager.shared
    let fetchRequest: NSFetchRequest<VoiceConversation> = VoiceConversation.fetchRequest()
    
    do {
      let conversations = try databaseManager.container.viewContext.fetch(fetchRequest)
      
      for conversation in conversations {
        guard let sessionID = conversation.sessionID else { continue }
        
        // Decode sessionData to get ownerId
        if let sessionData = conversation.sessionData,
           let contextParams = decodeSessionData(sessionData),
           contextParams.doctor?.id == ownerId {
          sessionIds.insert(sessionID.uuidString)
        }
      }
    } catch {
      debugPrint("Error fetching sessions for ownerId '\(ownerId)': \(error.localizedDescription)")
    }
    
    return sessionIds
  }
  
  /// Decodes sessionData binary data to VoiceToRxContextParams
  /// - Parameter data: Binary data from CoreData
  /// - Returns: Decoded VoiceToRxContextParams or nil
  private static func decodeSessionData(_ data: Data) -> VoiceToRxContextParams? {
    let decoder = JSONDecoder()
    do {
      let contextParams = try decoder.decode(VoiceToRxContextParams.self, from: data)
      return contextParams
    } catch {
      debugPrint("Failed to decode sessionData: \(error.localizedDescription)")
      return nil
    }
  }
}
