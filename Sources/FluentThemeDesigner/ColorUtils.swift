import Foundation

func hexToSRGB(hex: String) -> Vec3 {
	var hex = hex
	while hex.hasPrefix("#") {
		hex.removeFirst()
	}
	let scanner = Scanner(string: hex)
	var hexNumber: UInt64 = 0
	if scanner.scanHexInt64(&hexNumber) {
		let r = Double((hexNumber & 0xff0000) >> 16) / 255.0
		let g = Double((hexNumber & 0x00ff00) >> 8) / 255.0
		let b = Double(hexNumber & 0x0000ff) / 255.0
		return (r, g, b)
	}
	return (0, 0, 0)
}

func linSRGB(_ RGB: Vec3) -> Vec3 {
	let map = { (val: Double) in
		let sign: Double = val < 0 ? -1 : 1
		let absVal: Double = abs(val)

		if absVal < 0.04045 {
			return val / 12.92
		}

		return sign * pow((absVal + 0.055) / 1.055, 2.4)
	}

	return (map(RGB.0), map(RGB.1), map(RGB.2))
}

func multiplyMatrices(_ A: [[Double]], _ B: [[Double]]) -> [[Double]] {
	let m = A.count
	let n = A[0].count
	let p = B[0].count

	var product: [[Double]] = Array(
		repeating: Array(repeating: 0.0, count: p), count: m
	)

	for i in 0 ..< m {
		for j in 0 ..< p {
			for k in 0 ..< n {
				product[i][j] += A[i][k] * B[k][j]
			}
		}
	}

	return product
}

func linSRGBToXYZ(_ rgb: Vec3) -> Vec3 {
	let M: [[Double]] = [
		[0.41239079926595934, 0.357584339383878, 0.1804807884018343],
		[0.21263900587151027, 0.715168678767756, 0.07219231536073371],
		[0.01933081871559182, 0.11919477979462598, 0.9505321522496607],
	]
	let rgbMatrix: [[Double]] = [[rgb.0], [rgb.1], [rgb.2]]
	let result = multiplyMatrices(M, rgbMatrix)
	return (result[0][0], result[1][0], result[2][0])
}

func D65ToD50(_ XYZ: Vec3) -> Vec3 {
	// Bradford chromatic adaptation from D65 to D50
	// The matrix below is the result of three operations:
	// - convert from XYZ to retinal cone domain
	// - scale components from one reference white to another
	// - convert back to XYZ
	let M: [[Double]] = [
		[1.0479298208405488, 0.022946793341019088, -0.05019222954313557],
		[0.029627815688159344, 0.990434484573249, -0.01707382502938514],
		[-0.009243058152591178, 0.015055144896577895, 0.7518742899580008],
	]
	let XYZMatrix: [[Double]] = [[XYZ.0], [XYZ.1], [XYZ.2]]
	let result = multiplyMatrices(M, XYZMatrix)
	return (result[0][0], result[1][0], result[2][0])
}

func D50ToD65(_ XYZ: Vec3) -> Vec3 {
	// Bradford chromatic adaptation from D50 to D65
	let M: [[Double]] = [
		[0.9554734527042182, -0.023098536874261423, 0.0632593086610217],
		[-0.028369706963208136, 1.0099954580058226, 0.021041398966943008],
		[0.012314001688319899, -0.020507696433477912, 1.3303659366080753],
	]
	let XYZMatrix: [[Double]] = [[XYZ.0], [XYZ.1], [XYZ.2]]
	let result = multiplyMatrices(M, XYZMatrix)
	return (result[0][0], result[1][0], result[2][0])
}

func XYZToLab(_ XYZ: Vec3) -> Vec3 {
	// Assuming XYZ is relative to D50, convert to CIE Lab
	let ε: Double = 216 / 24389 // 6^3/29^3
	let κ: Double = 24389 / 27 // 29^3/3^3
	let white: [Double] = [0.96422, 1.0, 0.82521] // D50 reference white

	// Compute xyz, which is XYZ scaled relative to reference white
	let xyz = [XYZ.0 / white[0], XYZ.1 / white[1], XYZ.2 / white[2]]

	// Compute f
	let f = xyz.map { value -> Double in
		value > ε ? cbrt(value) : (κ * value + 16) / 116
	}

	let L = 116 * f[1] - 16
	let a = 500 * (f[0] - f[1])
	let b = 200 * (f[1] - f[2])

	return (L, a, b)
}

func LabToXYZ(_ Lab: Vec3) -> Vec3 {
	// Convert Lab to D50-adapted XYZ
	let κ: Double = 24389 / 27 // 29^3/3^3
	let ε: Double = 216 / 24389 // 6^3/29^3
	let white: [Double] = [0.96422, 1.0, 0.82521] // D50 reference white
	var f = [Double](repeating: 0.0, count: 3)

	// Compute f, starting with the luminance-related term
	f[1] = (Lab.0 + 16) / 116
	f[0] = Lab.1 / 500 + f[1]
	f[2] = f[1] - Lab.2 / 200

	// Compute xyz
	let xCubed = pow(f[0], 3)
	let x = xCubed > ε ? xCubed : (116 * f[0] - 16) / κ

	let yCubed = pow(f[1], 3)
	let y = Lab.0 > κ * ε ? yCubed : Lab.0 / κ

	let zCubed = pow(f[2], 3)
	let z = zCubed > ε ? zCubed : (116 * f[2] - 16) / κ

	// Compute XYZ by scaling xyz by reference white
	let X = x * white[0]
	let Y = y * white[1]
	let Z = z * white[2]

	return (X, Y, Z)
}

func LabToLCH(_ Lab: Vec3) -> Vec3 {
	// Convert to polar form
	let L = Lab.0
	let a = Lab.1
	let b = Lab.2
	let C = sqrt(a * a + b * b)
	var h = atan2(b, a) * 180 / .pi
	if h < 0 { h += 360 }
	return (L, C, h)
}

func LCHToLab(_ LCH: Vec3) -> Vec3 {
	// Convert from polar form
	let L = LCH.0
	let C = LCH.1
	let hRad = LCH.2 * .pi / 180
	let a = C * cos(hRad)
	let b = C * sin(hRad)
	return (L, a, b)
}

func sRGBToLCH(_ RGB: Vec3) -> Vec3 {
	// Convert gamma-corrected sRGB values to LCH
	let linearRGB = linSRGB(RGB)
	let XYZ = linSRGBToXYZ(linearRGB)
	let adaptedXYZ = D65ToD50(XYZ)
	let Lab = XYZToLab(adaptedXYZ)
	let LCH = LabToLCH(Lab)
	return LCH
}

func hexToLCH(hex: String) -> Vec3 {
	let _1 = hexToSRGB(hex: hex)
	let _2 = sRGBToLCH(_1)
	return _2
	// return sRGBToLCH(hexToSRGB(hex: hex))
}

func equals(_ v1: Vec3, _ v2: Vec3) -> Bool {
	v1.0 == v2.0 && v1.1 == v2.1 && v1.2 == v2.2
}

func QuadraticBezierP0(_ t: Double, _ p: Double) -> Double {
	let k = 1 - t
	return k * k * p
}

func QuadraticBezierP1(_ t: Double, _ p: Double) -> Double {
	2 * (1 - t) * t * p
}

func QuadraticBezierP2(_ t: Double, _ p: Double) -> Double {
	t * t * p
}

func QuadraticBezier(_ t: Double, _ p0: Double, _ p1: Double, _ p2: Double) -> Double {
	QuadraticBezierP0(t, p0)
		+ QuadraticBezierP1(t, p1)
		+ QuadraticBezierP2(t, p2)
}

func getPointOnCurve(_ curve: Curve, _ t: Double) -> Vec3 {
	// let (v0, v1, v2) = curve.points
	let v0 = curve.points[0]
	let v1 = curve.points[1]
	let v2 = curve.points[2]
	return (
		QuadraticBezier(t, v0.0, v1.0, v2.0),
		QuadraticBezier(t, v0.1, v1.1, v2.1),
		QuadraticBezier(t, v0.2, v1.2, v2.2)
	)
}

func getPointsOnCurve(_ curve: Curve, _ divisions: Int) -> [Vec3] {
	var points: [Vec3] = []
	for d in 0 ... divisions {
		points.append(getPointOnCurve(curve, Double(d) / Double(divisions)))
	}
	return points
}

func getPointsOnCurvePath(_ curvePath: CurvePath, _ divisions: Int = curveResolution) -> [Vec3] {
	var points: [Vec3] = []
	var last: Vec3?

	for curve in curvePath.curves {
		let pts = getPointsOnCurve(curve, divisions)
		for point in pts {
			if let last = last, equals(last, point) {
				continue
			}
			points.append(point)
			last = point
		}
	}

	return points
}

func curvePathFromPalette(palette: Palette) -> CurvedHelixPath {
	let keyColor: Vec3 = palette.keyColor
	let darkCp: Double = palette.darkCp
	let lightCp: Double = palette.lightCp
	let hueTorsion: Double = palette.hueTorsion
	let blackPosition: Vec3 = (0, 0, 0)
	let whitePosition: Vec3 = (100, 0, 0)
	let keyColorPosition = LCHToLab(keyColor)
	let (l, a, b) = keyColorPosition

	let darkControlPosition: Vec3 = (l * (1 - darkCp), a, b)
	let lightControlPosition: Vec3 = (l + (100 - l) * lightCp, a, b)

	return CurvedHelixPath(
		curves: [
			Curve(points: [
				blackPosition, darkControlPosition, keyColorPosition,
			]),
			Curve(points: [
				keyColorPosition, lightControlPosition, whitePosition,
			]),
		],
		torsion: hueTorsion,
		torsionT0: l
	)
}

func hexToHue(hexColor: String) -> Int {
	// Parse the hex color string into its red, green, and blue components
	let red = Int(hexColor.prefix(3).suffix(2), radix: 16) ?? 0
	let green = Int(hexColor.prefix(5).suffix(2), radix: 16) ?? 0
	let blue = Int(hexColor.suffix(2), radix: 16) ?? 0

	// Convert the RGB color to HSL color space
	let r = Double(red) / 255.0
	let g = Double(green) / 255.0
	let b = Double(blue) / 255.0
	let cmax = max(r, g, b)
	let cmin = min(r, g, b)
	let delta = cmax - cmin
	var hue: Double

	// Calculate the hue value based on the RGB color values
	if delta == 0 {
		hue = 0
	} else if cmax == r {
		hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
	} else if cmax == g {
		hue = (b - r) / delta + 2
	} else {
		hue = (r - g) / delta + 4
	}

	// Convert the hue value to degrees and return it
	hue = round(hue * 60)
	if hue < 0 {
		hue += 360
	}
	return Int(hue)
}

func snappingPointsForKeyColor(keyColor: String) -> [Double] {
	let hue = hexToHue(hexColor: keyColor)
	let range = [
		hueToSnappingPointsMap[hue][0] * 100,
		hueToSnappingPointsMap[hue][1] * 100,
		hueToSnappingPointsMap[hue][2] * 100,
	]
	return range
}

func pointsForKeyColor(keyColor: String, range: [Double], centerPoint: Double) -> [Double] {
	let hue = hexToHue(hexColor: keyColor)
	let center = hueToSnappingPointsMap[hue][1] * 100
	let linear = linearInterpolationThroughPoint(
		start: range[0], end: range[1], inBetween: center, numSamples: 16
	)
	return linear
}

func linearInterpolationThroughPoint(start: Double, end: Double, inBetween: Double, numSamples: Int) -> [Double] {
	guard numSamples >= 3 else {
		fatalError("Number of samples must be at least 3.")
	}

	let inBetweenRatio = (inBetween - start) / (end - start)
	let inBetweenIndex = Int(
		(Double(numSamples - 1) * inBetweenRatio).rounded(.down)
	)

	var result = [Double](repeating: 0.0, count: numSamples)
	result[0] = start
	result[inBetweenIndex] = inBetween
	result[numSamples - 1] = end

	let stepBefore = (inBetween - start) / Double(inBetweenIndex)
	let stepAfter = (end - inBetween) / Double(numSamples - 1 - inBetweenIndex)

	for i in 1 ..< inBetweenIndex {
		result[i] = start + Double(i) * stepBefore
	}

	for i in (inBetweenIndex + 1) ..< numSamples - 1 {
		result[i] = inBetween + Double(i - inBetweenIndex) * stepAfter
	}

	return result
}

func getPointOnHelix(pointOnCurve: Vec3, torsion: Double = 0, torsionT0: Double = 50) -> Vec3 {
	let t = pointOnCurve.0
	let (l, c, h) = LabToLCH(pointOnCurve)
	let hueOffset = torsion * (t - torsionT0)
	return LCHToLab((l, c, h + hueOffset))
}

func getLogSpace(min: Double, max: Double, n: Int) -> [Double] {
	let a = min <= 0 ? 0 : log(min)
	let b = log(max)
	let delta = (b - a) / Double(n)

	var result = [pow(M_E, a)]
	for i in 1 ..< n {
		result.append(pow(M_E, a + delta * Double(i)))
	}
	result.append(pow(M_E, b))
	return result
}

func paletteShadesFromCurvePoints(
	curvePoints: [Vec3],
	nShades: Int,
	linearity: Double = defaultLinearity,
	keyColor: String
) -> [Vec3] {
	guard curvePoints.count > 2 else {
		return []
	}

	let snappingPoints = snappingPointsForKeyColor(keyColor: keyColor)
	var paletteShades: [Vec3] = []
	let range = [snappingPoints[0], snappingPoints[2]]
	let logLightness = getLogSpace(min: log10(0), max: log10(100), n: nShades)
	let linearLightness = pointsForKeyColor(
		keyColor: keyColor, range: range, centerPoint: snappingPoints[1]
	)
	var c = 0

	for i in 0 ..< nShades {
		let l = min(
			range[1],
			max(
				range[0],
				logLightness[i] * (1 - linearity) + linearLightness[i]
					* linearity
			)
		)

		while l > curvePoints[c + 1].0 {
			c += 1
		}

		let (l1, a1, b1) = curvePoints[c]
		let (l2, a2, b2) = curvePoints[c + 1]

		let u = (l - l1) / (l2 - l1)

		paletteShades.append(
			(l1 + (l2 - l1) * u, a1 + (a2 - a1) * u, b1 + (b2 - b1) * u)
		)
	}

	return paletteShades.map(snapIntoGamut)
}

func isLCHInsideSRGB(l: Double, c: Double, h: Double) -> Bool {
	let ε = 0.000005
	let rgb = LCHToSRGB((l, c, h))
	return [rgb.0, rgb.1, rgb.2].reduce(true) {
		$0 && $1 >= 0 - ε && $1 <= 1 + ε
	}
}

func snapIntoGamut(Lab: Vec3) -> Vec3 {
	// Moves an LCH color into the sRGB gamut
	// by holding the l and h steady,
	// and adjusting the c via binary-search
	// until the color is on the sRGB boundary.

	// .0001 chosen fairly arbitrarily as "close enough"
	let ε = 0.0001

	let LCH = LabToLCH(Lab)
	let l = LCH.0
	var c = LCH.1
	let h = LCH.2

	if isLCHInsideSRGB(l: l, c: c, h: h) {
		return Lab
	}

	var hiC = c
	var loC = 0.0
	c /= 2

	while hiC - loC > ε {
		if isLCHInsideSRGB(l: l, c: c, h: h) {
			loC = c
		} else {
			hiC = c
		}
		c = (hiC + loC) / 2
	}

	return LCHToLab((l, c, h))
}

func gamSRGB(_ RGB: Vec3) -> Vec3 {
	// Convert an array of linear-light sRGB values in the range 0.0-1.0
	// to gamma corrected form
	// https://en.wikipedia.org/wiki/SRGB
	// Extended transfer function:
	// For negative values, linear portion extends on reflection
	// of axis, then uses reflected pow below that
	let map = { (val: Double) -> Double in
		let sign = val < 0 ? -1 : 1
		let abs = abs(val)

		if abs > 0.0031308 {
			return Double(sign) * (1.055 * pow(abs, 1 / 2.4) - 0.055)
		}

		return 12.92 * val
	}

	return (map(RGB.0), map(RGB.1), map(RGB.2))
}

func LCHToSRGB(_ LCH: Vec3) -> Vec3 {
	// Convert an array of CIE LCH values
	// to CIE Lab, and then to XYZ,
	// adapt from D50 to D65,
	// then convert XYZ to linear-light sRGB
	// and finally to gamma corrected sRGB
	// for in-gamut colors, components are in the 0.0 to 1.0 range
	// out of gamut colors may have negative components
	// or components greater than 1.0
	// so check for that :)

	let lab = LCHToLab(LCH)
	let xyz = LabToXYZ(lab)
	let adaptedXYZ = D50ToD65(xyz)
	let linearRGB = linSRGBToXYZ(adaptedXYZ)
	return gamSRGB(linearRGB)
}

func paletteShadesFromCurve(
	keyColor: String,
	curve: CurvedHelixPath,
	nShades: Int = 16,
	linearity: Double = defaultLinearity,
	curveDepth: Int = 24
) -> [Vec3] {
	let _curve = CurvePath(curves: curve.curves)
	let _divisions = (
		(Double(1.0 + abs((curve.torsion ?? .zero) == .zero ? 1.0 : (curve.torsion ?? .zero))) * Double(curveDepth))
			.rounded(.up) / 2.0
	)
	let _points = getPointsOnCurvePath(_curve, Int(_divisions))

	let points: [Vec3] = _points.map { curvePoint in
		getPointOnHelix(
			pointOnCurve: curvePoint,
			torsion: curve.torsion ?? 0,
			torsionT0: curve.torsionT0 ?? 50
		)
	}

	return paletteShadesFromCurvePoints(
		curvePoints: points,
		nShades: nShades,
		linearity: linearity,
		keyColor: keyColor
	)
}

func sRGBToHex(_ rgb: Vec3) -> String {
	String(
		format: "#%02X%02X%02X",
		max(0, min(255, Int(rgb.0 * 255))),
		max(0, min(255, Int(rgb.1 * 255))),
		max(0, min(255, Int(rgb.2 * 255)))
	)
}

func XYZToLinSRGB(_ XYZ: Vec3) -> Vec3 {
	let M: [[Double]] = [
		[3.2409699419045226, -1.537383177570094, -0.4986107602930034],
		[-0.9692436362808796, 1.8759675015077202, 0.04155505740717559],
		[0.05563007969699366, -0.20397695888897652, 1.0569715142428786],
	]
	let result = multiplyMatrices(M, [[XYZ.0], [XYZ.1], [XYZ.2]])
	return (result[0][0], result[1][0], result[2][0])
}

func LabToSRGB(_ lab: Vec3) -> Vec3 {
	let xyz = LabToXYZ(lab)
	let adaptedXYZ = D50ToD65(xyz)
	let linearRGB = XYZToLinSRGB(adaptedXYZ)
	return gamSRGB(linearRGB)
}

func LabToHex(_ lab: Vec3) -> String {
	sRGBToHex(LabToSRGB(lab))
}

func paletteShadesToHex(paletteShades: [Vec3]) -> [String] {
	paletteShades.map(LabToHex)
}

func hexColorsFromPalette(
	keyColor: String,
	palette: Palette,
	nShades: Int = 16,
	linearity: Double = defaultLinearity,
	curveDepth: Int = 24
) -> [String] {
	let curve = curvePathFromPalette(palette: palette)
	let shades = paletteShadesFromCurve(
		keyColor: keyColor,
		curve: curve,
		nShades: nShades,
		linearity: linearity,
		curveDepth: curveDepth
	)
	return paletteShadesToHex(paletteShades: shades)
}

func getBrandTokensFromPalette(keyColor: String, options: Options = Options()) -> [String: String] {
	let darkCp = options.darkCp
	let lightCp = options.lightCp
	let hueTorsion = options.hueTorsion

	let brandPalette = Palette(
		keyColor: hexToLCH(hex: keyColor),
		darkCp: darkCp,
		lightCp: lightCp,
		hueTorsion: hueTorsion
	)

	let hexColors = hexColorsFromPalette(
		keyColor: keyColor,
		palette: brandPalette,
		nShades: 16,
		linearity: 1
	)

	var brandVariants: [String: String] = [:]
	for (index, hexColor) in hexColors.enumerated() {
		brandVariants["\((index + 1) * 10)"] = hexColor
	}

	return brandVariants
}
