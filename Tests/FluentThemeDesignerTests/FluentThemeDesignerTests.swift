@testable import FluentThemeDesigner
import SwiftUI
import XCTest

final class FluentThemeDesignerTests: XCTestCase {
	var options: Options!

	override func setUp() async throws {
		// Initial setup before each test
		options = Options() // Assuming Options has a default initializer
	}

	override func tearDown() async throws {
		// Cleanup after each test
		options = nil
	}

	func testInitializer_withValidHexKeyColorAndOptions() async throws {
		// Arrange
		let hexKeyColor = "#FF5733"

		// Act
		let themeDesigner = FluentThemeDesigner(hexKeyColor: hexKeyColor, options: options)

		// Assert
		XCTAssertEqual(themeDesigner.options, options)
		XCTAssertNotNil(themeDesigner.palette)
	}

	func testInitializer_generatesCorrectPalette() async throws {
		// Arrange
		let hexKeyColor = "#FF5733"
		let expectedPalette = getBrandTokensFromPalette(keyColor: hexKeyColor, options: options)

		// Act
		let themeDesigner = FluentThemeDesigner(hexKeyColor: hexKeyColor, options: options)

		// Assert
		XCTAssertEqual(themeDesigner.palette, expectedPalette)
	}

	func testSubscript_returnsCorrectColor() async throws {
		// Arrange
		let expected: [PaletteTokenKey: String] = [
			.t10: "#020305",
			.t20: "#111723",
			.t30: "#16263D",
			.t40: "#193253",
			.t50: "#1B3F6A",
			.t60: "#1B4C82",
			.t70: "#18599A",
			.t80: "#1267B4",
			.t90: "#3074C1",
			.t100: "#4F81C8",
			.t110: "#678FCE",
			.t120: "#7D9DD5",
			.t130: "#91ABDB",
			.t140: "#A5BAE2",
			.t150: "#B9C8E8",
			.t160: "#CDD7EE",
		]
		let themeDesigner = FluentThemeDesigner(hexKeyColor: "#0F6CBD", options: .init(
			darkCp: 0,
			lightCp: 0,
			hueTorsion: 0
		))
		let key = PaletteTokenKey.t10

		// Act
		let color = themeDesigner[key]

		// Assert
		XCTAssertNotNil(color)
		XCTAssertEqual(color, Color(hex: expected[key]!))
	}
}
