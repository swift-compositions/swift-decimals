extension Decimal.Operation where Value == Decimal.Format32 {
    public func add(
        _ other: Value,
        context: Decimal.Context = .format32
    ) -> Decimal.Outcome<Value> {
        let a = base
        let b = other

        if a.test.signaling || b.test.signaling {
            let payload =
                a.test.signaling
                ? Decimal.Payload(UInt64(a.extractCoefficient()))
                : Decimal.Payload(UInt64(b.extractCoefficient()))
            return Decimal.Outcome(value: .nan(kind: .quiet, payload: payload), status: .invalid)
        }

        if a.test.nan {
            return Decimal.Outcome(value: a, status: .none)
        }
        if b.test.nan {
            return Decimal.Outcome(value: b, status: .none)
        }

        if a.test.infinite {
            if b.test.infinite {
                if a.sign != b.sign {
                    return Decimal.Outcome(value: .nan(), status: .invalid)
                }
            }
            return Decimal.Outcome(value: a, status: .none)
        }
        if b.test.infinite {
            return Decimal.Outcome(value: b, status: .none)
        }

        if a.test.zero && b.test.zero {
            let resultSign: Decimal.Sign =
                (a.sign == .negative && b.sign == .negative)
                ? .negative : (context.rounding == .floor ? .negative : .positive)
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }
        if a.test.zero {
            return Decimal.Outcome(value: b, status: .none)
        }
        if b.test.zero {
            return Decimal.Outcome(value: a, status: .none)
        }

        let signA = a.sign
        let signB = b.sign
        var coeffA = UInt64(a.extractCoefficient())
        var coeffB = UInt64(b.extractCoefficient())
        var expA = a.extractExponent()
        var expB = b.extractExponent()

        if expA < expB {
            let diff = expB - expA
            var scaled = coeffB
            var shifted = 0
            while shifted < diff.rawValue {
                let (next, overflow) = scaled.multipliedReportingOverflow(by: 10)
                if overflow { break }
                scaled = next
                shifted += 1
            }
            if shifted < diff.rawValue {
                return Decimal.Outcome(value: b, status: .inexact)
            }
            coeffB = scaled
            expB = expA
        } else if expB < expA {
            let diff = expA - expB
            var scaled = coeffA
            var shifted = 0
            while shifted < diff.rawValue {
                let (next, overflow) = scaled.multipliedReportingOverflow(by: 10)
                if overflow { break }
                scaled = next
                shifted += 1
            }
            if shifted < diff.rawValue {
                return Decimal.Outcome(value: a, status: .inexact)
            }
            coeffA = scaled
            expA = expB
        }

        let resultSign: Decimal.Sign
        let resultCoeff: UInt64

        if signA == signB {
            resultSign = signA
            resultCoeff = coeffA + coeffB
        } else {
            if coeffA >= coeffB {
                resultSign = signA
                resultCoeff = coeffA - coeffB
            } else {
                resultSign = signB
                resultCoeff = coeffB - coeffA
            }
        }

        if resultCoeff == 0 {
            let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
            return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
        }

        let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
            coefficient: resultCoeff,
            exponent: expA,
            sign: resultSign,
            rounding: context.rounding,
            precision: context.precision
        )

        if finalExp > context.maxExponent {
            return Decimal.Outcome(
                value: .infinity(sign: resultSign),
                status: status.union(Decimal.Status.overflow)
            )
        }

        let result = Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff)
        return Decimal.Outcome(value: result, status: status)
    }

    public func add(
        _ other: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try add(other, context: context).trapped(by: context.traps)
    }
}

extension Decimal.Operation where Value == Decimal.Format64 {
    public func add(
        _ other: Value,
        context: Decimal.Context = .format64
    ) -> Decimal.Outcome<Value> {
        let a = base
        let b = other

        if a.test.signaling || b.test.signaling {

            let payload =
                a.test.signaling
                ? Decimal.Payload(a.extractCoefficient()) : Decimal.Payload(b.extractCoefficient())
            return Decimal.Outcome(value: .nan(kind: .quiet, payload: payload), status: .invalid)
        }

        if a.test.nan {
            return Decimal.Outcome(value: a, status: .none)
        }
        if b.test.nan {
            return Decimal.Outcome(value: b, status: .none)
        }

        if a.test.infinite {
            if b.test.infinite {

                if a.sign != b.sign {
                    return Decimal.Outcome(value: .nan(), status: .invalid)
                }
            }
            return Decimal.Outcome(value: a, status: .none)
        }
        if b.test.infinite {
            return Decimal.Outcome(value: b, status: .none)
        }

        if a.test.zero && b.test.zero {

            let resultSign: Decimal.Sign =
                (a.sign == .negative && b.sign == .negative)
                ? .negative : (context.rounding == .floor ? .negative : .positive)
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }
        if a.test.zero {
            return Decimal.Outcome(value: b, status: .none)
        }
        if b.test.zero {
            return Decimal.Outcome(value: a, status: .none)
        }

        let signA = a.sign
        let signB = b.sign
        var coeffA = UInt128(a.extractCoefficient())
        var coeffB = UInt128(b.extractCoefficient())
        var expA = a.extractExponent()
        var expB = b.extractExponent()

        if expA < expB {
            let diff = expB - expA
            var scaled = coeffB
            var shifted = 0
            while shifted < diff.rawValue {
                let (next, overflow) = scaled.multipliedReportingOverflow(by: 10)
                if overflow { break }
                scaled = next
                shifted += 1
            }
            if shifted < diff.rawValue {

                return Decimal.Outcome(value: b, status: .inexact)
            }
            coeffB = scaled
            expB = expA
        } else if expB < expA {
            let diff = expA - expB
            var scaled = coeffA
            var shifted = 0
            while shifted < diff.rawValue {
                let (next, overflow) = scaled.multipliedReportingOverflow(by: 10)
                if overflow { break }
                scaled = next
                shifted += 1
            }
            if shifted < diff.rawValue {

                return Decimal.Outcome(value: a, status: .inexact)
            }
            coeffA = scaled
            expA = expB
        }

        let resultSign: Decimal.Sign
        let resultCoeff: UInt128

        if signA == signB {

            resultSign = signA
            resultCoeff = coeffA + coeffB
        } else {

            if coeffA >= coeffB {
                resultSign = signA
                resultCoeff = coeffA - coeffB
            } else {
                resultSign = signB
                resultCoeff = coeffB - coeffA
            }
        }

        if resultCoeff == 0 {
            let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
            return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
        }

        let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
            coefficient: resultCoeff,
            exponent: expA,
            sign: resultSign,
            rounding: context.rounding,
            precision: context.precision
        )

        if finalExp > context.maxExponent {
            return Decimal.Outcome(
                value: .infinity(sign: resultSign),
                status: status.union(Decimal.Status.overflow)
            )
        }

        let result = Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff)
        return Decimal.Outcome(value: result, status: status)
    }

    public func add(
        _ other: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try add(other, context: context).trapped(by: context.traps)
    }
}

extension Decimal.Operation where Value == Decimal.Format128 {
    public func add(
        _ other: Value,
        context: Decimal.Context = .format128
    ) -> Decimal.Outcome<Value> {
        let a = base
        let b = other

        if a.test.signaling || b.test.signaling {
            let payload =
                a.test.signaling
                ? Decimal.Payload(UInt64(truncatingIfNeeded: a.extractCoefficient()))
                : Decimal.Payload(UInt64(truncatingIfNeeded: b.extractCoefficient()))
            return Decimal.Outcome(value: .nan(kind: .quiet, payload: payload), status: .invalid)
        }

        if a.test.nan {
            return Decimal.Outcome(value: a, status: .none)
        }
        if b.test.nan {
            return Decimal.Outcome(value: b, status: .none)
        }

        if a.test.infinite {
            if b.test.infinite {
                if a.sign != b.sign {
                    return Decimal.Outcome(value: .nan(), status: .invalid)
                }
            }
            return Decimal.Outcome(value: a, status: .none)
        }
        if b.test.infinite {
            return Decimal.Outcome(value: b, status: .none)
        }

        if a.test.zero && b.test.zero {
            let resultSign: Decimal.Sign =
                (a.sign == .negative && b.sign == .negative)
                ? .negative : (context.rounding == .floor ? .negative : .positive)
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }
        if a.test.zero {
            return Decimal.Outcome(value: b, status: .none)
        }
        if b.test.zero {
            return Decimal.Outcome(value: a, status: .none)
        }

        let signA = a.sign
        let signB = b.sign
        let coeffA = a.extractCoefficient()
        let coeffB = b.extractCoefficient()
        let expA = a.extractExponent()
        let expB = b.extractExponent()

        if expA < expB {
            let diff = expB - expA
            let digitsFar = Decimals.Rounding.digitCount(coeffA)
            let digitsNear = Decimals.Rounding.digitCount(coeffB)
            let threshold = context.precision.rawValue + digitsFar - digitsNear + 1
            if diff.rawValue <= threshold {
                let scaledB = Decimals.Wide.multiplied(
                    Decimals.Wide(coeffB),
                    byPowerOf10: diff.rawValue
                )
                let wideA = Decimals.Wide(coeffA)
                let resultSign: Decimal.Sign
                let wideSum: Decimals.Wide
                if signA == signB {
                    resultSign = signA
                    wideSum = wideA.adding(scaledB)
                } else if wideA >= scaledB {
                    resultSign = signA
                    wideSum = wideA.subtracting(scaledB)
                } else {
                    resultSign = signB
                    wideSum = scaledB.subtracting(wideA)
                }
                if wideSum.isZero {
                    let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
                    return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
                }
                let (reduced, shift, sticky) = wideSum.reducedToFitUInt128()
                let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                    coefficient: reduced,
                    exponent: expA + shift,
                    sign: resultSign,
                    rounding: context.rounding,
                    precision: context.precision,
                    sticky: sticky
                )
                if finalExp > context.maxExponent {
                    return Decimal.Outcome(
                        value: .infinity(sign: resultSign),
                        status: status.union(Decimal.Status.overflow)
                    )
                }
                return Decimal.Outcome(
                    value: Value.encode(
                        sign: resultSign,
                        exponent: finalExp,
                        coefficient: finalCoeff
                    ),
                    status: status
                )
            }
            let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                coefficient: coeffB,
                exponent: expB,
                sign: signB,
                rounding: context.rounding,
                precision: context.precision,
                sticky: true
            )
            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: signB),
                    status: status.union(Decimal.Status.overflow)
                )
            }
            return Decimal.Outcome(
                value: Value.encode(sign: signB, exponent: finalExp, coefficient: finalCoeff),
                status: status
            )
        } else if expB < expA {
            let diff = expA - expB
            let digitsFar = Decimals.Rounding.digitCount(coeffB)
            let digitsNear = Decimals.Rounding.digitCount(coeffA)
            let threshold = context.precision.rawValue + digitsFar - digitsNear + 1
            if diff.rawValue <= threshold {
                let scaledA = Decimals.Wide.multiplied(
                    Decimals.Wide(coeffA),
                    byPowerOf10: diff.rawValue
                )
                let wideB = Decimals.Wide(coeffB)
                let resultSign: Decimal.Sign
                let wideSum: Decimals.Wide
                if signA == signB {
                    resultSign = signA
                    wideSum = scaledA.adding(wideB)
                } else if scaledA >= wideB {
                    resultSign = signA
                    wideSum = scaledA.subtracting(wideB)
                } else {
                    resultSign = signB
                    wideSum = wideB.subtracting(scaledA)
                }
                if wideSum.isZero {
                    let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
                    return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
                }
                let (reduced, shift, sticky) = wideSum.reducedToFitUInt128()
                let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                    coefficient: reduced,
                    exponent: expB + shift,
                    sign: resultSign,
                    rounding: context.rounding,
                    precision: context.precision,
                    sticky: sticky
                )
                if finalExp > context.maxExponent {
                    return Decimal.Outcome(
                        value: .infinity(sign: resultSign),
                        status: status.union(Decimal.Status.overflow)
                    )
                }
                return Decimal.Outcome(
                    value: Value.encode(
                        sign: resultSign,
                        exponent: finalExp,
                        coefficient: finalCoeff
                    ),
                    status: status
                )
            }
            let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                coefficient: coeffA,
                exponent: expA,
                sign: signA,
                rounding: context.rounding,
                precision: context.precision,
                sticky: true
            )
            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: signA),
                    status: status.union(Decimal.Status.overflow)
                )
            }
            return Decimal.Outcome(
                value: Value.encode(sign: signA, exponent: finalExp, coefficient: finalCoeff),
                status: status
            )
        }

        let resultSign: Decimal.Sign
        let resultCoeff: UInt128

        if signA == signB {
            resultSign = signA
            resultCoeff = coeffA + coeffB
        } else {
            if coeffA >= coeffB {
                resultSign = signA
                resultCoeff = coeffA - coeffB
            } else {
                resultSign = signB
                resultCoeff = coeffB - coeffA
            }
        }

        if resultCoeff == 0 {
            let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
            return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
        }

        let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
            coefficient: resultCoeff,
            exponent: expA,
            sign: resultSign,
            rounding: context.rounding,
            precision: context.precision
        )

        if finalExp > context.maxExponent {
            return Decimal.Outcome(
                value: .infinity(sign: resultSign),
                status: status.union(Decimal.Status.overflow)
            )
        }

        let result = Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff)
        return Decimal.Outcome(value: result, status: status)
    }

    public func add(
        _ other: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try add(other, context: context).trapped(by: context.traps)
    }
}
