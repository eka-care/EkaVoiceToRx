//
//  provides.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//


/// This class provides the singleton object for making API service requests
public final class NetworkService: Networking {
  public static let shared = NetworkService()
}