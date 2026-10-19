import Division
public import Rounding

extension Decimals {

    public enum Rounding {}
}

extension Decimals.Rounding {

    static func digitCount(_ coefficient: UInt64) -> Int {
        var digits = 0
        var temp = coefficient
        while temp > 0 {
            digits += 1
            temp /= 10
        }
        return digits
    }

    static func digitCount(_ coefficient: UInt128) -> Int {
        var digits = 0
        var temp = coefficient
        while temp > 0 {
            digits += 1
            temp /= 10
        }
        return digits
    }
}

extension Decimals.Rounding {

    public static func round(
        coefficient: UInt64,
        exponent: Decimal.Exponent,
        sign: FloatingPointSign,
        rounding: Rounding::Rounding,
        precision: Decimal.Precision,
        sticky: Bool = false
    ) -> (coefficient: UInt32, exponent: Decimal.Exponent, status: Decimal.Status) {
        let c = coefficient
        var e = exponent
        var status: Decimal.Status = .none

        var digits = 0
        var temp = c
        while temp > 0 {
            digits += 1
            temp /= 10
        }

        if digits <= precision.rawValue {
            return (UInt32(truncatingIfNeeded: c), e, sticky ? .inexact : status)
        }

        let roundDigits = digits - precision.rawValue

        var divisor: UInt64 = 1
        for _ in 0..<roundDigits {
            divisor *= 10
        }

        let quotient = c / divisor
        let remainder = c % divisor
        let halfDivisor = divisor / 2

        let remainderPositive = remainder > 0 || sticky
        let isAboveHalf = remainder > halfDivisor || (sticky && remainder == halfDivisor)
        let isExactHalf = remainder == halfDivisor && !sticky

        let comparison: Order.Comparison? =
            remainderPositive ? (isAboveHalf ? .greater : (isExactHalf ? .equal : .less)) : nil
        let roundUp =
            (try? rounding.incrementsMagnitude(
                isNegative: sign == .minus,
                integralPartIsOdd: quotient % 2 != 0,
                fractionComparedToHalf: comparison
            )) ?? false

        var result = quotient
        if roundUp {
            result += 1
        }

        if remainderPositive {
            status = .inexact
        }

        e += roundDigits

        if result > UInt64(Decimal.Format32.coefficientMax()) {
            result /= 10

            e += 1
        }

        return (UInt32(truncatingIfNeeded: result), e, status)
    }

    public static func round(
        coefficient: UInt128,
        exponent: Decimal.Exponent,
        sign: FloatingPointSign,
        rounding: Rounding::Rounding,
        precision: Decimal.Precision,
        sticky: Bool = false
    ) -> (coefficient: UInt64, exponent: Decimal.Exponent, status: Decimal.Status) {
        let c = coefficient
        var e = exponent
        var status: Decimal.Status = .none

        var digits = 0
        var temp = c
        while temp > 0 {
            digits += 1
            temp /= 10
        }

        if digits <= precision.rawValue {
            return (UInt64(truncatingIfNeeded: c), e, sticky ? .inexact : status)
        }

        let roundDigits = digits - precision.rawValue

        var divisor: UInt128 = 1
        for _ in 0..<roundDigits {
            divisor *= 10
        }

        let quotient = c / divisor
        let remainder = c % divisor
        let halfDivisor = divisor / 2

        let remainderPositive = remainder > 0 || sticky
        let isAboveHalf = remainder > halfDivisor || (sticky && remainder == halfDivisor)
        let isExactHalf = remainder == halfDivisor && !sticky

        let comparison: Order.Comparison? =
            remainderPositive ? (isAboveHalf ? .greater : (isExactHalf ? .equal : .less)) : nil
        let roundUp =
            (try? rounding.incrementsMagnitude(
                isNegative: sign == .minus,
                integralPartIsOdd: quotient % 2 != 0,
                fractionComparedToHalf: comparison
            )) ?? false

        var result = quotient
        if roundUp {
            result += 1
        }

        if remainderPositive {
            status = .inexact
        }

        e += roundDigits

        if result > UInt128(Decimal.Format64.coefficientMax()) {
            result /= 10

            e += 1
        }

        return (UInt64(truncatingIfNeeded: result), e, status)
    }

    public static func round128(
        coefficient: UInt128,
        exponent: Decimal.Exponent,
        sign: FloatingPointSign,
        rounding: Rounding::Rounding,
        precision: Decimal.Precision,
        sticky: Bool = false
    ) -> (coefficient: UInt128, exponent: Decimal.Exponent, status: Decimal.Status) {
        let c = coefficient
        var e = exponent
        var status: Decimal.Status = .none

        var digits = 0
        var temp = c
        while temp > 0 {
            digits += 1
            temp /= 10
        }

        if digits <= precision.rawValue {
            return (c, e, sticky ? .inexact : status)
        }

        let roundDigits = digits - precision.rawValue

        var divisor: UInt128 = 1
        for _ in 0..<roundDigits {
            divisor *= 10
        }

        let quotient = c / divisor
        let remainder = c % divisor
        let halfDivisor = divisor / 2

        let remainderPositive = remainder > 0 || sticky
        let isAboveHalf = remainder > halfDivisor || (sticky && remainder == halfDivisor)
        let isExactHalf = remainder == halfDivisor && !sticky

        let comparison: Order.Comparison? =
            remainderPositive ? (isAboveHalf ? .greater : (isExactHalf ? .equal : .less)) : nil
        let roundUp =
            (try? rounding.incrementsMagnitude(
                isNegative: sign == .minus,
                integralPartIsOdd: quotient % 2 != 0,
                fractionComparedToHalf: comparison
            )) ?? false

        var result = quotient
        if roundUp {
            result += 1
        }

        if remainderPositive {
            status = .inexact
        }

        e += roundDigits

        if result > Decimal.Format128.coefficientMax() {
            result /= 10

            e += 1
        }

        return (result, e, status)
    }
}

extension Decimals.Rounding {

    static func dropping<Coefficient: FixedWidthInteger & UnsignedInteger>(
        _ digits: Int,
        from coefficient: Coefficient,
        sign: FloatingPointSign,
        rounding: Rounding::Rounding
    ) -> Coefficient {
        guard digits > 0 else {
            return coefficient
        }
        guard digits <= 37 else {
            let increments = try? rounding.incrementsMagnitude(
                isNegative: sign == .minus,
                integralPartIsOdd: false,
                fractionComparedToHalf: coefficient == 0 ? nil : .less
            )
            return increments == true ? 1 : 0
        }
        var divisor: Int128 = 1
        for _ in 0..<digits {
            divisor *= 10
        }
        let dividend = sign == .minus ? -Int128(coefficient) : Int128(coefficient)
        let quotient = (try? Division.rounded(dividend, by: divisor, rounding: rounding).quotient) ?? dividend / divisor
        return Coefficient(quotient.magnitude)
    }
}
