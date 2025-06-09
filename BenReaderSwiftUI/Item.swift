//
//  Item.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/9/25.
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
