import XCTest
import DrinklyCore
@testable import Drinkly

/// Testes do ViewModel principal (no simulador do Apple Watch).
/// As regras de negócio têm cobertura própria em Packages/DrinklyCore/Tests.
final class HydrationViewModelTests: XCTestCase {
    private func makeModel(profile: UserProfile? = UserProfile(gender: .female, heightCm: 165, weightKg: 60, ageYears: 30,
                                                                goalMode: .manual, manualGoalMl: 2500)) -> HydrationViewModel {
        HydrationViewModel(service: HydrationService(store: InMemoryHydrationStore(profile: profile)))
    }

    func testQuickAddUpdatesProgressImmediately() {
        let model = makeModel()
        model.add(volumeMl: 500)
        XCTAssertEqual(model.today.consumedMl, 500)
        XCTAssertEqual(model.today.percentage, 20)
        XCTAssertEqual(model.today.remainingMl, 2000)
        XCTAssertEqual(model.todayRecords.count, 1)
        XCTAssertNotNil(model.undoableRecord)
    }

    func testUndoRemovesLastRecord() {
        let model = makeModel()
        model.add(volumeMl: 300)
        model.undoLastAdd()
        XCTAssertEqual(model.today.consumedMl, 0)
        XCTAssertNil(model.undoableRecord)
    }

    func testEditAndDeleteRecalculate() throws {
        let model = makeModel()
        model.add(volumeMl: 500, type: .water)
        var record = try XCTUnwrap(model.todayRecords.first)
        record.volumeMl = 250
        record.type = .juice
        model.update(record)
        XCTAssertEqual(model.today.consumedMl, 250)
        XCTAssertEqual(model.todayRecords.first?.type, .juice)

        model.delete(try XCTUnwrap(model.todayRecords.first))
        XCTAssertEqual(model.today.consumedMl, 0)
        XCTAssertEqual(model.today.status, .empty)
    }

    func testOtherBeverageBecomesShortcut() throws {
        let model = makeModel()
        model.add(volumeMl: 300, type: .coconutWater, rememberShortcut: true)
        let coconut = DrinkShortcut(type: .coconutWater, volumeMl: 300)
        XCTAssertEqual(model.shortcuts.last, coconut)
        XCTAssertEqual(model.today.consumedMl, 300)

        // Usar o atalho registra de novo, sem duplicar o atalho.
        model.add(coconut)
        XCTAssertEqual(model.today.consumedMl, 600)
        XCTAssertEqual(model.shortcuts.filter { $0 == coconut }.count, 1)

        model.removeShortcut(coconut)
        XCTAssertFalse(model.shortcuts.contains(coconut))
    }

    func testQuickAddFromDashboardDoesNotCreateShortcut() {
        let model = makeModel()
        let before = model.shortcuts
        model.add(volumeMl: 330)
        XCTAssertEqual(model.shortcuts, before)
    }

    func testInvalidVolumeShowsError() {
        let model = makeModel()
        model.add(volumeMl: 0)
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.today.consumedMl, 0)
    }

    func testOnboardingCreatesProfile() {
        let model = makeModel(profile: nil)
        XCTAssertNil(model.profile)
        let onboarding = OnboardingViewModel()
        onboarding.weightKg = 120
        model.completeOnboarding(with: onboarding.makeProfile())
        XCTAssertNotNil(model.profile)
        XCTAssertEqual(model.currentGoalMl, 4200)
    }

    func testHistoryWeekHasSevenDays() {
        let model = makeModel()
        let history = HistoryViewModel(service: model.service, period: .week(offset: 0))
        history.load()
        XCTAssertEqual(history.summaries.count, 7)
        XCTAssertFalse(history.canGoForward)
        history.goBack()
        XCTAssertTrue(history.canGoForward)
    }
}
