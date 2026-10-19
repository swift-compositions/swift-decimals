extension Decimal.Operation where Value == Decimal.Format64 {
    public func quantize(
        _ exponent: Decimal.Exponent,
        context: Decimal.Context = .format64
    ) -> Decimal.Outcome<Value> {
        let value = base

        if value.test.signaling {
            return Decimal.Outcome(
                value: .nan(kind: .quiet, payload: Decimal.Payload(UInt64(value.extractCoefficient()))),
                status: .invalid
            )
        }

        if value.test.nan {
            return Decimal.Outcome(value: value, status: .none)
        }

        if value.test.infinite {
            return Decimal.Outcome(value: .nan(), status: .invalid)
        }

        guard exponent.rawValue >= context.minExponent.rawValue, exponent.rawValue <= context.maxExponent.rawValue else {
            return Decimal.Outcome(value: .nan(), status: .invalid)
        }

        let sign = value.sign
        let coefficient = value.extractCoefficient()
        let current = value.extractExponent()

        if current.rawValue >= exponent.rawValue {
            var scaled = coefficient
            for _ in 0..<(current.rawValue - exponent.rawValue) {
                let (next, overflow) = scaled.multipliedReportingOverflow(by: 10)
                guard !overflow, next <= Value.coefficientMax() else {
                    return Decimal.Outcome(value: .nan(), status: .invalid)
                }
                scaled = next
            }
            return Decimal.Outcome(value: Value.encode(sign: sign, exponent: exponent, coefficient: scaled), status: .none)
        }

        let (rounded, inexact) = Decimals.Rounding.drop(
            exponent.rawValue - current.rawValue,
            from: coefficient,
            sign: sign,
            rounding: context.rounding
        )

        guard rounded <= Value.coefficientMax() else {
            return Decimal.Outcome(value: .nan(), status: .invalid)
        }

        return Decimal.Outcome(
            value: Value.encode(sign: sign, exponent: exponent, coefficient: rounded),
            status: inexact ? .inexact : .none
        )
    }
}
