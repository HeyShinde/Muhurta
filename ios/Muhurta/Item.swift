//
//  Item.swift
//  Muhurta
//
//  Created by Shinde on 24/10/26.
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
