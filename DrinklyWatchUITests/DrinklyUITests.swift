import XCTest

/// Testes de UI. O app é iniciado com `-ui-testing`, que usa armazenamento em
/// memória e desliga notificações, Health e complicações.
///
/// Rode este esquema em simuladores de tamanhos diferentes (ex.: Series 3 –
/// 38 mm/42 mm, Series 9 – 41 mm/45 mm, Ultra – 49 mm) para validar o layout.
final class DrinklyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(onboarded: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"] + (onboarded ? ["-onboarded"] : [])
        app.launch()
        return app
    }

    func testFirstLaunchShowsOnboardingAndCompletes() {
        let app = launch(onboarded: false)
        let female = app.buttons["gender-female"]
        XCTAssertTrue(female.waitForExistence(timeout: 5))
        female.tap()

        for _ in 0..<3 {
            let next = app.buttons["nextStep"]
            XCTAssertTrue(next.waitForExistence(timeout: 2))
            next.tap()
        }
        XCTAssertTrue(app.staticTexts["recommendedGoal"].waitForExistence(timeout: 2))
        app.buttons["finishOnboarding"].tap()

        XCTAssertTrue(app.staticTexts["statusMessage"].waitForExistence(timeout: 5))
    }

    func testEmptyStateMessage() {
        let app = launch(onboarded: true)
        let message = app.staticTexts["statusMessage"]
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        XCTAssertEqual(message.label, "Comece registrando sua primeira bebida.")
    }

    func testQuickAddIsOneTap() {
        let app = launch(onboarded: true)
        let add500 = app.buttons["quickAdd-500"]
        XCTAssertTrue(add500.waitForExistence(timeout: 5))
        XCTAssertEqual(add500.label, "Adicionar 500 mililitros de água")
        add500.tap()

        let percentage = app.staticTexts["percentage"]
        let predicate = NSPredicate(format: "label == %@", "20%")
        expectation(for: predicate, evaluatedWith: percentage)
        waitForExpectations(timeout: 3)
        XCTAssertTrue(app.buttons["undo"].exists)
    }

    func testGoalReachedAndExceeded() {
        let app = launch(onboarded: true)
        let add500 = app.buttons["quickAdd-500"]
        XCTAssertTrue(add500.waitForExistence(timeout: 5))
        for _ in 0..<5 { add500.tap() }
        let message = app.staticTexts["statusMessage"]
        expectation(for: NSPredicate(format: "label == %@", "Meta atingida! 💧"), evaluatedWith: message)
        waitForExpectations(timeout: 3)

        add500.tap()
        expectation(for: NSPredicate(format: "label BEGINSWITH %@", "Meta ultrapassada"), evaluatedWith: message)
        waitForExpectations(timeout: 3)
        XCTAssertEqual(app.staticTexts["percentage"].label, "120%")
    }

    func testAddOtherBeverageWithCustomVolume() {
        let app = launch(onboarded: true)
        let other = app.buttons["otherDrinks"]
        XCTAssertTrue(other.waitForExistence(timeout: 5))
        other.tap()

        let juice = app.buttons["beverage-juice"]
        XCTAssertTrue(juice.waitForExistence(timeout: 3))
        juice.tap()
        let volume = app.buttons["volume-300"]
        XCTAssertTrue(volume.waitForExistence(timeout: 3))
        volume.tap()

        expectation(for: NSPredicate(format: "label == %@", "12%"), evaluatedWith: app.staticTexts["percentage"])
        waitForExpectations(timeout: 3)

        // A bebida vira um atalho na tela inicial, que registra com um toque.
        let shortcut = app.buttons["quickAdd-juice-300"]
        XCTAssertTrue(shortcut.waitForExistence(timeout: 3))
        shortcut.tap()
        expectation(for: NSPredicate(format: "label == %@", "24%"), evaluatedWith: app.staticTexts["percentage"])
        waitForExpectations(timeout: 3)
    }
}
