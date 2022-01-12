//
//  Apod.swift
//  testNasaApp
//
//  Created by Sai Leung on 1/12/22.
//

import Foundation

struct Apod: Decodable {
    
    let date, explanation, serviceVersion, title, url: String
    let mediaType: MediaType
    
    enum MediaType: String, Decodable {
        case image, video
    }
    
    enum CodingKeys: String, CodingKey {
        case date, explanation, title, url
        case mediaType = "media_type"
        case serviceVersion = "service_version"
    }
}
