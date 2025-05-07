//
//  RequestProvider.swift
//  EkaVoiceToRx
//
//  Created by Arya Vashisht on 06/05/25.
//

import Alamofire

public protocol RequestProvider {
  var urlRequest: DataRequest { get }
}
