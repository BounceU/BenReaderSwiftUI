
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
