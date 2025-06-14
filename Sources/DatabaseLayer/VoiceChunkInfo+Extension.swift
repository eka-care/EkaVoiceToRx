//
//  VoiceChunkInfo+Extension.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 27/05/25.
//

import CoreData

extension VoiceChunkInfo {
  func update(from model: VoiceChunkInfoArguementModel) {
    fileName = model.fileName
    if let startTime = model.startTime {
      self.startTime = startTime
    }
    if let endTime = model.endTime {
      self.endTime = endTime
    }
    if let fileURI = model.fileURL {
      self.fileURI = fileURI
    }
    isFileUploaded = model.isFileUploaded
  }
}
