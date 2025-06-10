//
//  Utils.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/9/25.
//



import Foundation

public class Utils {

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
    
    static func getCoverURL(_ bookName: String) -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            
            print("Error: Could not get Documents directory URL");
            return nil;
        }
        
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: documentsDirectory.appendingPathComponent("\(bookName)/"), includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            print("Error: Could not get book directory URL");
            return nil;
        }
        
        for fileURL in fileURLs {
            if fileURL.deletingPathExtension().lastPathComponent == "cover" {
                return fileURL
            }
        }
        
        print("Error: Couldn't find cover");
        return nil;
        
    }
  
        
          
}
