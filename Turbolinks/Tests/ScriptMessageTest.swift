import XCTest
import WebKit
@testable import Turbolinks

class ScriptMessageTest: XCTestCase {
    func testParseWithInvalidBody() {
        let script = FakeScriptMessage(body: "foo")
        
        let message = ScriptMessage.parse(script)
        XCTAssertNil(message)
    }
    
    func test_ParseWithInvalidName() {
        let script = FakeScriptMessage(body: ["name": "foobar"])
        
        let message = ScriptMessage.parse(script)
        XCTAssertNil(message)
    }
    
    func test_ParseWithMissingData() {
        let script = FakeScriptMessage(body: ["name": "pageLoaded"])
        
        let message = ScriptMessage.parse(script)
        XCTAssertNil(message)
    }
    
    func test_ParseWithValidBody() {
        let data = ["identifier": "123", "restorationIdentifier": "abc", "action": "advance", "location": "http://turbolinks.test"]
        let script = FakeScriptMessage(body: ["name": "pageLoaded", "data": data])
        
        let message = ScriptMessage.parse(script)
        XCTAssertNotNil(message)
        XCTAssertEqual(message?.name, ScriptMessageName.PageLoaded)
        XCTAssertEqual(message?.identifier, "123")
        XCTAssertEqual(message?.restorationIdentifier, "abc")
        XCTAssertEqual(message?.action, Action.Advance)
        XCTAssertEqual(message?.location, URL(string: "http://turbolinks.test")!)
    }
}

// Can't instantiate a WKScriptMessage directly
private class FakeScriptMessage: WKScriptMessage {
    override var body: Any {
        return actualBody
    }
    
    var actualBody: Any
    
    init(body: Any) {
        self.actualBody = body
    }
}
