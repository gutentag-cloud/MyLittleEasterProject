import AppKit
import WebKit

/// Renders web pages / HTML5 content using WKWebView.
final class WebRenderer: NSObject, WallpaperRenderer, WKNavigationDelegate {
    
    let targetView: NSView
    private let configuration: Configuration
    private var webView: WKWebView?
    private var audioSpectrum: AudioSpectrum?
    
    init(targetView: NSView, configuration: Configuration) {
        self.targetView = targetView
        self.configuration = configuration
    }
    
    func load(url: URL) {
        cleanup()
        
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = false
        
        // Add user script to inject audio data
        let userController = WKUserContentController()
        userController.add(ScriptMessageHandler(renderer: self), name: "macLiveEngine")
        config.userContentController = userController
        
        let webView = WKWebView(frame: targetView.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")
        
        // Remove old subviews
        targetView.subviews.forEach { $0.removeFromSuperview() }
        targetView.addSubview(webView)
        
        if url.isFileURL {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.load(URLRequest(url: url))
        }
        
        self.webView = webView
        Logger.shared.info("Web wallpaper loaded: \(url)")
    }
    
    func start() {
        webView?.evaluateJavaScript("if(typeof onStart === 'function') onStart();")
    }
    
    func pause() {
        webView?.evaluateJavaScript("if(typeof onPause === 'function') onPause();")
    }
    
    func resume() {
        webView?.evaluateJavaScript("if(typeof onResume === 'function') onResume();")
    }
    
    func stop() {
        webView?.evaluateJavaScript("if(typeof onStop === 'function') onStop();")
        cleanup()
    }
    
    func setTargetFPS(_ fps: Int) {
        webView?.evaluateJavaScript("if(typeof setFPS === 'function') setFPS(\(fps));")
    }
    
    func receiveAudioSpectrum(_ spectrum: AudioSpectrum) {
        self.audioSpectrum = spectrum
        // Send audio data to JavaScript
        guard let data = try? JSONEncoder().encode(spectrum.bands),
              let json = String(data: data, encoding: .utf8) else { return }
        webView?.evaluateJavaScript("""
            if(typeof onAudioData === 'function') onAudioData(\(json));
        """)
    }
    
    func setProperty(_ key: String, value: Any) {
        if let jsonValue = try? JSONSerialization.data(withJSONObject: value),
           let jsonString = String(data: jsonValue, encoding: .utf8) {
            webView?.evaluateJavaScript("""
                if(typeof onPropertyChange === 'function') onPropertyChange('\(key)', \(jsonString));
            """)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Logger.shared.error("Web wallpaper navigation error: \(error.localizedDescription)")
    }
    
    private func cleanup() {
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
    }
}

/// Handles messages from JavaScript.
private class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var renderer: WebRenderer?
    init(renderer: WebRenderer) { self.renderer = renderer }
    
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        // Handle messages from web wallpaper
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }
        
        switch action {
        case "log":
            if let msg = body["message"] as? String {
                Logger.shared.info("[WebWallpaper] \(msg)")
            }
        default:
            break
        }
    }
}
