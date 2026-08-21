extension Decimals {

    struct Wide: Sendable, Hashable {

        var high: UInt128

        var low: UInt128
    }
}

extension Decimals.Wide {

    init(_ value: UInt128) {
        self.init(high: 0, low: value)
    }
}

extension Decimals.Wide: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.high != rhs.high { return lhs.high < rhs.high }
        return lhs.low < rhs.low
    }
}

extension Decimals.Wide {
    var isZero: Bool { high == 0 && low == 0 }
}

extension Decimals.Wide {

    func multipliedBy10() -> Self {
        let (carry, newLow) = low.multipliedFullWidth(by: 10)
        let (highTimesTen, highOverflow) = high.multipliedReportingOverflow(by: 10)
        let (newHigh, carryOverflow) = highTimesTen.addingReportingOverflow(carry)
        precondition(
            !highOverflow && !carryOverflow,
            "Decimals.Wide multiplication overflowed 256 bits"
        )
        return Self(high: newHigh, low: newLow)
    }

    static func multiplied(_ value: Self, byPowerOf10 count: Int) -> Self {
        var result = value
        for _ in 0..<count {
            result = result.multipliedBy10()
        }
        return result
    }

    func adding(_ other: Self) -> Self {
        let (lowSum, lowCarry) = low.addingReportingOverflow(other.low)
        let (highSum, highOverflow) = high.addingReportingOverflow(other.high)
        let (highSum2, carryOverflow) = highSum.addingReportingOverflow(lowCarry ? 1 : 0)
        precondition(!highOverflow && !carryOverflow, "Decimals.Wide addition overflowed 256 bits")
        return Self(high: highSum2, low: lowSum)
    }

    func subtracting(_ other: Self) -> Self {
        precondition(self >= other, "Decimals.Wide subtraction requires self >= other")
        let (lowDiff, lowBorrow) = low.subtractingReportingOverflow(other.low)
        let (highDiff, _) = high.subtractingReportingOverflow(other.high)

        let (highDiff2, _) = highDiff.subtractingReportingOverflow(lowBorrow ? 1 : 0)
        return Self(high: highDiff2, low: lowDiff)
    }

    func dividedBy10() -> (quotient: Self, remainder: UInt128) {
        let (highQuotient, highRemainder) = high.quotientAndRemainder(dividingBy: 10)

        let (lowQuotient, lowRemainder) = UInt128(10).dividingFullWidth(
            (high: highRemainder, low: low)
        )
        return (Self(high: highQuotient, low: lowQuotient), lowRemainder)
    }

    func reduced(
        toFitBelowOrEqual limit: UInt128
    ) -> (coefficient: UInt128, shift: Int, sticky: Bool) {
        var value = self
        var shift = 0
        var sticky = false
        while value.high != 0 || value.low > limit {
            let (quotient, remainder) = value.dividedBy10()
            if remainder != 0 { sticky = true }
            value = quotient
            shift += 1
        }
        return (value.low, shift, sticky)
    }

    func reducedToFitUInt128() -> (coefficient: UInt128, shift: Int, sticky: Bool) {
        reduced(toFitBelowOrEqual: .max)
    }
}
