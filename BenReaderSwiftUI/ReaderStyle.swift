//
//  ReaderStyle.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 8/4/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class ReaderStyle: ObservableObject {
    
    static let shared = ReaderStyle() // Private static instance
    
    
    var fontSize: CGFloat = 20
    var spacing: CGFloat = 8
    var sides: CGFloat = 4
    var textColor: ReaderColor = ReaderColor(red: 1, green: 1, blue: 1, alpha: 1)
    var backgroundColor: ReaderColor = ReaderColor(red: 0, green: 0, blue: 0, alpha: 1)
    var hilightColor: String = "darkgreen"
    
    init() {
        
    }
    
    public func dark() {
        backgroundColor = .black
        textColor = .white
        hilightColor = "darkgreen"
    }
    
    public func light() {
        backgroundColor = .white
        textColor = .black
        hilightColor = "lightgreen"
    }
    
    public func sepia() {
        backgroundColor = ReaderColor(red: 0.984, green: 0.941, blue: 0.851, alpha: 1.0)
        textColor = ReaderColor(red: 0.372, green: 0.294, blue: 0.196, alpha: 1.0)
        hilightColor = "yellowgreen"
    }
    
    public func wide() {
        spacing = 2
        sides = 2
    }
    
    public func normalSpacing() {
        spacing = 8
        sides = 4
    }
    
    public func compact() {
        spacing = 8
        sides = 8
    }
    
    public func small() {
        fontSize = 12
    }
    
    public func normalSize() {
        fontSize = 20
    }
    
    public func largeSize() {
        fontSize = 28
    }
    
    public func giantSize() {
        fontSize = 36
    }
    
    public func getJS() -> String {
        return "refreshCSS(\"\(backgroundColor.toHexString())\", \"\(textColor.toHexString())\", \(sides), \(spacing), \(fontSize), \(hilightColor));"
    }
    
    static func getSharedInstance(modelContext: ModelContext) -> ReaderStyle {
           do {
               let descriptor = FetchDescriptor<ReaderStyle>()
               if let existingStyle = try modelContext.fetch(descriptor).first {
                   return existingStyle
               } else {
                   let newStyle = ReaderStyle()
                   modelContext.insert(newStyle)
                   return newStyle
               }
           } catch {
               fatalError("Failed to retrieve or create ReaderStyle: \(error)")
           }
       }
    
}
