import XCTest
@testable import DrinklyCore

final class HydrationGoalCalculatorTests: XCTestCase {
    private let metrics = BodyMetrics(gender: .male, heightCm: 170, weightKg: 120, ageYears: 34)

    func testDefaultFormulaIsWeightTimes35() {
        XCTAssertEqual(HydrationGoalCalculator.default.recommendedGoalMl(for: metrics), 4200)
    }

    func testFactorIsConfigurable() {
        let calculator = HydrationGoalCalculator(formula: WeightBasedGoalFormula(mlPerKg: 30))
        XCTAssertEqual(calculator.recommendedGoalMl(for: metrics), 3600)
    }

    func testRoundsToStep() {
        let m = BodyMetrics(gender: .female, heightCm: 160, weightKg: 61.3, ageYears: 30)
        // 61,3 × 35 = 2145,5 → 2150
        XCTAssertEqual(HydrationGoalCalculator.default.recommendedGoalMl(for: m), 2150)
    }

    func testClampsExtremeValues() {
        let tiny = BodyMetrics(gender: .female, heightCm: 100, weightKg: 10, ageYears: 30)
        let huge = BodyMetrics(gender: .male, heightCm: 210, weightKg: 400, ageYears: 30)
        XCTAssertEqual(HydrationGoalCalculator.default.recommendedGoalMl(for: tiny), 1000)
        XCTAssertEqual(HydrationGoalCalculator.default.recommendedGoalMl(for: huge), 6000)
    }

    func testCustomFormulaCanReplaceRule() {
        struct Fixed: HydrationGoalFormula {
            var identifier: String { "fixed" }
            func rawGoalMl(for metrics: BodyMetrics) -> Double { 3000 }
        }
        XCTAssertEqual(HydrationGoalCalculator(formula: Fixed()).recommendedGoalMl(for: metrics), 3000)
    }

    func testManualGoalOverridesAutomatic() {
        let profile = makeProfile(weight: 120, goalMode: .manual, manualGoal: 2750)
        XCTAssertEqual(HydrationGoalCalculator.default.effectiveGoalMl(for: profile), 2750)
        let auto = makeProfile(weight: 120, goalMode: .automatic, manualGoal: 2750)
        XCTAssertEqual(HydrationGoalCalculator.default.effectiveGoalMl(for: auto), 4200)
    }
}
