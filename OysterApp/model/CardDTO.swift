//
//  CardDTO.swift
//  OysterApp
//
//  Created by Ewa on 17/12/2024.
//
import Foundation

struct CardDTO: Codable {
    let id: Int64
    let cardNumber: Int64
    let userId: Int64
    let issuedAt: String
    let balance: Double

}
