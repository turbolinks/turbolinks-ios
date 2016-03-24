import XCTest

class TurbolinksDemoUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        app.launch()
    }

    func test_HTTPError() {
        app.links["Trigger an HTTP 404"].tap()
        XCTAssert(app.staticTexts["Page Not Found"].exists)
        XCTAssert(app.buttons["Retry"].exists)
    }

    func test_LoggingIn() {
        let protectedLink = app.links["Visit a protected area"]
        protectedLink.tap()
        XCTAssert(app.navigationBars["Sign in"].exists)

        app.buttons["Sign in"].tap()
        XCTAssert(app.navigationBars["Protected"].exists)

        app.buttons["Demo"].tap()
        protectedLink.tap()
        XCTAssert(app.navigationBars["Protected"].exists)
    }

    func test_NativeViewController() {
        app.links["Load a native view controller"].tap()
        XCTAssert(app.navigationBars["Numbers"].exists)
        XCTAssert(app.staticTexts["Row 1"].exists)
        XCTAssertEqual(app.cells.count, 100)
    }

    func test_JavaScriptMessage() {
        app.links["Post a message from JavaScript"].tap()
        XCTAssert(app.alerts.element.staticTexts["Hello from JavaScript!"].exists)
    }
}
