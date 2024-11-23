@testable import FluentThemeDesigner
import XCTest

class ColorUtilsTests: XCTestCase {
	func testHexToSRGB() {
		// Test black color
		var result = hexToSRGB(hex: "000000")
		XCTAssertEqual(result.0, 0.0)
		XCTAssertEqual(result.1, 0.0)
		XCTAssertEqual(result.2, 0.0)

		// Test white color
		result = hexToSRGB(hex: "FFFFFF")
		XCTAssertEqual(result.0, 1.0)
		XCTAssertEqual(result.1, 1.0)
		XCTAssertEqual(result.2, 1.0)

		// Test red color
		result = hexToSRGB(hex: "FF0000")
		XCTAssertEqual(result.0, 1.0)
		XCTAssertEqual(result.1, 0.0)
		XCTAssertEqual(result.2, 0.0)

		// Test green color
		result = hexToSRGB(hex: "00FF00")
		XCTAssertEqual(result.0, 0.0)
		XCTAssertEqual(result.1, 1.0)
		XCTAssertEqual(result.2, 0.0)

		// Test blue color
		result = hexToSRGB(hex: "0000FF")
		XCTAssertEqual(result.0, 0.0)
		XCTAssertEqual(result.1, 0.0)
		XCTAssertEqual(result.2, 1.0)

		// Test invalid hex
		result = hexToSRGB(hex: "ZZZZZZ")
		XCTAssertEqual(result.0, 0.0)
		XCTAssertEqual(result.1, 0.0)
		XCTAssertEqual(result.2, 0.0)
	}

	func testLinSRGB() {
		// Test linearization of black color
		var result = linSRGB((0.0, 0.0, 0.0))
		XCTAssertEqual(result.0, 0.0)
		XCTAssertEqual(result.1, 0.0)
		XCTAssertEqual(result.2, 0.0)

		// Test linearization of white color
		result = linSRGB((1.0, 1.0, 1.0))
		XCTAssertEqual(result.0, 1.0)
		XCTAssertEqual(result.1, 1.0)
		XCTAssertEqual(result.2, 1.0)

		// Test linearization of mid-gray color
		result = linSRGB((0.5, 0.5, 0.5))
		XCTAssertEqual(result.0, 0.21404114, accuracy: 0.00001)
		XCTAssertEqual(result.1, 0.21404114, accuracy: 0.00001)
		XCTAssertEqual(result.2, 0.21404114, accuracy: 0.00001)
	}

	func testMultiplyMatrices() {
		// Test multiplying two 2x2 matrices
		let A: [[Double]] = [
			[1, 2],
			[3, 4],
		]
		let B: [[Double]] = [
			[5, 6],
			[7, 8],
		]
		let result = multiplyMatrices(A, B)
		XCTAssertEqual(result, [
			[19, 22],
			[43, 50],
		])

		// Test multiplying a 2x3 matrix with a 3x2 matrix
		let C: [[Double]] = [
			[1, 2, 3],
			[4, 5, 6],
		]
		let D: [[Double]] = [
			[7, 8],
			[9, 10],
			[11, 12],
		]
		let result2 = multiplyMatrices(C, D)
		XCTAssertEqual(result2, [
			[58, 64],
			[139, 154],
		])
	}

	func testLinSRGBToXYZ() {
		// Test conversion of linear sRGB black color to XYZ
		var result = linSRGBToXYZ((0.0, 0.0, 0.0))
		XCTAssertEqual(result.0, 0.0)
		XCTAssertEqual(result.1, 0.0)
		XCTAssertEqual(result.2, 0.0)

		// Test conversion of linear sRGB white color to XYZ
		result = linSRGBToXYZ((1.0, 1.0, 1.0))
		XCTAssertEqual(result.0, 0.95045, accuracy: 0.00001)
		XCTAssertEqual(result.1, 1.00000, accuracy: 0.00001)
		XCTAssertEqual(result.2, 1.08905, accuracy: 0.00001)

		// Test conversion of linear sRGB red color to XYZ
		result = linSRGBToXYZ((1.0, 0.0, 0.0))
		XCTAssertEqual(result.0, 0.41239, accuracy: 0.00001)
		XCTAssertEqual(result.1, 0.21264, accuracy: 0.00001)
		XCTAssertEqual(result.2, 0.01933, accuracy: 0.00001)
	}

	func testXYZToLab() {
		// Test conversion of XYZ black color to Lab
		var result = XYZToLab((0.0, 0.0, 0.0))
		XCTAssertEqual(result.0, 0.0, accuracy: 0.0001)
		XCTAssertEqual(result.1, 0.0, accuracy: 0.0001)
		XCTAssertEqual(result.2, 0.0, accuracy: 0.0001)

		// Test conversion of XYZ white color to Lab
		result = XYZToLab((0.96422, 1.0, 0.82521))
		XCTAssertEqual(result.0, 100.0, accuracy: 0.0001)
		XCTAssertEqual(result.1, 0.0, accuracy: 0.0001)
		XCTAssertEqual(result.2, 0.0, accuracy: 0.0001)

		result = XYZToLab((1.0, 1.0, 1.0))
		XCTAssertEqual(result.0, 100.0, accuracy: 0.00001)
		XCTAssertEqual(result.1, 6.109659052457195, accuracy: 0.00001)
		XCTAssertEqual(result.2, -13.226822414335526, accuracy: 0.00001)
	}

	func testLabToXYZ() {
		// Test conversion of Lab black color to XYZ
		var result = LabToXYZ((0.0, 0.0, 0.0))
		XCTAssertEqual(result.0, 0.0, accuracy: 0.0001)
		XCTAssertEqual(result.1, 0.0, accuracy: 0.0001)
		XCTAssertEqual(result.2, 0.0, accuracy: 0.0001)

		// Test conversion of Lab white color to XYZ
		result = LabToXYZ((100.0, 0.0, 0.0))
		XCTAssertEqual(result.0, 0.96422, accuracy: 0.0001)
		XCTAssertEqual(result.1, 1.0, accuracy: 0.0001)
		XCTAssertEqual(result.2, 0.82521, accuracy: 0.0001)
	}

	func testLabToLCH() {
		// Test conversion of Lab to LCH
		let result = LabToLCH((50.0, 25.0, -25.0))
		XCTAssertEqual(result.0, 50.0)
		XCTAssertEqual(result.1, 35.3553, accuracy: 0.0001)
		XCTAssertEqual(result.2, 315.0, accuracy: 0.0001)
	}

	func testLCHToLab() {
		// Test conversion of LCH to Lab
		let result = LCHToLab((50.0, 35.3553, 315.0))
		XCTAssertEqual(result.0, 50.0)
		XCTAssertEqual(result.1, 25.0, accuracy: 0.0001)
		XCTAssertEqual(result.2, -25.0, accuracy: 0.0001)
	}

	func testSRGBToLCH() {
		// Test black color
		var result = sRGBToLCH((0.0, 0.0, 0.0))
		XCTAssertEqual(result.0, 0.0, accuracy: 0.0001) // L
		XCTAssertEqual(result.1, 0.0, accuracy: 0.0001) // C
		XCTAssertTrue(result.2.isNaN || result.2 == 0.0) // H is undefined when C is zero

		// Test white color
		result = sRGBToLCH((1.0, 1.0, 1.0))
		XCTAssertEqual(result.0, 100.00000139649632, accuracy: 0.00001) // L
		XCTAssertEqual(result.1, 0.015605019433726806, accuracy: 0.00001) // C
		XCTAssertEqual(result.2, 33.09999269502754, accuracy: 0.00001) // H
	}

	func testGetBrandTokensFromPalette() {
		let brandTokens = getBrandTokensFromPalette(
			keyColor: "#0F6CBD",
			options: .init(
				darkCp: 0,
				lightCp: 0,
				hueTorsion: 0
			)
		)
		let expected: [String: String] = [
			"10": "#020305",
			"20": "#111723",
			"30": "#16263D",
			"40": "#193253",
			"50": "#1B3F6A",
			"60": "#1B4C82",
			"70": "#18599A",
			"80": "#1267B4",
			"90": "#3074C1",
			"100": "#4F81C8",
			"110": "#678FCE",
			"120": "#7D9DD5",
			"130": "#91ABDB",
			"140": "#A5BAE2",
			"150": "#B9C8E8",
			"160": "#CDD7EE",
		]
		XCTAssertEqual(brandTokens, expected)
	}
}
