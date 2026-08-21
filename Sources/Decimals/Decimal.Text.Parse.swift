extension Decimal.Text.Parse where Value == Decimal.Format64 {

    public func callAsFunction(
        _ bytes: UnsafeBufferPointer<UInt8>,
        context: Decimal.Context = .format64
    ) throws(Decimal.Text.Error) -> Value {
        guard !bytes.isEmpty else {
            throw .empty
        }

        var index = 0

        var sign: Decimal.Sign = .positive
        if index < bytes.count {
            if unsafe bytes[index] == UInt8(ascii: "-") {
                sign = .negative
                index += 1
            } else if unsafe bytes[index] == UInt8(ascii: "+") {
                index += 1
            }
        }

        guard index < bytes.count else {
            throw .syntax(offset: index)
        }

        let remaining = bytes.count - index

        if remaining >= 3 {
            let i = unsafe bytes[index]
            let n = unsafe bytes[index + 1]
            let f = unsafe bytes[index + 2]
            if (i == UInt8(ascii: "I") || i == UInt8(ascii: "i"))
                && (n == UInt8(ascii: "n") || n == UInt8(ascii: "N"))
                && (f == UInt8(ascii: "f") || f == UInt8(ascii: "F"))
            {

                if remaining >= 8 {

                    let rest = unsafe [
                        bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6],
                        bytes[index + 7],
                    ]
                    if (rest[0] == UInt8(ascii: "i") || rest[0] == UInt8(ascii: "I"))
                        && (rest[1] == UInt8(ascii: "n") || rest[1] == UInt8(ascii: "N"))
                        && (rest[2] == UInt8(ascii: "i") || rest[2] == UInt8(ascii: "I"))
                        && (rest[3] == UInt8(ascii: "t") || rest[3] == UInt8(ascii: "T"))
                        && (rest[4] == UInt8(ascii: "y") || rest[4] == UInt8(ascii: "Y"))
                    {
                        if index + 8 == bytes.count {
                            return .infinity(sign: sign)
                        }
                    }
                }
                if index + 3 == bytes.count {
                    return .infinity(sign: sign)
                }
            }
        }

        if remaining >= 3 {
            let n1 = unsafe bytes[index]
            let a = unsafe bytes[index + 1]
            let n2 = unsafe bytes[index + 2]
            if (n1 == UInt8(ascii: "N") || n1 == UInt8(ascii: "n"))
                && (a == UInt8(ascii: "a") || a == UInt8(ascii: "A"))
                && (n2 == UInt8(ascii: "N") || n2 == UInt8(ascii: "n"))
            {
                guard index + 3 == bytes.count else {
                    throw .syntax(offset: index + 3)
                }
                let nan = Value.nan()
                return sign == .negative ? nan.negated : nan
            }
        }

        var coefficient: UInt64 = 0
        var exponent: Int = 0
        var hasDigits = false
        var decimalPos: Int? = nil
        var digitCount = 0

        while index < bytes.count {
            let byte = unsafe bytes[index]

            if byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9") {
                hasDigits = true
                let digit = UInt64(byte - UInt8(ascii: "0"))

                if digitCount < 19 {
                    coefficient = coefficient * 10 + digit
                    digitCount += 1
                } else {

                    if decimalPos == nil {
                        exponent += 1
                    }
                }
                index += 1
            } else if byte == UInt8(ascii: ".") {
                if decimalPos != nil {
                    throw .syntax(offset: index)
                }
                decimalPos = digitCount
                index += 1
            } else {
                break
            }
        }

        guard hasDigits else {
            throw .syntax(offset: index)
        }

        if let dp = decimalPos {
            exponent -= (digitCount - dp)
        }

        if index < bytes.count {
            let byte = unsafe bytes[index]
            if byte == UInt8(ascii: "E") || byte == UInt8(ascii: "e") {
                index += 1

                guard index < bytes.count else {
                    throw .syntax(offset: index)
                }

                var expSign = 1
                if unsafe bytes[index] == UInt8(ascii: "-") {
                    expSign = -1
                    index += 1
                } else if unsafe bytes[index] == UInt8(ascii: "+") {
                    index += 1
                }

                guard index < bytes.count else {
                    throw .syntax(offset: index)
                }

                let expSentinel = 1_000_000_000
                var expValue = 0
                var expTooLarge = false
                var hasExpDigits = false
                while index < bytes.count {
                    let b = unsafe bytes[index]
                    if b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9") {
                        hasExpDigits = true
                        if expValue < expSentinel {
                            expValue = expValue * 10 + Int(b - UInt8(ascii: "0"))
                        } else {
                            expTooLarge = true
                        }
                        index += 1
                    } else {
                        break
                    }
                }

                guard hasExpDigits else {
                    throw .syntax(offset: index)
                }

                if expTooLarge {
                    throw expSign > 0 ? .high : .low
                }

                exponent += expSign * expValue
            }
        }

        guard index == bytes.count else {
            throw .syntax(offset: index)
        }

        if coefficient == 0 {
            return .zero(sign: sign)
        }

        let (roundedCoefficient, roundedExponent, _) = Decimals.Rounding.round(
            coefficient: UInt128(coefficient),
            exponent: Decimal.Exponent(exponent),
            sign: sign,
            rounding: context.rounding,
            precision: context.precision
        )

        if roundedExponent > context.maxExponent {
            throw .high
        }
        if roundedExponent < context.minExponent {
            throw .low
        }

        return Value.encode(sign: sign, exponent: roundedExponent, coefficient: roundedCoefficient)
    }

    public func callAsFunction(
        _ bytes: ArraySlice<UInt8>,
        context: Decimal.Context = .format64
    ) throws(Decimal.Text.Error) -> Value {
        var result: Result<Value, Decimal.Text.Error>!
        bytes.withUnsafeBufferPointer { buffer in
            do {
                result = unsafe .success(try self(buffer, context: context))
            } catch let error as Decimal._TextError {
                result = .failure(error)
            } catch {
                fatalError("Unexpected error type")
            }
        }
        return try result.get()
    }

    public func callAsFunction(
        _ bytes: [UInt8],
        context: Decimal.Context = .format64
    ) throws(Decimal.Text.Error) -> Value {
        var result: Result<Value, Decimal.Text.Error>!
        bytes.withUnsafeBufferPointer { buffer in
            do {
                result = unsafe .success(try self(buffer, context: context))
            } catch let error as Decimal._TextError {
                result = .failure(error)
            } catch {
                fatalError("Unexpected error type")
            }
        }
        return try result.get()
    }
}

extension Decimal.Text.Parse where Value == Decimal.Format32 {

    public func callAsFunction(
        _ bytes: UnsafeBufferPointer<UInt8>,
        context: Decimal.Context = .format32
    ) throws(Decimal.Text.Error) -> Value {
        guard !bytes.isEmpty else {
            throw .empty
        }

        var index = 0

        var sign: Decimal.Sign = .positive
        if index < bytes.count {
            if unsafe bytes[index] == UInt8(ascii: "-") {
                sign = .negative
                index += 1
            } else if unsafe bytes[index] == UInt8(ascii: "+") {
                index += 1
            }
        }

        guard index < bytes.count else {
            throw .syntax(offset: index)
        }

        let remaining = bytes.count - index

        if remaining >= 3 {
            let i = unsafe bytes[index]
            let n = unsafe bytes[index + 1]
            let f = unsafe bytes[index + 2]
            if (i == UInt8(ascii: "I") || i == UInt8(ascii: "i"))
                && (n == UInt8(ascii: "n") || n == UInt8(ascii: "N"))
                && (f == UInt8(ascii: "f") || f == UInt8(ascii: "F"))
            {
                if remaining >= 8 {
                    let rest = unsafe [
                        bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6],
                        bytes[index + 7],
                    ]
                    if (rest[0] == UInt8(ascii: "i") || rest[0] == UInt8(ascii: "I"))
                        && (rest[1] == UInt8(ascii: "n") || rest[1] == UInt8(ascii: "N"))
                        && (rest[2] == UInt8(ascii: "i") || rest[2] == UInt8(ascii: "I"))
                        && (rest[3] == UInt8(ascii: "t") || rest[3] == UInt8(ascii: "T"))
                        && (rest[4] == UInt8(ascii: "y") || rest[4] == UInt8(ascii: "Y"))
                    {
                        if index + 8 == bytes.count {
                            return .infinity(sign: sign)
                        }
                    }
                }
                if index + 3 == bytes.count {
                    return .infinity(sign: sign)
                }
            }
        }

        if remaining >= 3 {
            let n1 = unsafe bytes[index]
            let a = unsafe bytes[index + 1]
            let n2 = unsafe bytes[index + 2]
            if (n1 == UInt8(ascii: "N") || n1 == UInt8(ascii: "n"))
                && (a == UInt8(ascii: "a") || a == UInt8(ascii: "A"))
                && (n2 == UInt8(ascii: "N") || n2 == UInt8(ascii: "n"))
            {
                guard index + 3 == bytes.count else {
                    throw .syntax(offset: index + 3)
                }
                let nan = Value.nan()
                return sign == .negative ? nan.negated : nan
            }
        }

        var coefficient: UInt32 = 0
        var exponent: Int = 0
        var hasDigits = false
        var decimalPos: Int? = nil
        var digitCount = 0

        while index < bytes.count {
            let byte = unsafe bytes[index]

            if byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9") {
                hasDigits = true
                let digit = UInt32(byte - UInt8(ascii: "0"))

                if digitCount < 9 {
                    coefficient = coefficient * 10 + digit
                    digitCount += 1
                } else {
                    if decimalPos == nil {
                        exponent += 1
                    }
                }
                index += 1
            } else if byte == UInt8(ascii: ".") {
                if decimalPos != nil {
                    throw .syntax(offset: index)
                }
                decimalPos = digitCount
                index += 1
            } else {
                break
            }
        }

        guard hasDigits else {
            throw .syntax(offset: index)
        }

        if let dp = decimalPos {
            exponent -= (digitCount - dp)
        }

        if index < bytes.count {
            let byte = unsafe bytes[index]
            if byte == UInt8(ascii: "E") || byte == UInt8(ascii: "e") {
                index += 1

                guard index < bytes.count else {
                    throw .syntax(offset: index)
                }

                var expSign = 1
                if unsafe bytes[index] == UInt8(ascii: "-") {
                    expSign = -1
                    index += 1
                } else if unsafe bytes[index] == UInt8(ascii: "+") {
                    index += 1
                }

                guard index < bytes.count else {
                    throw .syntax(offset: index)
                }

                let expSentinel = 1_000_000_000
                var expValue = 0
                var expTooLarge = false
                var hasExpDigits = false
                while index < bytes.count {
                    let b = unsafe bytes[index]
                    if b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9") {
                        hasExpDigits = true
                        if expValue < expSentinel {
                            expValue = expValue * 10 + Int(b - UInt8(ascii: "0"))
                        } else {
                            expTooLarge = true
                        }
                        index += 1
                    } else {
                        break
                    }
                }

                guard hasExpDigits else {
                    throw .syntax(offset: index)
                }

                if expTooLarge {
                    throw expSign > 0 ? .high : .low
                }

                exponent += expSign * expValue
            }
        }

        guard index == bytes.count else {
            throw .syntax(offset: index)
        }

        if coefficient == 0 {
            return .zero(sign: sign)
        }

        let (roundedCoefficient, roundedExponent, _) = Decimals.Rounding.round(
            coefficient: UInt64(coefficient),
            exponent: Decimal.Exponent(exponent),
            sign: sign,
            rounding: context.rounding,
            precision: context.precision
        )

        if roundedExponent > context.maxExponent {
            throw .high
        }
        if roundedExponent < context.minExponent {
            throw .low
        }

        return Value.encode(sign: sign, exponent: roundedExponent, coefficient: roundedCoefficient)
    }

    public func callAsFunction(
        _ bytes: ArraySlice<UInt8>,
        context: Decimal.Context = .format32
    ) throws(Decimal.Text.Error) -> Value {
        var result: Result<Value, Decimal.Text.Error>!
        bytes.withUnsafeBufferPointer { buffer in
            do {
                result = unsafe .success(try self(buffer, context: context))
            } catch let error as Decimal._TextError {
                result = .failure(error)
            } catch {
                fatalError("Unexpected error type")
            }
        }
        return try result.get()
    }

    public func callAsFunction(
        _ bytes: [UInt8],
        context: Decimal.Context = .format32
    ) throws(Decimal.Text.Error) -> Value {
        var result: Result<Value, Decimal.Text.Error>!
        bytes.withUnsafeBufferPointer { buffer in
            do {
                result = unsafe .success(try self(buffer, context: context))
            } catch let error as Decimal._TextError {
                result = .failure(error)
            } catch {
                fatalError("Unexpected error type")
            }
        }
        return try result.get()
    }
}

extension Decimal.Text.Parse where Value == Decimal.Format128 {

    public func callAsFunction(
        _ bytes: UnsafeBufferPointer<UInt8>,
        context: Decimal.Context = .format128
    ) throws(Decimal.Text.Error) -> Value {
        guard !bytes.isEmpty else {
            throw .empty
        }

        var index = 0

        var sign: Decimal.Sign = .positive
        if index < bytes.count {
            if unsafe bytes[index] == UInt8(ascii: "-") {
                sign = .negative
                index += 1
            } else if unsafe bytes[index] == UInt8(ascii: "+") {
                index += 1
            }
        }

        guard index < bytes.count else {
            throw .syntax(offset: index)
        }

        let remaining = bytes.count - index

        if remaining >= 3 {
            let i = unsafe bytes[index]
            let n = unsafe bytes[index + 1]
            let f = unsafe bytes[index + 2]
            if (i == UInt8(ascii: "I") || i == UInt8(ascii: "i"))
                && (n == UInt8(ascii: "n") || n == UInt8(ascii: "N"))
                && (f == UInt8(ascii: "f") || f == UInt8(ascii: "F"))
            {
                if remaining >= 8 {
                    let rest = unsafe [
                        bytes[index + 3], bytes[index + 4], bytes[index + 5], bytes[index + 6],
                        bytes[index + 7],
                    ]
                    if (rest[0] == UInt8(ascii: "i") || rest[0] == UInt8(ascii: "I"))
                        && (rest[1] == UInt8(ascii: "n") || rest[1] == UInt8(ascii: "N"))
                        && (rest[2] == UInt8(ascii: "i") || rest[2] == UInt8(ascii: "I"))
                        && (rest[3] == UInt8(ascii: "t") || rest[3] == UInt8(ascii: "T"))
                        && (rest[4] == UInt8(ascii: "y") || rest[4] == UInt8(ascii: "Y"))
                    {
                        if index + 8 == bytes.count {
                            return .infinity(sign: sign)
                        }
                    }
                }
                if index + 3 == bytes.count {
                    return .infinity(sign: sign)
                }
            }
        }

        if remaining >= 3 {
            let n1 = unsafe bytes[index]
            let a = unsafe bytes[index + 1]
            let n2 = unsafe bytes[index + 2]
            if (n1 == UInt8(ascii: "N") || n1 == UInt8(ascii: "n"))
                && (a == UInt8(ascii: "a") || a == UInt8(ascii: "A"))
                && (n2 == UInt8(ascii: "N") || n2 == UInt8(ascii: "n"))
            {
                guard index + 3 == bytes.count else {
                    throw .syntax(offset: index + 3)
                }
                let nan = Value.nan()
                return sign == .negative ? nan.negated : nan
            }
        }

        var coefficient: UInt128 = 0
        var exponent: Int = 0
        var hasDigits = false
        var decimalPos: Int? = nil
        var digitCount = 0

        while index < bytes.count {
            let byte = unsafe bytes[index]

            if byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9") {
                hasDigits = true
                let digit = UInt128(byte - UInt8(ascii: "0"))

                if digitCount < 38 {
                    coefficient = coefficient * 10 + digit
                    digitCount += 1
                } else {
                    if decimalPos == nil {
                        exponent += 1
                    }
                }
                index += 1
            } else if byte == UInt8(ascii: ".") {
                if decimalPos != nil {
                    throw .syntax(offset: index)
                }
                decimalPos = digitCount
                index += 1
            } else {
                break
            }
        }

        guard hasDigits else {
            throw .syntax(offset: index)
        }

        if let dp = decimalPos {
            exponent -= (digitCount - dp)
        }

        if index < bytes.count {
            let byte = unsafe bytes[index]
            if byte == UInt8(ascii: "E") || byte == UInt8(ascii: "e") {
                index += 1

                guard index < bytes.count else {
                    throw .syntax(offset: index)
                }

                var expSign = 1
                if unsafe bytes[index] == UInt8(ascii: "-") {
                    expSign = -1
                    index += 1
                } else if unsafe bytes[index] == UInt8(ascii: "+") {
                    index += 1
                }

                guard index < bytes.count else {
                    throw .syntax(offset: index)
                }

                let expSentinel = 1_000_000_000
                var expValue = 0
                var expTooLarge = false
                var hasExpDigits = false
                while index < bytes.count {
                    let b = unsafe bytes[index]
                    if b >= UInt8(ascii: "0") && b <= UInt8(ascii: "9") {
                        hasExpDigits = true
                        if expValue < expSentinel {
                            expValue = expValue * 10 + Int(b - UInt8(ascii: "0"))
                        } else {
                            expTooLarge = true
                        }
                        index += 1
                    } else {
                        break
                    }
                }

                guard hasExpDigits else {
                    throw .syntax(offset: index)
                }

                if expTooLarge {
                    throw expSign > 0 ? .high : .low
                }

                exponent += expSign * expValue
            }
        }

        guard index == bytes.count else {
            throw .syntax(offset: index)
        }

        if coefficient == 0 {
            return .zero(sign: sign)
        }

        let (roundedCoefficient, roundedExponent, _) = Decimals.Rounding.round128(
            coefficient: coefficient,
            exponent: Decimal.Exponent(exponent),
            sign: sign,
            rounding: context.rounding,
            precision: context.precision
        )

        if roundedExponent > context.maxExponent {
            throw .high
        }
        if roundedExponent < context.minExponent {
            throw .low
        }

        return Value.encode(sign: sign, exponent: roundedExponent, coefficient: roundedCoefficient)
    }

    public func callAsFunction(
        _ bytes: ArraySlice<UInt8>,
        context: Decimal.Context = .format128
    ) throws(Decimal.Text.Error) -> Value {
        var result: Result<Value, Decimal.Text.Error>!
        bytes.withUnsafeBufferPointer { buffer in
            do {
                result = unsafe .success(try self(buffer, context: context))
            } catch let error as Decimal._TextError {
                result = .failure(error)
            } catch {
                fatalError("Unexpected error type")
            }
        }
        return try result.get()
    }

    public func callAsFunction(
        _ bytes: [UInt8],
        context: Decimal.Context = .format128
    ) throws(Decimal.Text.Error) -> Value {
        var result: Result<Value, Decimal.Text.Error>!
        bytes.withUnsafeBufferPointer { buffer in
            do {
                result = unsafe .success(try self(buffer, context: context))
            } catch let error as Decimal._TextError {
                result = .failure(error)
            } catch {
                fatalError("Unexpected error type")
            }
        }
        return try result.get()
    }
}
