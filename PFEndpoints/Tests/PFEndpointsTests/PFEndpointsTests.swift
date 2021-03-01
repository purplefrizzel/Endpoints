import XCTest
@testable import PFEndpoints

final class PFEndpointsTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PFEndpoints().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
