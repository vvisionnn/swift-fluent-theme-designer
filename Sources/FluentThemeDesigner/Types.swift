typealias Vec2 = (Double, Double)
typealias Vec3 = (Double, Double, Double)
typealias Vec4 = (Double, Double, Double, Double)

struct Curve {
	var points: [Vec3]
}

struct CurvePath {
	var curves: [Curve]
}

struct CurvedHelixPath {
	var curves: [Curve]
	var cacheLengths: [Double]?
	var torsion: Double?
	var torsionT0: Double?
}

struct Palette {
	var keyColor: Vec3
	var darkCp: Double
	var lightCp: Double
	var hueTorsion: Double
}

public struct Options: Hashable {
	public let darkCp: Double
	public let lightCp: Double
	public let hueTorsion: Double

	public init(
		darkCp: Double = 2 / 3,
		lightCp: Double = 1 / 3,
		hueTorsion: Double = 0.0
	) {
		self.darkCp = darkCp
		self.lightCp = lightCp
		self.hueTorsion = hueTorsion
	}
}

public enum PaletteTokenKey: String, Hashable {
	case t10 = "10"
	case t20 = "20"
	case t30 = "30"
	case t40 = "40"
	case t50 = "50"
	case t60 = "60"
	case t70 = "70"
	case t80 = "80"
	case t90 = "90"
	case t100 = "100"
	case t110 = "110"
	case t120 = "120"
	case t130 = "130"
	case t140 = "140"
	case t150 = "150"
	case t160 = "160"
}
