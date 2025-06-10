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
final class Book {
    
    var title: String;
    var author: String;
    var fileName: String;
    var image: String;
    
    init(title: String = "Default Title", author: String = "John Doe", image: String = "default_cover") {
        self.title = title;
        self.author = author;
        self.image = image;
        self.fileName = "";
    }
    
    init(fileName: String) {
        self.fileName = fileName;
        self.title = fileName;
        
        self.image = Utils.getCoverURL(fileName)?.absoluteString ?? "default_cover";
        self.author = "";
    }
}
