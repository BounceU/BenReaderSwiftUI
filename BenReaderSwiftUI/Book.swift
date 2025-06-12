//
//  Book.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/9/25.
//

import Foundation
import SwiftUI
import SwiftData

@Model
final class Book: ObservableObject {
    
    var title: String;
    var author: String;
    var fileName: String;
    var image: String;
    var location: TimeInterval;
    var lastOpened: Date;
    
    init(title: String = "Default Title", author: String = "John Doe", image: String = "default_cover") {
        self.title = title;
        self.author = author;
        self.image = image;
        self.fileName = "";
        self.location = TimeInterval(0);
        self.lastOpened = Date.now;
    }
    
    init(fileName: String) {
        self.fileName = fileName;
        self.title = fileName;
        
        self.image = Utils.getCoverURL(fileName) ?? "default_cover";
        
        
        self.author = "";
        self.location = TimeInterval(0);
        self.lastOpened = Date.now;
        print("Getting \(image)")
    }
}
