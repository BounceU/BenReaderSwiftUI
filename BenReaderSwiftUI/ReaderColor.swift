//
//  ReaderColor.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 8/4/25.
//

import Foundation

struct ReaderColor: Codable {
    
    static let black = ReaderColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    static let white = ReaderColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    func toHexString() -> String {
        let rgb:Int = (Int)(red*255)<<16 | (Int)(green*255)<<8 | (Int)(blue*255)<<0
        return String(format:"#%06x", rgb)
    }
    
}

