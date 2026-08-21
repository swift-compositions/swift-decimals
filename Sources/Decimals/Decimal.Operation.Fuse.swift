extension Decimal.Operation where Value == Decimal.Format64 {

    public func fuse(
        _ a: Value,
        _ b: Value,
        context: Decimal.Context = .format64
    ) -> Decimal.Outcome<Value> {
        let x = base
        let y = a
        let z = b

        if x.test.signaling || y.test.signaling || z.test.signaling {
            let payload: Decimal.Payload
            if x.test.signaling {
                payload = Decimal.Payload(x.extractCoefficient())
            } else if y.test.signaling {
                payload = Decimal.Payload(y.extractCoefficient())
            } else {
                payload = Decimal.Payload(z.extractCoefficient())
            }
            return Decimal.Outcome(value: .nan(kind: .quiet, payload: payload), status: .invalid)
        }

        if x.test.nan { return Decimal.Outcome(value: x, status: .none) }
        if y.test.nan { return Decimal.Outcome(value: y, status: .none) }
        if z.test.nan { return Decimal.Outcome(value: z, status: .none) }

        if (x.test.infinite && y.test.zero) || (x.test.zero && y.test.infinite) {
            return Decimal.Outcome(value: .nan(), status: .invalid)
        }

        let productSign: Decimal.Sign = (x.sign == y.sign) ? .positive : .negative

        if x.test.infinite || y.test.infinite {
            if z.test.infinite {

                if productSign != z.sign {
                    return Decimal.Outcome(value: .nan(), status: .invalid)
                }
            }
            return Decimal.Outcome(value: .infinity(sign: productSign), status: .none)
        }

        if z.test.infinite {
            return Decimal.Outcome(value: z, status: .none)
        }

        if x.test.zero || y.test.zero {
            if z.test.zero {
                let resultSign: Decimal.Sign =
                    (productSign == .negative && z.sign == .negative)
                    ? .negative : (context.rounding == .floor ? .negative : .positive)
                return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
            }
            return Decimal.Outcome(value: z, status: .none)
        }

        let coeffX = UInt128(x.extractCoefficient())
        let coeffY = UInt128(y.extractCoefficient())
        let expX = x.extractExponent()
        let expY = y.extractExponent()

        let productCoeff = coeffX * coeffY
        let productExp = expX + expY

        if z.test.zero {

            let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                coefficient: productCoeff,
                exponent: productExp,
                sign: productSign,
                rounding: context.rounding,
                precision: context.precision
            )

            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: productSign),
                    status: status.union(Decimal.Status.overflow)
                )
            }

            return Decimal.Outcome(
                value: Value.encode(sign: productSign, exponent: finalExp, coefficient: finalCoeff),
                status: status
            )
        }

        let pCoeff = productCoeff
        let pExp = productExp
        let zCoeff = UInt128(z.extractCoefficient())
        let zExp = z.extractExponent()

        if pExp < zExp {
            let diff = zExp - pExp
            let digitsFar = Decimals.Rounding.digitCount(pCoeff)
            let digitsNear = Decimals.Rounding.digitCount(zCoeff)
            let threshold = context.precision.rawValue + digitsFar - digitsNear + 1
            if diff.rawValue <= threshold {
                let scaledZ = Decimals.Wide.multiplied(
                    Decimals.Wide(zCoeff),
                    byPowerOf10: diff.rawValue
                )
                let wideP = Decimals.Wide(pCoeff)
                let resultSign: Decimal.Sign
                let wideSum: Decimals.Wide
                if productSign == z.sign {
                    resultSign = productSign
                    wideSum = wideP.adding(scaledZ)
                } else if wideP >= scaledZ {
                    resultSign = productSign
                    wideSum = wideP.subtracting(scaledZ)
                } else {
                    resultSign = z.sign
                    wideSum = scaledZ.subtracting(wideP)
                }
                if wideSum.isZero {
                    let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
                    return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
                }
                let (reduced, shift, sticky) = wideSum.reducedToFitUInt128()
                let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                    coefficient: reduced,
                    exponent: pExp + shift,
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

            let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                coefficient: zCoeff,
                exponent: zExp,
                sign: z.sign,
                rounding: context.rounding,
                precision: context.precision,
                sticky: true
            )
            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: z.sign),
                    status: status.union(Decimal.Status.overflow)
                )
            }
            return Decimal.Outcome(
                value: Value.encode(sign: z.sign, exponent: finalExp, coefficient: finalCoeff),
                status: status
            )
        } else if zExp < pExp {
            let diff = pExp - zExp
            let digitsFar = Decimals.Rounding.digitCount(zCoeff)
            let digitsNear = Decimals.Rounding.digitCount(pCoeff)
            let threshold = context.precision.rawValue + digitsFar - digitsNear + 1

            let sameSign = productSign == z.sign
            let effectiveThreshold = max(threshold, digitsFar)
            if diff.rawValue <= effectiveThreshold {
                let scaledP = Decimals.Wide.multiplied(
                    Decimals.Wide(pCoeff),
                    byPowerOf10: diff.rawValue
                )
                let wideZ = Decimals.Wide(zCoeff)
                let resultSign: Decimal.Sign
                let wideSum: Decimals.Wide
                if productSign == z.sign {
                    resultSign = productSign
                    wideSum = scaledP.adding(wideZ)
                } else if scaledP >= wideZ {
                    resultSign = productSign
                    wideSum = scaledP.subtracting(wideZ)
                } else {
                    resultSign = z.sign
                    wideSum = wideZ.subtracting(scaledP)
                }
                if wideSum.isZero {
                    let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
                    return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
                }
                let (reduced, shift, sticky) = wideSum.reducedToFitUInt128()
                let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                    coefficient: reduced,
                    exponent: zExp + shift,
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
            if sameSign {

                let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                    coefficient: productCoeff,
                    exponent: productExp,
                    sign: productSign,
                    rounding: context.rounding,
                    precision: context.precision,
                    sticky: true
                )
                if finalExp > context.maxExponent {
                    return Decimal.Outcome(
                        value: .infinity(sign: productSign),
                        status: status.union(Decimal.Status.overflow).union(.inexact)
                    )
                }
                return Decimal.Outcome(
                    value: Value.encode(
                        sign: productSign,
                        exponent: finalExp,
                        coefficient: finalCoeff
                    ),
                    status: status.union(.inexact)
                )
            }

            if digitsNear <= context.precision.rawValue {
                if productExp > context.maxExponent {
                    return Decimal.Outcome(
                        value: .infinity(sign: productSign),
                        status: Decimal.Status.overflow.union(.inexact)
                    )
                }
                return Decimal.Outcome(
                    value: Value.encode(
                        sign: productSign,
                        exponent: productExp,
                        coefficient: UInt64(productCoeff)
                    ),
                    status: .inexact
                )
            }

            let extendedCoeff = productCoeff * 10 - 1
            let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                coefficient: extendedCoeff,
                exponent: productExp - 1,
                sign: productSign,
                rounding: context.rounding,
                precision: context.precision,
                sticky: true
            )
            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: productSign),
                    status: status.union(Decimal.Status.overflow).union(.inexact)
                )
            }
            return Decimal.Outcome(
                value: Value.encode(sign: productSign, exponent: finalExp, coefficient: finalCoeff),
                status: status.union(.inexact)
            )
        }

        let resultSign: Decimal.Sign
        let resultCoeff: UInt128

        if productSign == z.sign {
            resultSign = productSign
            resultCoeff = pCoeff + zCoeff
        } else {
            if pCoeff >= zCoeff {
                resultSign = productSign
                resultCoeff = pCoeff - zCoeff
            } else {
                resultSign = z.sign
                resultCoeff = zCoeff - pCoeff
            }
        }

        if resultCoeff == 0 {
            let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
            return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
        }

        let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
            coefficient: resultCoeff,
            exponent: pExp,
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

        return Decimal.Outcome(
            value: Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff),
            status: status
        )
    }

    public func fuse(
        _ a: Value,
        _ b: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try fuse(a, b, context: context).trapped(by: context.traps)
    }
}

extension Decimal.Operation where Value == Decimal.Format32 {

    public func fuse(
        _ a: Value,
        _ b: Value,
        context: Decimal.Context = .format32
    ) -> Decimal.Outcome<Value> {
        let x = base
        let y = a
        let z = b

        if x.test.signaling || y.test.signaling || z.test.signaling {
            let payload: Decimal.Payload
            if x.test.signaling {
                payload = Decimal.Payload(UInt64(x.extractCoefficient()))
            } else if y.test.signaling {
                payload = Decimal.Payload(UInt64(y.extractCoefficient()))
            } else {
                payload = Decimal.Payload(UInt64(z.extractCoefficient()))
            }
            return Decimal.Outcome(value: .nan(kind: .quiet, payload: payload), status: .invalid)
        }

        if x.test.nan { return Decimal.Outcome(value: x, status: .none) }
        if y.test.nan { return Decimal.Outcome(value: y, status: .none) }
        if z.test.nan { return Decimal.Outcome(value: z, status: .none) }

        if (x.test.infinite && y.test.zero) || (x.test.zero && y.test.infinite) {
            return Decimal.Outcome(value: .nan(), status: .invalid)
        }

        let productSign: Decimal.Sign = (x.sign == y.sign) ? .positive : .negative

        if x.test.infinite || y.test.infinite {
            if z.test.infinite {
                if productSign != z.sign {
                    return Decimal.Outcome(value: .nan(), status: .invalid)
                }
            }
            return Decimal.Outcome(value: .infinity(sign: productSign), status: .none)
        }

        if z.test.infinite {
            return Decimal.Outcome(value: z, status: .none)
        }

        if x.test.zero || y.test.zero {
            if z.test.zero {
                let resultSign: Decimal.Sign =
                    (productSign == .negative && z.sign == .negative)
                    ? .negative : (context.rounding == .floor ? .negative : .positive)
                return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
            }
            return Decimal.Outcome(value: z, status: .none)
        }

        let coeffX = UInt64(x.extractCoefficient())
        let coeffY = UInt64(y.extractCoefficient())
        let expX = x.extractExponent()
        let expY = y.extractExponent()

        let productCoeff = coeffX * coeffY
        let productExp = expX + expY

        if z.test.zero {
            let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                coefficient: productCoeff,
                exponent: productExp,
                sign: productSign,
                rounding: context.rounding,
                precision: context.precision
            )

            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: productSign),
                    status: status.union(Decimal.Status.overflow)
                )
            }

            return Decimal.Outcome(
                value: Value.encode(sign: productSign, exponent: finalExp, coefficient: finalCoeff),
                status: status
            )
        }

        let zCoeff = UInt64(z.extractCoefficient())
        let zExp = z.extractExponent()

        if productExp < zExp {
            let diff = zExp - productExp
            let digitsFar = Decimals.Rounding.digitCount(productCoeff)
            let digitsNear = Decimals.Rounding.digitCount(zCoeff)
            let threshold = context.precision.rawValue + digitsFar - digitsNear + 1
            if diff.rawValue <= threshold {
                let scaledZ = Decimals.Wide.multiplied(
                    Decimals.Wide(UInt128(zCoeff)),
                    byPowerOf10: diff.rawValue
                )
                let wideP = Decimals.Wide(UInt128(productCoeff))
                let resultSign: Decimal.Sign
                let wideSum: Decimals.Wide
                if productSign == z.sign {
                    resultSign = productSign
                    wideSum = wideP.adding(scaledZ)
                } else if wideP >= scaledZ {
                    resultSign = productSign
                    wideSum = wideP.subtracting(scaledZ)
                } else {
                    resultSign = z.sign
                    wideSum = scaledZ.subtracting(wideP)
                }
                if wideSum.isZero {
                    let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
                    return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
                }
                let (reduced, shift, sticky) = wideSum.reduced(
                    toFitBelowOrEqual: UInt128(UInt64.max)
                )
                let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                    coefficient: UInt64(reduced),
                    exponent: productExp + shift,
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

            let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                coefficient: zCoeff,
                exponent: zExp,
                sign: z.sign,
                rounding: context.rounding,
                precision: context.precision,
                sticky: true
            )
            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: z.sign),
                    status: status.union(Decimal.Status.overflow)
                )
            }
            return Decimal.Outcome(
                value: Value.encode(sign: z.sign, exponent: finalExp, coefficient: finalCoeff),
                status: status
            )
        } else if zExp < productExp {
            let diff = productExp - zExp
            let digitsFar = Decimals.Rounding.digitCount(zCoeff)
            let digitsNear = Decimals.Rounding.digitCount(productCoeff)
            let threshold = context.precision.rawValue + digitsFar - digitsNear + 1

            let sameSign = productSign == z.sign
            let effectiveThreshold = max(threshold, digitsFar)
            if diff.rawValue <= effectiveThreshold {
                let scaledP = Decimals.Wide.multiplied(
                    Decimals.Wide(UInt128(productCoeff)),
                    byPowerOf10: diff.rawValue
                )
                let wideZ = Decimals.Wide(UInt128(zCoeff))
                let resultSign: Decimal.Sign
                let wideSum: Decimals.Wide
                if productSign == z.sign {
                    resultSign = productSign
                    wideSum = scaledP.adding(wideZ)
                } else if scaledP >= wideZ {
                    resultSign = productSign
                    wideSum = scaledP.subtracting(wideZ)
                } else {
                    resultSign = z.sign
                    wideSum = wideZ.subtracting(scaledP)
                }
                if wideSum.isZero {
                    let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
                    return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
                }
                let (reduced, shift, sticky) = wideSum.reduced(
                    toFitBelowOrEqual: UInt128(UInt64.max)
                )
                let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                    coefficient: UInt64(reduced),
                    exponent: zExp + shift,
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
            if sameSign {

                let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                    coefficient: productCoeff,
                    exponent: productExp,
                    sign: productSign,
                    rounding: context.rounding,
                    precision: context.precision,
                    sticky: true
                )
                if finalExp > context.maxExponent {
                    return Decimal.Outcome(
                        value: .infinity(sign: productSign),
                        status: status.union(Decimal.Status.overflow).union(.inexact)
                    )
                }
                return Decimal.Outcome(
                    value: Value.encode(
                        sign: productSign,
                        exponent: finalExp,
                        coefficient: finalCoeff
                    ),
                    status: status.union(.inexact)
                )
            }

            if digitsNear <= context.precision.rawValue {
                if productExp > context.maxExponent {
                    return Decimal.Outcome(
                        value: .infinity(sign: productSign),
                        status: Decimal.Status.overflow.union(.inexact)
                    )
                }
                return Decimal.Outcome(
                    value: Value.encode(
                        sign: productSign,
                        exponent: productExp,
                        coefficient: UInt32(productCoeff)
                    ),
                    status: .inexact
                )
            }
            let extendedCoeff = productCoeff * 10 - 1
            let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
                coefficient: extendedCoeff,
                exponent: productExp - 1,
                sign: productSign,
                rounding: context.rounding,
                precision: context.precision,
                sticky: true
            )
            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: productSign),
                    status: status.union(Decimal.Status.overflow).union(.inexact)
                )
            }
            return Decimal.Outcome(
                value: Value.encode(sign: productSign, exponent: finalExp, coefficient: finalCoeff),
                status: status.union(.inexact)
            )
        }

        let resultSign: Decimal.Sign
        let resultCoeff: UInt64

        if productSign == z.sign {
            resultSign = productSign
            resultCoeff = productCoeff + zCoeff
        } else {
            if productCoeff >= zCoeff {
                resultSign = productSign
                resultCoeff = productCoeff - zCoeff
            } else {
                resultSign = z.sign
                resultCoeff = zCoeff - productCoeff
            }
        }

        if resultCoeff == 0 {
            let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
            return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
        }

        let (finalCoeff, finalExp, status) = Decimals.Rounding.round(
            coefficient: resultCoeff,
            exponent: productExp,
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

        return Decimal.Outcome(
            value: Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff),
            status: status
        )
    }

    public func fuse(
        _ a: Value,
        _ b: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try fuse(a, b, context: context).trapped(by: context.traps)
    }
}

extension Decimal.Operation where Value == Decimal.Format128 {

    public func fuse(
        _ a: Value,
        _ b: Value,
        context: Decimal.Context = .format128
    ) -> Decimal.Outcome<Value> {
        let x = base
        let y = a
        let z = b

        if x.test.signaling || y.test.signaling || z.test.signaling {
            let payload: Decimal.Payload
            if x.test.signaling {
                payload = Decimal.Payload(UInt64(truncatingIfNeeded: x.extractCoefficient()))
            } else if y.test.signaling {
                payload = Decimal.Payload(UInt64(truncatingIfNeeded: y.extractCoefficient()))
            } else {
                payload = Decimal.Payload(UInt64(truncatingIfNeeded: z.extractCoefficient()))
            }
            return Decimal.Outcome(value: .nan(kind: .quiet, payload: payload), status: .invalid)
        }

        if x.test.nan { return Decimal.Outcome(value: x, status: .none) }
        if y.test.nan { return Decimal.Outcome(value: y, status: .none) }
        if z.test.nan { return Decimal.Outcome(value: z, status: .none) }

        if (x.test.infinite && y.test.zero) || (x.test.zero && y.test.infinite) {
            return Decimal.Outcome(value: .nan(), status: .invalid)
        }

        let productSign: Decimal.Sign = (x.sign == y.sign) ? .positive : .negative

        if x.test.infinite || y.test.infinite {
            if z.test.infinite {
                if productSign != z.sign {
                    return Decimal.Outcome(value: .nan(), status: .invalid)
                }
            }
            return Decimal.Outcome(value: .infinity(sign: productSign), status: .none)
        }

        if z.test.infinite {
            return Decimal.Outcome(value: z, status: .none)
        }

        if x.test.zero || y.test.zero {
            if z.test.zero {
                let resultSign: Decimal.Sign =
                    (productSign == .negative && z.sign == .negative)
                    ? .negative : (context.rounding == .floor ? .negative : .positive)
                return Decimal.Outcome(value: .zero(sign: resultSign), status: .none)
            }
            return Decimal.Outcome(value: z, status: .none)
        }

        let coeffX = x.extractCoefficient()
        let coeffY = y.extractCoefficient()
        let expX = x.extractExponent()
        let expY = y.extractExponent()

        let productCoeff = coeffX * coeffY
        let productExp = expX + expY

        if z.test.zero {
            let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                coefficient: productCoeff,
                exponent: productExp,
                sign: productSign,
                rounding: context.rounding,
                precision: context.precision
            )

            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: productSign),
                    status: status.union(Decimal.Status.overflow)
                )
            }

            return Decimal.Outcome(
                value: Value.encode(sign: productSign, exponent: finalExp, coefficient: finalCoeff),
                status: status
            )
        }

        let zCoeff = z.extractCoefficient()
        let zExp = z.extractExponent()

        if productExp < zExp {
            let diff = zExp - productExp
            let digitsFar = Decimals.Rounding.digitCount(productCoeff)
            let digitsNear = Decimals.Rounding.digitCount(zCoeff)
            let threshold = context.precision.rawValue + digitsFar - digitsNear + 1
            if diff.rawValue <= threshold {
                let scaledZ = Decimals.Wide.multiplied(
                    Decimals.Wide(zCoeff),
                    byPowerOf10: diff.rawValue
                )
                let wideP = Decimals.Wide(productCoeff)
                let resultSign: Decimal.Sign
                let wideSum: Decimals.Wide
                if productSign == z.sign {
                    resultSign = productSign
                    wideSum = wideP.adding(scaledZ)
                } else if wideP >= scaledZ {
                    resultSign = productSign
                    wideSum = wideP.subtracting(scaledZ)
                } else {
                    resultSign = z.sign
                    wideSum = scaledZ.subtracting(wideP)
                }
                if wideSum.isZero {
                    let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
                    return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
                }
                let (reduced, shift, sticky) = wideSum.reducedToFitUInt128()
                let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                    coefficient: reduced,
                    exponent: productExp + shift,
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
                coefficient: zCoeff,
                exponent: zExp,
                sign: z.sign,
                rounding: context.rounding,
                precision: context.precision,
                sticky: true
            )
            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: z.sign),
                    status: status.union(Decimal.Status.overflow)
                )
            }
            return Decimal.Outcome(
                value: Value.encode(sign: z.sign, exponent: finalExp, coefficient: finalCoeff),
                status: status
            )
        } else if zExp < productExp {
            let diff = productExp - zExp
            let digitsFar = Decimals.Rounding.digitCount(zCoeff)
            let digitsNear = Decimals.Rounding.digitCount(productCoeff)
            let threshold = context.precision.rawValue + digitsFar - digitsNear + 1

            let sameSign = productSign == z.sign
            let effectiveThreshold = max(threshold, digitsFar)
            if diff.rawValue <= effectiveThreshold {
                let scaledP = Decimals.Wide.multiplied(
                    Decimals.Wide(productCoeff),
                    byPowerOf10: diff.rawValue
                )
                let wideZ = Decimals.Wide(zCoeff)
                let resultSign: Decimal.Sign
                let wideSum: Decimals.Wide
                if productSign == z.sign {
                    resultSign = productSign
                    wideSum = scaledP.adding(wideZ)
                } else if scaledP >= wideZ {
                    resultSign = productSign
                    wideSum = scaledP.subtracting(wideZ)
                } else {
                    resultSign = z.sign
                    wideSum = wideZ.subtracting(scaledP)
                }
                if wideSum.isZero {
                    let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
                    return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
                }
                let (reduced, shift, sticky) = wideSum.reducedToFitUInt128()
                let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                    coefficient: reduced,
                    exponent: zExp + shift,
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
            if sameSign {

                let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                    coefficient: productCoeff,
                    exponent: productExp,
                    sign: productSign,
                    rounding: context.rounding,
                    precision: context.precision,
                    sticky: true
                )
                if finalExp > context.maxExponent {
                    return Decimal.Outcome(
                        value: .infinity(sign: productSign),
                        status: status.union(Decimal.Status.overflow).union(.inexact)
                    )
                }
                return Decimal.Outcome(
                    value: Value.encode(
                        sign: productSign,
                        exponent: finalExp,
                        coefficient: finalCoeff
                    ),
                    status: status.union(.inexact)
                )
            }

            if digitsNear <= context.precision.rawValue {
                if productExp > context.maxExponent {
                    return Decimal.Outcome(
                        value: .infinity(sign: productSign),
                        status: Decimal.Status.overflow.union(.inexact)
                    )
                }
                return Decimal.Outcome(
                    value: Value.encode(
                        sign: productSign,
                        exponent: productExp,
                        coefficient: productCoeff
                    ),
                    status: .inexact
                )
            }
            let extendedWide = Decimals.Wide(productCoeff).multipliedBy10().subtracting(
                Decimals.Wide(UInt128(1))
            )
            let (reducedCoeff, reduceShift, _) = extendedWide.reducedToFitUInt128()
            let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
                coefficient: reducedCoeff,
                exponent: productExp - 1 + reduceShift,
                sign: productSign,
                rounding: context.rounding,
                precision: context.precision,
                sticky: true
            )
            if finalExp > context.maxExponent {
                return Decimal.Outcome(
                    value: .infinity(sign: productSign),
                    status: status.union(Decimal.Status.overflow).union(.inexact)
                )
            }
            return Decimal.Outcome(
                value: Value.encode(sign: productSign, exponent: finalExp, coefficient: finalCoeff),
                status: status.union(.inexact)
            )
        }

        let resultSign: Decimal.Sign
        let resultCoeff: UInt128

        if productSign == z.sign {
            resultSign = productSign
            resultCoeff = productCoeff + zCoeff
        } else {
            if productCoeff >= zCoeff {
                resultSign = productSign
                resultCoeff = productCoeff - zCoeff
            } else {
                resultSign = z.sign
                resultCoeff = zCoeff - productCoeff
            }
        }

        if resultCoeff == 0 {
            let zeroSign: Decimal.Sign = context.rounding == .floor ? .negative : .positive
            return Decimal.Outcome(value: .zero(sign: zeroSign), status: .none)
        }

        let (finalCoeff, finalExp, status) = Decimals.Rounding.round128(
            coefficient: resultCoeff,
            exponent: productExp,
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

        return Decimal.Outcome(
            value: Value.encode(sign: resultSign, exponent: finalExp, coefficient: finalCoeff),
            status: status
        )
    }

    public func fuse(
        _ a: Value,
        _ b: Value,
        trapping context: Decimal.Context
    ) throws(Decimal.Trap<Value>) -> Value {
        try fuse(a, b, context: context).trapped(by: context.traps)
    }
}
