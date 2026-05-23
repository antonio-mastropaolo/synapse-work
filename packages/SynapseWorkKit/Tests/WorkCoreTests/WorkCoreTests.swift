import XCTest
@testable import WorkCore

final class WorkErrorTests: XCTestCase {
    func testEqualityHonorsAssociatedValues() {
        XCTAssertEqual(WorkError.unauthenticated, .unauthenticated)
        XCTAssertNotEqual(WorkError.server(status: 500, message: nil), .server(status: 502, message: nil))
    }

    func testSpotlightEventDecodesISO8601() throws {
        let json = #"""
        {
          "id": "spot-x",
          "title": "T",
          "abstract": "A",
          "venue": null,
          "detectedAt": "2026-05-23T12:00:00Z",
          "kind": "pick",
          "status": "pending"
        }
        """#.data(using: .utf8)!
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        let event = try d.decode(SpotlightEvent.self, from: json)
        XCTAssertEqual(event.id, "spot-x")
        XCTAssertEqual(event.kind, .pick)
    }
}
