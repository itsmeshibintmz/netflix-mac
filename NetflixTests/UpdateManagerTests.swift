import Combine
import Foundation
import XCTest

private final class StubURLProtocol: URLProtocol {
    static var statusCode = 200
    static var body = ""

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@MainActor
final class UpdateManagerTests: XCTestCase {
    private func check(body: String, status: Int = 200, manual: Bool = true) -> UpdateManager {
        StubURLProtocol.body = body
        StubURLProtocol.statusCode = status
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let manager = UpdateManager(session: URLSession(configuration: configuration), startingUpdater: false)
        let completed = expectation(description: "update check completed")
        let subscription = manager.$isCheckingForUpdates.dropFirst().filter { !$0 }.sink { _ in
            completed.fulfill()
        }
        manager.checkForUpdates(manual: manual)
        wait(for: [completed], timeout: 5)
        withExtendedLifetime(subscription) {}
        return manager
    }

    func testManualCheckReportsUpToDate() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let manager = check(body: """
            {"tag_name":"v.\(currentVersion)","body":null,"assets":[]}
            """)
        XCTAssertTrue(manager.isUpToDate)
        XCTAssertNil(manager.updateError)
        XCTAssertFalse(manager.isCheckingForUpdates)
    }

    func testManualCheckShowsNewRelease() {
        let manager = check(body: #"{"tag_name":"v.9999.0.0","body":"Notes","assets":[{"name":"Netflix.dmg","browser_download_url":"https://example.com/Netflix.dmg"}]}"#)
        XCTAssertTrue(manager.isUpdateAvailable)
        XCTAssertEqual(manager.latestVersion, "9999.0.0")
        XCTAssertEqual(manager.changelog, "Notes")
        XCTAssertNil(manager.updateError)
    }

    func testManualCheckReportsHTTPAndMalformedReleaseErrors() {
        let httpError = check(body: "{}", status: 403)
        XCTAssertNotNil(httpError.updateError)
        XCTAssertFalse(httpError.isUpToDate)

        let invalidVersion = check(body: #"{"tag_name":"invalid","body":null,"assets":[]}"#)
        XCTAssertNotNil(invalidVersion.updateError)
        XCTAssertFalse(invalidVersion.isUpToDate)

        let missingAsset = check(body: #"{"tag_name":"v9999.0.0","body":null,"assets":[]}"#)
        XCTAssertNotNil(missingAsset.updateError)
        XCTAssertFalse(missingAsset.isUpdateAvailable)

        let invalidURL = check(body: #"{"tag_name":"v9999.0.0","body":null,"assets":[{"name":"Netflix.dmg","browser_download_url":"http://example.com/Netflix.dmg"}]}"#)
        XCTAssertNotNil(invalidURL.updateError)
        XCTAssertFalse(invalidURL.isUpdateAvailable)
    }

    func testAutomaticFailureDoesNotShowManualAlert() {
        let manager = check(body: "{}", status: 500, manual: false)
        XCTAssertNil(manager.updateError)
        XCTAssertFalse(manager.isUpToDate)
    }

    func testInstallDoesNotDismissUpdateWhenSparkleIsNotReady() {
        let manager = UpdateManager(startingUpdater: false)
        manager.isUpdateAvailable = true
        manager.downloadAndInstall()
        XCTAssertTrue(manager.isUpdateAvailable)
        XCTAssertNotNil(manager.updateError)
    }
}
