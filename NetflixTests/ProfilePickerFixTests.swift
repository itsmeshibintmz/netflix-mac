import WebKit
import XCTest

@MainActor
final class ProfilePickerFixTests: XCTestCase {
    private final class LoadWaiter: NSObject, WKNavigationDelegate {
        let expectation: XCTestExpectation
        init(_ expectation: XCTestExpectation) { self.expectation = expectation }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { expectation.fulfill() }
    }

    private func loadWebView(header: String, includeIcon: Bool = true) async -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(WKUserScript(
            source: NetflixWebView.profilePickerFixSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        ))
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: configuration)
        let loaded = expectation(description: "loaded")
        let waiter = LoadWaiter(loaded)
        webView.navigationDelegate = waiter
        let html = """
        <body style="margin:0">\(header)
        \(includeIcon ? Self.iconHTML : "")
        </body>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.netflix.com/browse"))
        await fulfillment(of: [loaded], timeout: 10)
        return webView
    }

    private static let iconHTML = """
    <div style="position:relative;margin-top:-60px;height:300px">
      <div id="holder" style="position:relative"><div style="position:absolute;top:0;left:0">
        <img id="lock" width="130" height="130" style="display:block">
      </div></div>
    </div>
    """

    private func iconTop(header: String) async throws -> Double {
        let webView = await loadWebView(header: header)
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

    func testDynamicallyInsertedIconIsCorrectedWithoutDebounce() async throws {
        let webView = await loadWebView(header: "", includeIcon: false)
        let top = try await webView.callAsyncJavaScript("""
            document.body.insertAdjacentHTML('beforeend', iconHTML);
            await new Promise(resolve => setTimeout(resolve, 30));
            return document.getElementById('lock').getBoundingClientRect().top;
            """, arguments: ["iconHTML": Self.iconHTML], in: nil, contentWorld: .page)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(top as? Double), 12)
    }

    func testResizeRemovesOffsetWhenIconAlreadyFits() async throws {
        let webView = await loadWebView(header: "")
        let top = try await webView.evaluateJavaScript("""
            document.getElementById('holder').parentElement.style.marginTop = '50px';
            window.dispatchEvent(new Event('resize'));
            document.getElementById('lock').getBoundingClientRect().top;
            """)
        XCTAssertEqual(try XCTUnwrap(top as? Double), 50)
    }
}
