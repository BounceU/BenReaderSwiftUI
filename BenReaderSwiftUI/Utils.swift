//
//  Utils.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/9/25.
//


import Foundation

public class Utils {
    
    
    // MARK: - Get Chapters
    static func loadChaptersFromBook(_ book: Book, ) -> [Chapter] {
        
        let timeStampPath = getTimestampURL(book.fileName)!
        
        guard let fileData = try? String(contentsOfFile: timeStampPath.path(), encoding: .ascii) else {
            return []
        }
        
        let lines = fileData.isEmpty ? [] : fileData.split(separator: "\r\n")
        
        
        var chapters: [Chapter] = []
        
        
        var paragraphs: [TimeInterval] = []
        var chapterTimes: [TimeInterval] = []
        
        // MARK: - Load all lines
        for line in lines {
            let useLine = line.replacingOccurrences(of: "\n", with: "");
            if useLine.contains("p ") {
                let timeString = useLine.replacingOccurrences(of: "p ", with: "");
                if let timestamp = Utils.parseDate(String(timeString)) {
                    paragraphs.append(timestamp)
                } else {
                   // print("Couldn't parse timestamp: \(timeString)")
                }
            } else if useLine.contains("c ") {
                let timeString = useLine.replacingOccurrences(of: "c ", with: "");
                if let timestamp = Utils.parseDate(String(timeString)) {
                    chapterTimes.append(timestamp)
                } else {
               //     print("Couldn't parse timestamp: \(timeString)")
                }
            } else {
                print("Line not conforming to specification");
            }
        }
        
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
        let epubParser = EpubParser(epubDirectory: documentsDirectory.appendingPathComponent("\(book.fileName)/"));
        epubParser.initializeData();
        
        // MARK: - Create chapters from lines
        for i in 0..<chapterTimes.count {
            let startTime = chapterTimes[i];
            let endTime = i == chapterTimes.count - 1 ? paragraphs.last! : chapterTimes[i + 1];
            
            var chapterParagraphs: [TimeInterval] = []
            
            for paragraph in paragraphs {
                if(paragraph > endTime) {
                    break;
                }
                if(paragraph > startTime) {
                    chapterParagraphs.append(paragraph);
                }
            }
            
            let newChapter = Chapter(chapterTitle: i >= epubParser.chapterTitles.count ? "" : epubParser.chapterTitles[i], startTime: startTime, endTime: endTime, paragraphs: chapterParagraphs, chapterPath: i >= epubParser.chapterPaths.count ? "" : epubParser.chapterPaths[i])
            chapters.append(newChapter);
            
            
        }
        
        
        
        
        
        
        
        return chapters
    }
    
    
    // MARK: - Audio URL

    static func getAudioURL(_ bookName: String) -> URL? {

        // 1. Get the Documents directory URL
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not get Documents directory URL")
            return nil
        }

        // 2. Create the file URL by appending the filename
        let fileURL = documentsDirectory.appendingPathComponent("\(bookName)/\(bookName).m4a");

        return fileURL
    }
    
    // MARK: - TimeStamp URL
    
    static func getTimestampURL(_ bookName: String) -> URL? {

        // 1. Get the Documents directory URL
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not get Documents directory URL")
            return nil
        }

        // 2. Create the file URL by appending the filename
        let fileURL = documentsDirectory.appendingPathComponent("\(bookName)/\(bookName).txt");

        return fileURL
    }
    
    // MARK: - Cover URL
    
    static func getCoverURL(_ bookName: String) -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            
            print("Error: Could not get Documents directory URL");
            return nil;
        }
        
        guard let enumerator = FileManager.default.enumerator(at: documentsDirectory.appendingPathComponent("\(bookName)"), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
            print("Can't get URLS from enumerator");
            return nil;
        }
        
        for fileURL in enumerator.allObjects as! [URL] {
            if fileURL.deletingPathExtension().lastPathComponent == "cover" {
                
                return fileURL.relativePath(from: documentsDirectory) ?? nil
            }
        }
        
        print("Error: Couldn't find cover");
        return nil;
        
    }
  
    // MARK: - Chapter URL
    static func getChapterURL(_ book: Book, _ chapter: Chapter) -> URL? {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
        let chapURL = documentsDirectory.appendingPathComponent("/\(book.fileName)/OEBPS/\(chapter.chapterPath)");
        return chapURL
    }
    
    // MARK: - Process File
    
    static func processSelectedFile(url: URL, books: [Book]) -> Book? {
        
        print("given URL: \(url)");
        
        if url.pathExtension != "zip" {
            return nil
        }
        
        let epubName = (url.lastPathComponent as NSString).deletingPathExtension;
        print("EPUB name: \(epubName)");
        for b in books {
            if b.fileName == epubName {
                return nil;
            }
        }
        
        print("Okay, the url is \(url)")
        
        UnzipHelper.unzipZip(zipURL: url) { unzipDirectory in
            print("unzipped directory: \(String(describing: unzipDirectory))");
            guard let _ = unzipDirectory else {
                print("error unizzping file");
                return;
            }
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
            let epubURL = documentsDirectory.appendingPathComponent("/\(epubName)/\(epubName).epub");
            if FileManager.default.fileExists(atPath: epubURL.path) {
                UnzipHelper.unzipEPUB(epubURL: epubURL) { unzipDirectory in
                    guard let  _ = unzipDirectory else {
                        print("error unizzping epub after unzipping zip.");
                        return;
                    }
                    
                    
                }
            }
        }
        
        // Got through successfully
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
        
        let newBook = Book(fileName: "\(epubName)");
        let parser = getChapterInfo(book: newBook);
        newBook.title = parser.title;
        newBook.author = parser.author;
        
//        epubParser.parseEpub(chapterNumber: 3) { url in
//            print("url: \(url)");
//        }
        
        
        
        return newBook;
        
        
    }
    
    static func getChapterInfo(book: Book) -> EpubParser {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
        let epubParser = EpubParser(epubDirectory: documentsDirectory.appendingPathComponent("\(book.fileName)/"));
        epubParser.initializeData();
        return epubParser;
    }
    
    
    
    // MARK: - Date Stuff
    
    static func parseDate(_ input: String) -> TimeInterval? {
        
        let components = input.split(separator: " ")
        
        if components.count == 1 {
            guard let fromTime = getFromTime(components[0]) else {
                return nil
            }
            return TimeInterval(fromTime);
        } else {
            let time = components.last!;
            guard let fromTime = getFromTime(time) else {
                return nil;
            }
            
            guard let days = Double(components[0]) else {
                return nil;
            }
            
            return TimeInterval(fromTime + days * 24.0 * 60.0 * 60.0);
            
        }
        
    }

    private static func getFromTime(_ input: String.SubSequence) -> Double? {
        let times = input.split(separator: ":")
     
        guard let hourSecs = Double(times[0]) else {
            return nil
        }
        guard let minSecs = Double(times[1]) else {
            return nil
        }
        guard let secs = Double(times[2]) else {
            return nil
        }
        let outTime: Double = hourSecs * 60.0 * 60.0 + minSecs * 60.0 + secs
        return outTime;
    }
    
}

// MARK: - URL Extension

extension URL {
    func relativePath(from base: URL) -> String? {
        // Ensure that both URLs represent files:
        guard self.isFileURL && base.isFileURL else {
            return nil
        }

        //this is the new part, clearly, need to use workBase in lower part
        var workBase = base
        if workBase.pathExtension != "" {
            workBase = workBase.deletingLastPathComponent()
        }

        // Remove/replace "." and "..", make paths absolute:
        let destComponents = self.standardized.resolvingSymlinksInPath().pathComponents
        let baseComponents = workBase.standardized.resolvingSymlinksInPath().pathComponents

        // Find number of common path components:
        var i = 0
        while i < destComponents.count &&
              i < baseComponents.count &&
              destComponents[i] == baseComponents[i] {
                i += 1
        }

        // Build relative path:
        var relComponents = Array(repeating: "..", count: baseComponents.count - i)
        relComponents.append(contentsOf: destComponents[i...])
        return relComponents.joined(separator: "/")
    }
}
