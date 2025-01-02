//
//  ErrorResponse.swift
//  OysterApp
//
//  Created by Ewa on 30/12/2024.
//
import Foundation

struct ErrorResponse: Decodable {
    let timestamp: String
    let message: String
    let error: String
    let status: Int
}
