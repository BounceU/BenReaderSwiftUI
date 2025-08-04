//
//  UnzipHelper.swift
//  BenReader
//
//  Created by Ben Liebkemann on 5/29/25.
//

import Foundation
import SSZipArchive

class UnzipHelper {
    
    static func unzipEPUB(epubURL: URL, unzipDirectory: URL, completion: @escaping (URL?) -> Void) {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
        let epubName = (epubURL.lastPathComponent as NSString).deletingPathExtension;
       // let unzipDirectory = documentsDirectory.appendingPathComponent(epubName);
        
        // Unzip
        do {
            try SSZipArchive.unzipFile(atPath: epubURL.path, toDestination: unzipDirectory.path, overwrite: true, password: nil);
            print("EPUB Unzipped successfully.");
            completion(unzipDirectory);
        } catch {
            print("Error unzipping file: \(error)");
            completion(nil);
        }
    }
    
    static func unzipZip(zipURL: URL, completion: @escaping (URL?) -> Void) {
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
        let zipName = (zipURL.lastPathComponent as NSString).deletingPathExtension;
        let unzipDirectory = documentsDirectory.appending(path: "\(zipName)/")//.appendingPathComponent("\(zipName)");
        
        // YOU NEED THIS LINE DO NOT DELETE!!!!!
        _ = zipURL.startAccessingSecurityScopedResource()
  
        // Unzip
        do {
            try SSZipArchive.unzipFile(atPath: zipURL.path, toDestination: unzipDirectory.path, overwrite: true, password: nil);
            print("Zip file unzipped successfully.");
            completion(unzipDirectory);
        } catch {
            print("Error unzipping file: \(error)");
            completion(nil);
        }
        
        zipURL.stopAccessingSecurityScopedResource()
    }
    
}
