import Rounding

extension Decimal.Format32: @retroactive FloatingPoint {
    public typealias Exponent = Int

    public static var radix: Int { 10 }

    public static var nan: Self { .nan() }

    public static var signalingNaN: Self { .nan(kind: .signaling) }

    public static var infinity: Self { .infinity() }

    public static var greatestFiniteMagnitude: Self {
        .encode(sign: .plus, exponent: maxExponent, coefficient: coefficientMax())
    }

    public static var leastNormalMagnitude: Self {
        .encode(sign: .plus, exponent: Decimal.Exponent.Format32.scientificMin, coefficient: 1)
    }

    public static var leastNonzeroMagnitude: Self {
        .encode(sign: .plus, exponent: minExponent, coefficient: 1)
    }

    public static var ulpOfOne: Self {
        .encode(sign: .plus, exponent: Decimal.Exponent(1 - precision.rawValue), coefficient: 1)
    }

    public static var pi: Self {
        .encode(sign: .plus, exponent: Decimal.Exponent(-6), coefficient: 3_141_592)
    }

    public init(_ value: Int) {
        self.init(rounding: value)
    }

    public init<Source: BinaryInteger>(_ value: Source) {
        self.init(rounding: value)
    }

    public init(sign: FloatingPointSign, exponent: Int, significand: Self) {
        let scaled = significand.scaled(byPowerOfTen: exponent)
        self = sign == .minus ? scaled.negated : scaled
    }

    public init(signOf sign: Self, magnitudeOf magnitude: Self) {
        let mask: UInt32 = 0x8000_0000
        self.init(bits: (magnitude.bits & ~mask) | (sign.bits & mask))
    }

    public var exponent: Int {
        guard test.finite else {
            return .max
        }
        let coefficient = canonicalCoefficient
        guard coefficient != 0 else {
            return .min
        }
        return Int(extractExponent()) + Decimals.Rounding.digitCount(UInt64(coefficient)) - 1
    }

    public var significand: Self {
        guard !test.nan else {
            return .nan
        }
        guard !test.infinite else {
            return .infinity
        }
        let coefficient = canonicalCoefficient
        guard coefficient != 0 else {
            return .zero
        }
        return .encode(
            sign: .plus,
            exponent: Decimal.Exponent(1 - Decimals.Rounding.digitCount(UInt64(coefficient))),
            coefficient: coefficient
        )
    }

    public var ulp: Self {
        guard test.finite else {
            return .nan
        }
        guard canonicalCoefficient != 0 else {
            return .leastNonzeroMagnitude
        }
        let quantum = max(exponent - (Self.precision.rawValue - 1), Int(Self.minExponent))
        return .encode(sign: .plus, exponent: Decimal.Exponent(quantum), coefficient: 1)
    }

    public var nextUp: Self {
        guard !test.nan else {
            return .nan
        }
        guard !test.infinite else {
            return sign == .minus ? -.greatestFiniteMagnitude : self
        }
        guard canonicalCoefficient != 0 else {
            return .leastNonzeroMagnitude
        }
        var (coefficient, exponent) = widened
        let smallest = (Self.coefficientMax() + 1) / 10
        if sign == .plus {
            coefficient += 1
            if coefficient > Self.coefficientMax() {
                coefficient = smallest
                exponent += 1
                guard exponent <= Int(Self.maxExponent) else {
                    return .infinity
                }
            }
        } else {
            coefficient -= 1
            if coefficient < smallest, exponent > Int(Self.minExponent) {
                coefficient = coefficient * 10 + 9
                exponent -= 1
            }
        }
        return .encode(sign: sign, exponent: Decimal.Exponent(exponent), coefficient: coefficient)
    }

    public var isNormal: Bool { test.normal }

    public var isFinite: Bool { test.finite }

    public var isZero: Bool { test.finite && canonicalCoefficient == 0 }

    public var isSubnormal: Bool { test.subnormal }

    public var isInfinite: Bool { test.infinite }

    public var isNaN: Bool { test.nan }

    public var isSignalingNaN: Bool { test.signaling }

    public var isCanonical: Bool { !test.finite || extractCoefficient() <= Self.coefficientMax() }

    public mutating func round(_ rule: FloatingPointRoundingRule) {
        guard !test.nan else {
            self = .nan
            return
        }
        let exponent = Int(extractExponent())
        guard test.finite, exponent < 0 else {
            return
        }
        let coefficient = Decimals.Rounding.dropping(
            -exponent,
            from: canonicalCoefficient,
            sign: sign,
            rounding: Rounding::Rounding(rule)
        )
        self = .encode(sign: sign, exponent: Decimal.Exponent(0), coefficient: coefficient)
    }

    public mutating func formRemainder(dividingBy other: Self) {
        self = remainder(dividingBy: other, truncating: false)
    }

    public mutating func formTruncatingRemainder(dividingBy other: Self) {
        self = remainder(dividingBy: other, truncating: true)
    }

    public mutating func formSquareRoot() {
        guard !test.nan else {
            self = .nan
            return
        }
        guard test.infinite || canonicalCoefficient != 0 else {
            return
        }
        guard sign == .plus else {
            self = .nan
            return
        }
        guard !test.infinite else {
            return
        }
        let ideal = Int(extractExponent()) >> 1
        var radicand = UInt128(canonicalCoefficient)
        var exponent = Int(extractExponent())
        if exponent & 1 != 0 {
            radicand *= 10
            exponent -= 1
        }
        let floor: UInt128 = 10_000_000_000_000_000
        while radicand < floor {
            radicand *= 100
            exponent -= 2
        }
        let root = Decimals.Wide(radicand).squareRoot()
        let exact = root * root == radicand
        var rounded = Decimals.Rounding.round(
            coefficient: UInt64(root),
            exponent: Decimal.Exponent(exponent / 2),
            sign: .plus,
            rounding: .even,
            precision: Self.precision,
            sticky: !exact
        )
        if exact {
            while rounded.coefficient % 10 == 0, Int(rounded.exponent) < ideal {
                rounded.coefficient /= 10
                rounded.exponent += 1
            }
        }
        self = .encode(sign: .plus, exponent: rounded.exponent, coefficient: rounded.coefficient)
    }

    public mutating func addProduct(_ lhs: Self, _ rhs: Self) {
        self = lhs.operation.fuse(rhs, self).value
    }

    public func isEqual(to other: Self) -> Bool {
        self == other
    }

    public func isLess(than other: Self) -> Bool {
        operation.compare(other) == .less
    }

    public func isLessThanOrEqualTo(_ other: Self) -> Bool {
        let comparison = operation.compare(other)
        return comparison == .less || comparison == .equal
    }

    public func isTotallyOrdered(belowOrEqualTo other: Self) -> Bool {
        operation.order(other) != .greater
    }

    public func distance(to other: Self) -> Self {
        other - self
    }

    public func advanced(by amount: Self) -> Self {
        self + amount
    }
}

extension Decimal.Format32 {
    init<Source: BinaryInteger>(rounding value: Source) {
        let sign: FloatingPointSign = value < 0 ? .minus : .plus
        var magnitude = value.magnitude
        var exponent = 0
        var sticky = false
        if let limit = Source.Magnitude(exactly: UInt64.max) {
            while magnitude > limit {
                sticky = sticky || magnitude % 10 != 0
                magnitude /= 10
                exponent += 1
            }
        }
        let rounded = Decimals.Rounding.round(
            coefficient: UInt64(truncatingIfNeeded: magnitude),
            exponent: Decimal.Exponent(exponent),
            sign: sign,
            rounding: Decimal.Context.format32.rounding,
            precision: Self.precision,
            sticky: sticky
        )
        guard rounded.exponent <= Self.maxExponent else {
            self = .infinity(sign: sign)
            return
        }
        self = .encode(sign: sign, exponent: rounded.exponent, coefficient: rounded.coefficient)
    }

    var canonicalCoefficient: UInt32 {
        let coefficient = extractCoefficient()
        return coefficient <= Self.coefficientMax() ? coefficient : 0
    }

    var widened: (coefficient: UInt32, exponent: Int) {
        var coefficient = canonicalCoefficient
        var exponent = Int(extractExponent())
        while coefficient <= Self.coefficientMax() / 10, exponent > Int(Self.minExponent) {
            coefficient *= 10
            exponent -= 1
        }
        return (coefficient, exponent)
    }

    func scaled(byPowerOfTen power: Int) -> Self {
        guard test.finite, canonicalCoefficient != 0 else {
            return self
        }
        let coefficient = canonicalCoefficient
        let target = Int(extractExponent()) + max(min(power, 1_000), -1_000)
        if target > Int(Self.maxExponent) {
            let shift = target - Int(Self.maxExponent)
            guard Decimals.Rounding.digitCount(UInt64(coefficient)) + shift <= Self.precision.rawValue else {
                return .infinity(sign: sign)
            }
            var padded = coefficient
            for _ in 0..<shift {
                padded *= 10
            }
            return .encode(sign: sign, exponent: Self.maxExponent, coefficient: padded)
        }
        if target < Int(Self.minExponent) {
            let dropped = Decimals.Rounding.dropping(
                Int(Self.minExponent) - target,
                from: coefficient,
                sign: sign,
                rounding: Decimal.Context.format32.rounding
            )
            return .encode(sign: sign, exponent: Self.minExponent, coefficient: dropped)
        }
        return .encode(sign: sign, exponent: Decimal.Exponent(target), coefficient: coefficient)
    }

    func remainder(dividingBy divisor: Self, truncating: Bool) -> Self {
        guard !test.nan, !divisor.test.nan, !test.infinite, divisor.canonicalCoefficient != 0 else {
            return .nan
        }
        guard !divisor.test.infinite, canonicalCoefficient != 0 else {
            return self
        }
        let dividendExponent = Int(extractExponent())
        let divisorExponent = Int(divisor.extractExponent())
        let unit: Int
        let modulus: UInt128
        let doubled: UInt128
        if divisorExponent <= dividendExponent {
            unit = divisorExponent
            modulus = UInt128(divisor.canonicalCoefficient)
            doubled = modulus * 2
            var residue = UInt128(canonicalCoefficient) % doubled
            for _ in 0..<(dividendExponent - divisorExponent) {
                residue = residue * 10 % doubled
            }
            return Self.remainder(residue, modulus: modulus, unit: unit, sign: sign, truncating: truncating)
        }
        unit = dividendExponent
        let gap = divisorExponent - dividendExponent
        guard gap < 8 else {
            return self
        }
        var scaled = UInt128(divisor.canonicalCoefficient)
        for _ in 0..<gap {
            scaled *= 10
        }
        modulus = scaled
        doubled = modulus * 2
        return Self.remainder(
            UInt128(canonicalCoefficient) % doubled,
            modulus: modulus,
            unit: unit,
            sign: sign,
            truncating: truncating
        )
    }

    static func remainder(
        _ residue: UInt128,
        modulus: UInt128,
        unit: Int,
        sign: FloatingPointSign,
        truncating: Bool
    ) -> Self {
        let quotientIsOdd = residue >= modulus
        var magnitude = quotientIsOdd ? residue - modulus : residue
        var resultSign = sign
        if !truncating, magnitude * 2 > modulus || (magnitude * 2 == modulus && quotientIsOdd) {
            magnitude = modulus - magnitude
            resultSign = sign == .plus ? .minus : .plus
        }
        guard magnitude != 0 else {
            return .encode(sign: sign, exponent: Decimal.Exponent(unit), coefficient: 0)
        }
        return .encode(sign: resultSign, exponent: Decimal.Exponent(unit), coefficient: UInt32(magnitude))
    }
}
