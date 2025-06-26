//
//  Chapter.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/10/25.
//

import Foundation

public class Chapter {
    
    var startTime: TimeInterval;
    var endTime: TimeInterval;
    var title: String;
    var paragraphTimes: [TimeInterval];
    var chapterPath: String;
    
    init() {
        self.startTime = TimeInterval(0)
        self.endTime = TimeInterval(1)
        self.title = "Default title"
        self.paragraphTimes = []
        self.chapterPath = ""
    }
    
    init(chapterTitle: String, startTime: TimeInterval, endTime: TimeInterval, paragraphs: [TimeInterval], chapterPath: String) {
        self.startTime = startTime;
        self.endTime = endTime;
        self.paragraphTimes = paragraphs;
        self.title = chapterTitle;
        self.chapterPath = chapterPath
        
    }
    
    init(title: String, startTime: String, endTime: String) {
        self.startTime = TimeInterval(Utils.parseDate(startTime) ?? 0)
        self.endTime = TimeInterval(Utils.parseDate(endTime) ?? 1)
        self.title = title;
        self.paragraphTimes = []
        self.chapterPath = ""
    }
    
    
    func getParagraphNumber(_ time: TimeInterval) -> Int {
        
        for (i, p) in paragraphTimes.enumerated() {
            if p >= time {
                return i
            }
        }
        
        return 0
    }
    
}
