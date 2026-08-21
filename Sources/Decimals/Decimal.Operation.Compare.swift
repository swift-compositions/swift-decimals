extension Decimal.Operation where Value == Decimal.Format32 {

    public func compare(_ other: Value) -> Decimal.Compare {

        if base.test.nan || other.test.nan {
            return .unordered
        }

        let baseInf = base.test.infinite
        let otherInf = other.test.infinite

        if baseInf && otherInf {
            let baseNeg = base.test.negative
            let otherNeg = other.test.negative
            if baseNeg == otherNeg {
                return .equal
            }
            return baseNeg ? .less : .greater
        }

        if baseInf {
            return base.test.negative ? .less : .greater
        }

        if otherInf {
            return other.test.negative ? .greater : .less
        }

        let baseZero = base.test.zero
        let otherZero = other.test.zero

        if baseZero && otherZero {
            return .equal
        }
        if baseZero {
            return other.test.negative ? .greater : .less
        }
        if otherZero {
            return base.test.negative ? .less : .greater
        }

        let baseNeg = base.test.negative
        let otherNeg = other.test.negative

        if baseNeg != otherNeg {
            return baseNeg ? .less : .greater
        }

        let magnitudeOrder = compareMagnitude(other)

        if baseNeg {
            switch magnitudeOrder {
            case .less: return .greater
            case .greater: return .less
            case .equal: return .equal
            case .unordered: return .unordered
            }
        }
        return magnitudeOrder
    }

    @usableFromInline
    internal func compareMagnitude(_ other: Value) -> Decimal.Compare {
        let aCoef = base.extractCoefficient()
        let bCoef = other.extractCoefficient()
        let aExp = base.extractExponent()
        let bExp = other.extractExponent()

        if aExp == bExp {
            if aCoef < bCoef { return .less }
            if aCoef > bCoef { return .greater }
            return .equal
        }

        let diff = aExp.rawValue - bExp.rawValue

        if diff > 7 { return .greater }
        if diff < -7 { return .less }

        if diff > 0 {

            var scaled = UInt64(aCoef)
            for _ in 0..<diff {
                scaled *= 10
            }
            if scaled > UInt64(bCoef) { return .greater }
            if scaled < UInt64(bCoef) { return .less }
            return .equal
        } else {

            var scaled = UInt64(bCoef)
            for _ in 0..<(-diff) {
                scaled *= 10
            }
            if UInt64(aCoef) > scaled { return .greater }
            if UInt64(aCoef) < scaled { return .less }
            return .equal
        }
    }
}

extension Decimal.Operation where Value == Decimal.Format64 {

    public func compare(_ other: Value) -> Decimal.Compare {

        if base.test.nan || other.test.nan {
            return .unordered
        }

        let baseInf = base.test.infinite
        let otherInf = other.test.infinite

        if baseInf && otherInf {
            let baseNeg = base.test.negative
            let otherNeg = other.test.negative
            if baseNeg == otherNeg {
                return .equal
            }
            return baseNeg ? .less : .greater
        }

        if baseInf {
            return base.test.negative ? .less : .greater
        }

        if otherInf {
            return other.test.negative ? .greater : .less
        }

        let baseZero = base.test.zero
        let otherZero = other.test.zero

        if baseZero && otherZero {
            return .equal
        }
        if baseZero {
            return other.test.negative ? .greater : .less
        }
        if otherZero {
            return base.test.negative ? .less : .greater
        }

        let baseNeg = base.test.negative
        let otherNeg = other.test.negative

        if baseNeg != otherNeg {
            return baseNeg ? .less : .greater
        }

        let magnitudeOrder = compareMagnitude(other)

        if baseNeg {
            switch magnitudeOrder {
            case .less: return .greater
            case .greater: return .less
            case .equal: return .equal
            case .unordered: return .unordered
            }
        }
        return magnitudeOrder
    }

    @usableFromInline
    internal func compareMagnitude(_ other: Value) -> Decimal.Compare {
        let aCoef = base.extractCoefficient()
        let bCoef = other.extractCoefficient()
        let aExp = base.extractExponent()
        let bExp = other.extractExponent()

        if aExp == bExp {
            if aCoef < bCoef { return .less }
            if aCoef > bCoef { return .greater }
            return .equal
        }

        let diff = aExp.rawValue - bExp.rawValue

        if diff > 16 { return .greater }
        if diff < -16 { return .less }

        if diff > 0 {
            var scaled = UInt128(aCoef)
            for _ in 0..<diff {
                scaled *= 10
            }
            let bCoef128 = UInt128(bCoef)
            if scaled > bCoef128 { return .greater }
            if scaled < bCoef128 { return .less }
            return .equal
        } else {
            var scaled = UInt128(bCoef)
            for _ in 0..<(-diff) {
                scaled *= 10
            }
            let aCoef128 = UInt128(aCoef)
            if aCoef128 > scaled { return .greater }
            if aCoef128 < scaled { return .less }
            return .equal
        }
    }
}

extension Decimal.Operation where Value == Decimal.Format128 {

    public func compare(_ other: Value) -> Decimal.Compare {

        if base.test.nan || other.test.nan {
            return .unordered
        }

        let baseInf = base.test.infinite
        let otherInf = other.test.infinite

        if baseInf && otherInf {
            let baseNeg = base.test.negative
            let otherNeg = other.test.negative
            if baseNeg == otherNeg {
                return .equal
            }
            return baseNeg ? .less : .greater
        }

        if baseInf {
            return base.test.negative ? .less : .greater
        }

        if otherInf {
            return other.test.negative ? .greater : .less
        }

        let baseZero = base.test.zero
        let otherZero = other.test.zero

        if baseZero && otherZero {
            return .equal
        }
        if baseZero {
            return other.test.negative ? .greater : .less
        }
        if otherZero {
            return base.test.negative ? .less : .greater
        }

        let baseNeg = base.test.negative
        let otherNeg = other.test.negative

        if baseNeg != otherNeg {
            return baseNeg ? .less : .greater
        }

        let magnitudeOrder = compareMagnitude(other)

        if baseNeg {
            switch magnitudeOrder {
            case .less: return .greater
            case .greater: return .less
            case .equal: return .equal
            case .unordered: return .unordered
            }
        }
        return magnitudeOrder
    }

    @usableFromInline
    internal func compareMagnitude(_ other: Value) -> Decimal.Compare {
        let aCoef = base.extractCoefficient()
        let bCoef = other.extractCoefficient()
        let aExp = base.extractExponent()
        let bExp = other.extractExponent()

        if aExp == bExp {
            if aCoef < bCoef { return .less }
            if aCoef > bCoef { return .greater }
            return .equal
        }

        let diff = aExp.rawValue - bExp.rawValue

        if diff > 34 { return .greater }
        if diff < -34 { return .less }

        if diff > 0 {

            var scaled = aCoef
            for _ in 0..<diff {
                let (result, overflow) = scaled.multipliedReportingOverflow(by: 10)
                if overflow {

                    return .greater
                }
                scaled = result
            }
            if scaled > bCoef { return .greater }
            if scaled < bCoef { return .less }
            return .equal
        } else {

            var scaled = bCoef
            for _ in 0..<(-diff) {
                let (result, overflow) = scaled.multipliedReportingOverflow(by: 10)
                if overflow {

                    return .less
                }
                scaled = result
            }
            if aCoef > scaled { return .greater }
            if aCoef < scaled { return .less }
            return .equal
        }
    }
}
