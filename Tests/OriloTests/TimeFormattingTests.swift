import XCTest
@testable import Orilo

final class TimeFormattingTests: XCTestCase {
    func testClockFormatting() {
        XCTAssertEqual(TimeFormatting.clock(0), "00:00")
        XCTAssertEqual(TimeFormatting.clock(65), "01:05")
        XCTAssertEqual(TimeFormatting.clock(3600), "60:00")
        XCTAssertEqual(TimeFormatting.clock(-4), "00:00")
    }

    func testMinuteFormatting() {
        XCTAssertEqual(TimeFormatting.minutes(0), "0m")
        XCTAssertEqual(TimeFormatting.minutes(3599), "59m")
        XCTAssertEqual(TimeFormatting.minutes(-1), "0m")
    }
}
