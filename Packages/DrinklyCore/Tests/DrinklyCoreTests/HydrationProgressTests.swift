import XCTest
@testable import DrinklyCore

final class HydrationProgressTests: XCTestCase {
    func testHalfway() {
        let p = HydrationProgress(consumedMl: 1250, goalMl: 2500)
        XCTAssertEqual(p.percentage, 50)
        XCTAssertEqual(p.remainingMl, 1250)
        XCTAssertFalse(p.goalReached)
        XCTAssertEqual(p.status, .inProgress)
    }

    func testRoundsPercentage() {
        let p = HydrationProgress(consumedMl: 1750, goalMl: 3000)
        XCTAssertEqual(p.percentage, 58)
        XCTAssertEqual(p.remainingMl, 1250)
    }

    func testGoalReached() {
        let p = HydrationProgress(consumedMl: 2500, goalMl: 2500)
        XCTAssertEqual(p.percentage, 100)
        XCTAssertEqual(p.remainingMl, 0)
        XCTAssertTrue(p.goalReached)
        XCTAssertEqual(p.status, .reached)
    }

    func testGoalExceededIsNotCapped() {
        let p = HydrationProgress(consumedMl: 3000, goalMl: 2500)
        XCTAssertEqual(p.percentage, 120)
        XCTAssertEqual(p.remainingMl, 0)
        XCTAssertEqual(p.excessMl, 500)
        XCTAssertEqual(p.status, .exceeded)
        XCTAssertEqual(p.clampedFraction, 1)
        XCTAssertEqual(p.fraction, 1.2, accuracy: 0.0001)

        XCTAssertEqual(HydrationProgress(consumedMl: 3200, goalMl: 3000).percentage, 107)
    }

    func testNeverShows100BeforeReachingGoal() {
        XCTAssertEqual(HydrationProgress(consumedMl: 2490, goalMl: 2500).percentage, 99)
    }

    func testEmptyDay() {
        let p = HydrationProgress(consumedMl: 0, goalMl: 2500)
        XCTAssertEqual(p.percentage, 0)
        XCTAssertEqual(p.remainingMl, 2500)
        XCTAssertEqual(p.status, .empty)
    }

    func testZeroGoalDoesNotCrash() {
        XCTAssertEqual(HydrationProgress(consumedMl: 0, goalMl: 0).fraction, 0)
        XCTAssertEqual(HydrationProgress(consumedMl: 100, goalMl: 0).percentage, 100)
    }

    func testVolumeFormatting() {
        XCTAssertEqual(VolumeFormatter.string(ml: 1250), "1.250 ml")
        XCTAssertEqual(VolumeFormatter.progress(consumedMl: 1250, goalMl: 2500), "1.250 / 2.500 ml")
        XCTAssertEqual(VolumeFormatter.liters(ml: 2500), "2,5 L")
        XCTAssertEqual(VolumeFormatter.spoken(ml: 500), "500 mililitros")
    }
}
