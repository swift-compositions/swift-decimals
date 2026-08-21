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
        sign: Decimal.Sign,
        rounding: Decimal.Rounding,
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

        var roundUp = false
        switch rounding {
        case .ceiling:
            roundUp = remainderPositive && sign == .positive

        case .floor:
            roundUp = remainderPositive && sign == .negative

        case .down:
            roundUp = false

        case .up:
            roundUp = remainderPositive

        case .even:
            if isAboveHalf {
                roundUp = true
            } else if isExactHalf {
                roundUp = (quotient % 2) != 0
            }

        case .away:
            roundUp = isAboveHalf || isExactHalf

        case .toward:
            roundUp = isAboveHalf
        }

        var result = quotient
        if roundUp {
            result += 1
        }

        if remainderPositive {
            status = .inexact
        }

        e = e + roundDigits

        if result > UInt64(Decimal.Format32.coefficientMax()) {
            result /= 10

            e = e + 1
        }

        return (UInt32(truncatingIfNeeded: result), e, status)
    }

    public static func round(
        coefficient: UInt128,
        exponent: Decimal.Exponent,
        sign: Decimal.Sign,
        rounding: Decimal.Rounding,
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

        var roundUp = false
        switch rounding {
        case .ceiling:
            roundUp = remainderPositive && sign == .positive

        case .floor:
            roundUp = remainderPositive && sign == .negative

        case .down:
            roundUp = false

        case .up:
            roundUp = remainderPositive

        case .even:
            if isAboveHalf {
                roundUp = true
            } else if isExactHalf {
                roundUp = (quotient % 2) != 0
            }

        case .away:
            roundUp = isAboveHalf || isExactHalf

        case .toward:
            roundUp = isAboveHalf
        }

        var result = quotient
        if roundUp {
            result += 1
        }

        if remainderPositive {
            status = .inexact
        }

        e = e + roundDigits

        if result > UInt128(Decimal.Format64.coefficientMax()) {
            result /= 10

            e = e + 1
        }

        return (UInt64(truncatingIfNeeded: result), e, status)
    }

    public static func round128(
        coefficient: UInt128,
        exponent: Decimal.Exponent,
        sign: Decimal.Sign,
        rounding: Decimal.Rounding,
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

        var roundUp = false
        switch rounding {
        case .ceiling:
            roundUp = remainderPositive && sign == .positive

        case .floor:
            roundUp = remainderPositive && sign == .negative

        case .down:
            roundUp = false

        case .up:
            roundUp = remainderPositive

        case .even:
            if isAboveHalf {
                roundUp = true
            } else if isExactHalf {
                roundUp = (quotient % 2) != 0
            }

        case .away:
            roundUp = isAboveHalf || isExactHalf

        case .toward:
            roundUp = isAboveHalf
        }

        var result = quotient
        if roundUp {
            result += 1
        }

        if remainderPositive {
            status = .inexact
        }

        e = e + roundDigits

        if result > Decimal.Format128.coefficientMax() {
            result /= 10

            e = e + 1
        }

        return (result, e, status)
    }
}
