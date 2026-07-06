import SwiftUI

/// OKLch 颜色空间 → sRGB Color 转换
/// 对齐原型 CSS `oklch(L C H)` 与 `oklch(L C H / A)` 取值
/// OKLch 色域比 sRGB 大，out-of-gamut 颜色通过二分降低 chroma 做 gamut mapping
struct OKLch {
    let l: Double   // 0...1 (原型中 12% 即 0.12)
    let c: Double   // chroma 0...~0.4
    let h: Double   // hue 0...360
    let a: Double   // alpha 0...1

    init(_ l: Double, _ c: Double, _ h: Double, _ a: Double = 1) {
        self.l = l
        self.c = c
        self.h = h
        self.a = a
    }

    /// 转换为 SwiftUI Color（sRGB，带 gamut mapping）
    var color: Color {
        let (r, g, b) = sRGBComponents()
        return Color(
            .sRGB,
            red: r,
            green: g,
            blue: b,
            opacity: a
        )
    }

    /// OKLch → linear sRGB → sRGB，含 gamut mapping（chroma 二分）
    private func sRGBComponents() -> (Double, Double, Double) {
        var lo: Double = 0
        var hi: Double = c
        var best: (Double, Double, Double) = (0, 0, 0)
        var foundInGamut = false
        for _ in 0..<20 {
            let mid = (lo + hi) / 2
            let rgb = oklchToLinearSRGB(l: l, c: mid, h: h)
            if inSRGBGamut(rgb) {
                best = linearToSRGB(rgb)
                lo = mid
                foundInGamut = true
            } else {
                hi = mid
            }
        }
        if !foundInGamut {
            let rgb = oklchToLinearSRGB(l: l, c: 0, h: h)
            best = linearToSRGB(rgb)
        }
        return best
    }

    private func oklchToLinearSRGB(l: Double, c: Double, h: Double) -> (Double, Double, Double) {
        let hRad = h * .pi / 180
        let aLab = c * cos(hRad)
        let bLab = c * sin(hRad)
        // OKLab → LMS
        let l_ = l + 0.396 * aLab + 0.215 * bLab
        let m_ = l - 0.105 * aLab - 0.063 * bLab
        let s_ = l - 0.089 * aLab - 1.291 * bLab
        // 非线性
        func cube(_ x: Double) -> Double { x * x * x }
        let lCube = l_ > 0 ? cube(l_) : 0
        let mCube = m_ > 0 ? cube(m_) : 0
        let sCube = s_ > 0 ? cube(s_) : 0
        // LMS → linear sRGB
        let r = 4.0767416621 * lCube - 3.3077115913 * mCube + 0.2309699292 * sCube
        let g = -1.2684380046 * lCube + 2.6097574011 * mCube - 0.3413193965 * sCube
        let b = -0.0041960863 * lCube - 0.7034186147 * mCube + 1.7076147010 * sCube
        return (r, g, b)
    }

    private func inSRGBGamut(_ rgb: (Double, Double, Double)) -> Bool {
        let eps = 0.0001
        return rgb.0 >= -eps && rgb.0 <= 1 + eps &&
               rgb.1 >= -eps && rgb.1 <= 1 + eps &&
               rgb.2 >= -eps && rgb.2 <= 1 + eps
    }

    private func linearToSRGB(_ rgb: (Double, Double, Double)) -> (Double, Double, Double) {
        func encode(_ c: Double) -> Double {
            let clamped = min(max(c, 0), 1)
            if clamped <= 0.0031308 {
                return 12.92 * clamped
            }
            return 1.055 * pow(clamped, 1.0 / 2.4) - 0.055
        }
        return (encode(rgb.0), encode(rgb.1), encode(rgb.2))
    }
}
