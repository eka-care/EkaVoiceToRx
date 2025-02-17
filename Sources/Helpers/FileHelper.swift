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
}
