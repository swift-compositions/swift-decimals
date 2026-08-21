extension Decimal.Operation where Value == Decimal.Format32 {
    public func divide(
        _ other: Value,
        context: Decimal.Context = .format32
    ) -> Decimal.Outcome<Value> {
        let a = base
        let b = other

        let resultSign: Decimal.Sign = (a.sign == b.sign) ? .positive : .negative

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
                return Decimal.Outcome(value: .nan(), status: .invalid)
            }
            return Decimal.Outcome(value: .infinity(sign: resultSign), status: .none)
        }

        if b.test.zero {
            if a.test.zero {
                return Decimal.Outcome(value: .nan(), status: .invalid)
            }
            return Decimal.Outcome(value: .infinity(sign: resultSign), status: .divide)
        }

        if a.test.zero {
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }

        if b.test.infinite {
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }

        var coeffA = UInt64(a.extractCoefficient())
        let coeffB = UInt64(b.extractCoefficient())
        var expA = a.extractExponent()
        let expB = b.extractExponent()

        let targetDigits = context.precision.rawValue + 2

        var digitsA = 0
        var temp = coeffA
        while temp > 0 {
            digitsA += 1
            temp /= 10
        }

        let scaleUp = targetDigits + 7 - digitsA
        if scaleUp > 0 {
            for _ in 0..<scaleUp {
                coeffA *= 10
            }

            expA = expA - scaleUp
        }

        let quotient = coeffA / coeffB
        let remainder = coeffA % coeffB

        let resultExp = expA - expB

        var status: Decimal.Status = .none
        if remainder != 0 {
            status = .inexact
        }

        let (finalCoeff, finalExp, roundStatus) = Decimals.Rounding.round(
            coefficient: quotient,
            exponent: resultExp,
            sign: resultSign,
            rounding: context.rounding,
            precision: context.precision,
            sticky: remainder != 0
        )
        status = status.union(roundStatus)

        if finalExp > context.maxExponent {
            return Decimal.Outcome(
                value: .infinity(sign: resultSign),
                status: status.union(Decimal.Status.overflow)
            )
        }

        if finalExp < context.minExponent {
            return Decimal.Outcome(
                value: .zero(sign: resultSign),
                status: status.union(Decimal.Status.underflow)
            )
        }

        let result = Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff)
        return Decimal.Outcome(value: result, status: status)
    }

    public func divide(
        _ other: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try divide(other, context: context).trapped(by: context.traps)
    }
}

extension Decimal.Operation where Value == Decimal.Format64 {
    public func divide(
        _ other: Value,
        context: Decimal.Context = .format64
    ) -> Decimal.Outcome<Value> {
        let a = base
        let b = other

        let resultSign: Decimal.Sign = (a.sign == b.sign) ? .positive : .negative

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

                return Decimal.Outcome(value: .nan(), status: .invalid)
            }
            return Decimal.Outcome(value: .infinity(sign: resultSign), status: .none)
        }

        if b.test.zero {
            if a.test.zero {

                return Decimal.Outcome(value: .nan(), status: .invalid)
            }

            return Decimal.Outcome(value: .infinity(sign: resultSign), status: .divide)
        }

        if a.test.zero {
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }

        if b.test.infinite {
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }

        var coeffA = UInt128(a.extractCoefficient())
        let coeffB = UInt128(b.extractCoefficient())
        var expA = a.extractExponent()
        let expB = b.extractExponent()

        let targetDigits = context.precision.rawValue + 2

        var digitsA = 0
        var temp = coeffA
        while temp > 0 {
            digitsA += 1
            temp /= 10
        }

        let scaleUp = targetDigits + 16 - digitsA
        if scaleUp > 0 {
            for _ in 0..<scaleUp {
                coeffA *= 10
            }

            expA = expA - scaleUp
        }

        let quotient = coeffA / coeffB
        let remainder = coeffA % coeffB

        let resultExp = expA - expB

        var status: Decimal.Status = .none
        if remainder != 0 {
            status = .inexact
        }

        let (finalCoeff, finalExp, roundStatus) = Decimals.Rounding.round(
            coefficient: quotient,
            exponent: resultExp,
            sign: resultSign,
            rounding: context.rounding,
            precision: context.precision,
            sticky: remainder != 0
        )
        status = status.union(roundStatus)

        if finalExp > context.maxExponent {
            return Decimal.Outcome(
                value: .infinity(sign: resultSign),
                status: status.union(Decimal.Status.overflow)
            )
        }

        if finalExp < context.minExponent {
            return Decimal.Outcome(
                value: .zero(sign: resultSign),
                status: status.union(Decimal.Status.underflow)
            )
        }

        let result = Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff)
        return Decimal.Outcome(value: result, status: status)
    }

    public func divide(
        _ other: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try divide(other, context: context).trapped(by: context.traps)
    }
}

extension Decimal.Operation where Value == Decimal.Format128 {
    public func divide(
        _ other: Value,
        context: Decimal.Context = .format128
    ) -> Decimal.Outcome<Value> {
        let a = base
        let b = other

        let resultSign: Decimal.Sign = (a.sign == b.sign) ? .positive : .negative

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
                return Decimal.Outcome(value: .nan(), status: .invalid)
            }
            return Decimal.Outcome(value: .infinity(sign: resultSign), status: .none)
        }

        if b.test.zero {
            if a.test.zero {
                return Decimal.Outcome(value: .nan(), status: .invalid)
            }
            return Decimal.Outcome(value: .infinity(sign: resultSign), status: .divide)
        }

        if a.test.zero {
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }

        if b.test.infinite {
            return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
        }

        var coeffA = a.extractCoefficient()
        let coeffB = b.extractCoefficient()
        var expA = a.extractExponent()
        let expB = b.extractExponent()

        let targetDigits = context.precision.rawValue + 2

        var digitsA = 0
        var temp = coeffA
        while temp > 0 {
            digitsA += 1
            temp /= 10
        }

        let scaleUp = targetDigits + 34 - digitsA
        if scaleUp > 0 {
            for _ in 0..<scaleUp {
                coeffA *= 10
            }

            expA = expA - scaleUp
        }

        let quotient = coeffA / coeffB
        let remainder = coeffA % coeffB

        let resultExp = expA - expB

        var status: Decimal.Status = .none
        if remainder != 0 {
            status = .inexact
        }

        let (finalCoeff, finalExp, roundStatus) = Decimals.Rounding.round128(
            coefficient: quotient,
            exponent: resultExp,
            sign: resultSign,
            rounding: context.rounding,
            precision: context.precision,
            sticky: remainder != 0
        )
        status = status.union(roundStatus)

        if finalExp > context.maxExponent {
            return Decimal.Outcome(
                value: .infinity(sign: resultSign),
                status: status.union(Decimal.Status.overflow)
            )
        }

        if finalExp < context.minExponent {
            return Decimal.Outcome(
                value: .zero(sign: resultSign),
                status: status.union(Decimal.Status.underflow)
            )
        }

        let result = Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff)
        return Decimal.Outcome(value: result, status: status)
    }

    public func divide(
        _ other: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try divide(other, context: context).trapped(by: context.traps)
    }
}
