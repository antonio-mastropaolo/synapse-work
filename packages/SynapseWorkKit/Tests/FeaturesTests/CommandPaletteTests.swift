import XCTest
@testable import Features

final class CommandPaletteTests: XCTestCase {

    func test_emptyQuery_returnsAllSurfacesInOriginalOrder() {
        let result = CommandPaletteMatcher.matches(query: "", surfaces: WorkSurface.allCases)
        XCTAssertEqual(result.count, WorkSurface.allCases.count)
        XCTAssertEqual(result.first, WorkSurface.allCases.first)
    }

    func test_whitespaceQuery_treatedAsEmpty() {
        let result = CommandPaletteMatcher.matches(query: "   \n", surfaces: WorkSurface.allCases)
        XCTAssertEqual(result.count, WorkSurface.allCases.count)
    }

    func test_prefixMatch_outranksContains() {
        // "ap" prefixes "Applicants" and "Approvals"; "Spotlight" only
        // contains the substring through "...ap..." (via "spotlight"
        // doesn't even contain "ap", so use a clearer pair).
        // "in" prefixes "Inbox" and contains in "Spotlight" (no), so
        // pick "rev" → prefix "Reviews", subsequence-only "Receipts".
        let result = CommandPaletteMatcher.matches(
            query: "rev",
            surfaces: [.receipts, .reviews]
        )
        XCTAssertEqual(result.first, .reviews, "Prefix match must win over subsequence match")
    }

    func test_fuzzySubsequence_findsSurface() {
        // "stl" should fuzzy-match "Spotlight" via subsequence.
        let result = CommandPaletteMatcher.matches(
            query: "stl",
            surfaces: WorkSurface.allCases
        )
        XCTAssertTrue(result.contains(.spotlight), "Subsequence match should find Spotlight via 'stl'")
    }

    func test_noMatch_returnsEmpty() {
        let result = CommandPaletteMatcher.matches(
            query: "zzzqqq",
            surfaces: WorkSurface.allCases
        )
        XCTAssertTrue(result.isEmpty)
    }

    func test_caseInsensitive() {
        let lower = CommandPaletteMatcher.matches(query: "dashboard", surfaces: WorkSurface.allCases)
        let upper = CommandPaletteMatcher.matches(query: "DASHBOARD", surfaces: WorkSurface.allCases)
        let mixed = CommandPaletteMatcher.matches(query: "DaShBoArD", surfaces: WorkSurface.allCases)
        XCTAssertEqual(lower, upper)
        XCTAssertEqual(lower, mixed)
        XCTAssertEqual(lower.first, .dashboard)
    }

    func test_groupNameMatch_findsSurfacesByGroup() {
        // "EDITORIAL" is the group label for Reviews/Automation/Spotlight.
        let result = CommandPaletteMatcher.matches(
            query: "editorial",
            surfaces: WorkSurface.allCases
        )
        XCTAssertTrue(result.contains(.reviews))
        XCTAssertTrue(result.contains(.spotlight))
        XCTAssertTrue(result.contains(.automation))
    }

    func test_rawValueMatch_findsSurfaceByEnumName() {
        // rawValue is "ask" — label is "Ask AI". "ask" should match.
        let result = CommandPaletteMatcher.matches(query: "ask", surfaces: WorkSurface.allCases)
        XCTAssertEqual(result.first, .ask)
    }

    func test_exactLabelMatch_isTopResult() {
        let result = CommandPaletteMatcher.matches(query: "Inbox", surfaces: WorkSurface.allCases)
        XCTAssertEqual(result.first, .inbox)
    }

    func test_subsequenceHelper_basic() {
        XCTAssertTrue(CommandPaletteMatcher.isSubsequence(needle: "abc", in: "axbycz"))
        XCTAssertFalse(CommandPaletteMatcher.isSubsequence(needle: "acb", in: "axbycz"))
        XCTAssertTrue(CommandPaletteMatcher.isSubsequence(needle: "", in: "hello"))
        XCTAssertFalse(CommandPaletteMatcher.isSubsequence(needle: "z", in: "hello"))
    }
}
