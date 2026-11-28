import WebKit
import XCTest

@MainActor
final class ProfilePickerFixTests: XCTestCase {
    private final class LoadWaiter: NSObject, WKNavigationDelegate {
        let expectation: XCTestExpectation
        init(_ expectation: XCTestExpectation) { self.expectation = expectation }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { expectation.fulfill() }
    }

    private func iconTop(header: String) async throws -> Double {
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        let loaded = expectation(description: "loaded")
        let waiter = LoadWaiter(loaded)
        webView.navigationDelegate = waiter
        let html = """
        <body style="margin:0">\(header)
        <div style="position:relative;margin-top:-60px;height:300px">
          <div id="holder" style="position:relative"><div style="position:absolute;top:0;left:0">
            <img id="lock" width="130" height="130" style="display:block">
          </div></div>
        </div></body>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.netflix.com/browse"))
        await fulfillment(of: [loaded], timeout: 10)

        _ = try await webView.evaluateJavaScript(NetflixWebView.profilePickerFixSource)
        _ = try await webView.evaluateJavaScript("window.__macFlixProfileFix.apply()")
        let top = try await webView.evaluateJavaScript("document.getElementById('lock').getBoundingClientRect().top")
        return try XCTUnwrap(top as? Double)
    }

    func testLockIconAboveViewportIsMovedIntoView() async throws {
        let top = try await iconTop(header: "")
        XCTAssertGreaterThanOrEqual(top, 12)
    }

    func testHomePageWithPinningHeaderIsLeftAlone() async throws {
        let top = try await iconTop(header: "<div class='pinning-header'></div>")
        XCTAssertEqual(top, -60)
    }
}
