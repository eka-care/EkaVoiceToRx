//
//  HTTPHeader.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//


/// Use this enum to add other standard headers
public enum HTTPHeader: String {
  case contentTypeJson = "application/json"
  case multipartFormData = "multipart/form-data"
  case protobuf = "application/x-protobuf"
}
