extension Decimals.Rounding {
    static func drop(
        _ digits: Int,
        from coefficient: UInt64,
        sign: Decimal.Sign,
        rounding: Decimal.Rounding
    ) -> (coefficient: UInt64, inexact: Bool) {
        guard digits > 0 else {
            return (coefficient, false)
        }

        guard digits <= 19 else {
            let remainderPositive = coefficient > 0
            let roundUp: Bool =
                switch rounding {
                case .ceiling: remainderPositive && sign == .positive
                case .floor: remainderPositive && sign == .negative
                case .up: remainderPositive
                case .down, .even, .away, .toward: false
                }
            return (roundUp ? 1 : 0, remainderPositive)
        }

        var divisor: UInt64 = 1
        for _ in 0..<digits {
            divisor *= 10
        }

        let quotient = coefficient / divisor
        let remainder = coefficient % divisor
        let half = divisor / 2
        let remainderPositive = remainder > 0

        let roundUp: Bool =
            switch rounding {
            case .ceiling: remainderPositive && sign == .positive
            case .floor: remainderPositive && sign == .negative
            case .down: false
            case .up: remainderPositive
            case .even: remainder > half || (remainder == half && quotient % 2 != 0)
            case .away: remainderPositive && remainder >= half
            case .toward: remainder > half
            }

        return (roundUp ? quotient + 1 : quotient, remainderPositive)
    }
}
