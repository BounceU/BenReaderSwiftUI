//
//  EpubParser.swift
//  BenReaderSwiftUI
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
    
    var title: String = "";
    var author: String = "";
    var chapterTitles: [String] = [];
    var chapterPaths: [String] = [];
    
    init(epubDirectory: URL) {
        self.unzipDirectory = epubDirectory;
    }
    
    func initializeData() {
        let containerXMLPath = unzipDirectory.appendingPathComponent("META-INF/container.xml").path;
        
        print("xmlParser initialize, xml path: \(containerXMLPath)");
        
        if let containerXMLData = FileManager.default.contents(atPath: containerXMLPath) {
            
            
            print("xmlParser data: \(String(data: containerXMLData, encoding: .utf8) ?? "")");
            
            let xml = XMLHash.parse(containerXMLData);
            
            if let rootfilePath = xml["container"]["rootfiles"]["rootfile"].element?.attribute(by: "full-path")?.text {
                let opfURL = unzipDirectory.appendingPathComponent(rootfilePath);
                
                // Get Author and Title from content.opf
                if let xmlDat = try? XMLHash.parse(Data(contentsOf: opfURL)) {
            
                    self.author = xmlDat["package"]["metadata"]["dc:creator"].element?.text ?? "";
                    self.title = xmlDat["package"]["metadata"]["dc:title"].element?.text ?? "Default title"
                    
                    print("Got author and title: \(author), \(title)")
                    
                } else {
                    print("Error: Could not get data from OPF for author and title")
                }
                
                // Get spine item paths from content.opf
                if let opfParser = XMLParser(contentsOf: opfURL) {
                    opfParser.delegate = self;
                    
                    opfParser.parse();
                    
                    for i in 0..<spineItems.count {
                        if let chapterPath = manifestItems[spineItems[i]] {
                            let chapterFullPath = "\(chapterPath)";
                            print("Got chapter path \(chapterFullPath)")
                            self.chapterPaths.append(chapterFullPath);
                        }
                        
                    }
                    
                } else {
                    print("Error: could not parse OPF for chapter paths")
                }
                
                
                // Get chapter names from toc.ncx
                let tocURL = opfURL.deletingLastPathComponent().appendingPathComponent("toc.ncx");
                if let tocDat = try? XMLHash.parse(Data(contentsOf: tocURL)) {
                    tocDat["ncx"]["navMap"]["navPoint"].all.forEach { (navPoint) in
                        self.chapterTitles.append(navPoint["navLabel"]["text"].element?.text ?? "Couldn't get name");
                        print("Got chapter name \(navPoint["navLabel"]["text"].element?.text ?? "Couldn't get name")")
                    }
                } else {
                    print("Error: Couldn't parse table of contents");
                }
                
                
                
            } else {
                print("Error: could not get root file path")
            }
        } else {
            print("Error: could not get xml data")
        }
        
       
        
    }
    
    func parseEpub(chapterNumber: Int, completion: @escaping (URL?) -> Void) {
        print("chapterNumber: \(chapterNumber)")
        
        let containerXMLPath = unzipDirectory.appendingPathComponent("META-INF/container.xml").path;
        
        print("containerXMLPath: \(containerXMLPath)");
        
        if let containerXMLData = FileManager.default.contents(atPath: containerXMLPath) {
            
            
            let xml = XMLHash.parse(containerXMLData);
            print("XML: \(xml)")
            
            if let rootfilePath = xml["container"]["rootfiles"]["rootfile"].element?.attribute(by: "full-path")?.text {
                let opfURL = unzipDirectory.appendingPathComponent(rootfilePath);
                if let xmlDat = try? XMLHash.parse(Data(contentsOf: opfURL)) {
                  
                    
                    print("Title: \(xmlDat["package"]["metadata"]["dc:title"].element?.text ?? "Default title")");
                    
                    print("Author: \(xmlDat["package"]["metadata"]["dc:creator"].element?.text ?? "Default title")");
                    
                } else {
                    
                }
                parseOPFFile(opfURL, chapterNumber: chapterNumber, completion: completion);
            } else {
                print("Error: could not get root file path")
            }
        } else {
            print("Error: could not get xml data")
        }
        
    }
    
    func getCover() -> URL? {
        if let imageURL = manifestItems["cover-image"] {
            print("COVER IMAGE: \(imageURL)")
            return unzipDirectory.appendingPathComponent("OEBPS/\(imageURL)");
        } else {
            print("Can't find cover image")
            return nil
        }
    }
    
    func getAuthor() -> String? {
        
        let containerXMLPath = unzipDirectory.appendingPathComponent("META-INF/container.xml").path;
        
        print("containerXMLPath: \(containerXMLPath)");
        if let containerXMLData = FileManager.default.contents(atPath: containerXMLPath) {
            
            _ = XMLHash.parse(containerXMLData);
        }
        
        return nil;
    }
    
    
    private func parseOPFFile(_ opfURL: URL, chapterNumber: Int, completion: @escaping (URL?) -> Void) {
        
        
        
        if let opfParser = XMLParser(contentsOf: opfURL) {
            opfParser.delegate = self;
            
            opfParser.parse();
            
          //  print("OPF Parser: \(opfParser)");
          //  print("spine items: \(spineItems)")
          //  print("manifest items: \(manifestItems)")
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
      //  print("elementName: \(elementName)\n namespaceURI: \(namespaceURI ?? "nil")\n qName: \(qName ?? "nil")\n attributes: \(attributeDict)\n")
       
        if elementName == "itemref", let idref = attributeDict["idref"] {
            spineItems.append(idref)
        } else if elementName == "item", let itemId = attributeDict["id"], let href = attributeDict["href"] {
            manifestItems[itemId] = href
        }
        
    }
}
