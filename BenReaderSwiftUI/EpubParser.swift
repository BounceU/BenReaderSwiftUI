//
//  EpubParser.swift
//  BenReader
//
//  Created by Ben Liebkemann on 5/29/25.
//


import Foundation
import SWXMLHash

class EpubParser: NSObject, XMLParserDelegate {
    
    private var unzipDirectory: URL!;
    
    private var manifestItems: [String: String] = [:];
    private var spineItems: [String] = [];
    private var currentElement: String = "";
    private var currentAttributes: [String: String] = [:];
    private var opfFilePath: String = "";
    
    init(epubDirectory: URL) {
        self.unzipDirectory = epubDirectory;
    }
    
    func parseEpub(chapterNumber: Int, completion: @escaping (URL?) -> Void) {
        print("chapterNumber: \(chapterNumber)")
        
        let containerXMLPath = unzipDirectory.appendingPathComponent("META-INF/container.xml").path;
        
        print("containerXMLPath: \(containerXMLPath)");
        
        if let containerXMLData = FileManager.default.contents(atPath: containerXMLPath) {
            
            let xml = XMLHash.parse(containerXMLData);
            if let rootfilePath = xml["container"]["rootfiles"]["rootfile"].element?.attribute(by: "full-path")?.text {
                let opfURL = unzipDirectory.appendingPathComponent(rootfilePath);
                parseOPFFile(opfURL, chapterNumber: chapterNumber, completion: completion);
            } else {
                print("Error: could not get root file path")
            }
        } else {
            print("Error: could not get xml data")
        }
        
    }
    
    
    
    func getAuthor() -> String? {
        
        let containerXMLPath = unzipDirectory.appendingPathComponent("META-INF/container.xml").path;
        
        print("containerXMLPath: \(containerXMLPath)");
        if let containerXMLData = FileManager.default.contents(atPath: containerXMLPath) {
            
            let xml = XMLHash.parse(containerXMLData);
        }
        
        return nil;
    }
    
    
    private func parseOPFFile(_ opfURL: URL, chapterNumber: Int, completion: @escaping (URL?) -> Void) {
        
        if let opfParser = XMLParser(contentsOf: opfURL) {
            opfParser.delegate = self;
            opfParser.parse();
            print("spine items: \(spineItems)")
            print("manifest items: \(manifestItems)")
            if chapterNumber < spineItems.count, let chapterPath = manifestItems[spineItems[chapterNumber]] {
                let chapterFullPath = "\(chapterPath)";
                let chapterURL = unzipDirectory.appendingPathComponent(chapterFullPath);
                completion(chapterURL);
            } else {
                completion(nil);
            }
        } else {
            completion(nil);
        }
        
    }
    
    
    
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        
        if elementName == "itemref", let idref = attributeDict["idref"] {
            spineItems.append(idref)
        } else if elementName == "item", let itemId = attributeDict["id"], let href = attributeDict["href"] {
            manifestItems[itemId] = href
        }
        
    }
}
