//
//  WebCoordinator.swift
//  BenReaderSwiftUI
//
//  Created by Ben Liebkemann on 6/18/25.
//



import Foundation
import WebKit

class WebCoordinator {
    
    var webview: WKWebView?
    
    init() {
        
    }
    
    func updateWebView(_ newWebView: WKWebView) {
        webview = newWebView
    }
    
    
}
