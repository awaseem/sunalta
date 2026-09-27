//
//  Item.swift
//  clock-app
//
//  Created by Ali Waseem on 2026-09-27.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
