internal import ASCII_Decimal_Serializer_Primitives

extension Decimal.Text where Value == Decimal.Format64 {

    public func render(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        style: Decimal.Text.Style = .plain
    ) -> Int {
        let capacity = requiredCapacity(style: style)
        precondition(
            buffer.count >= capacity,
            "Decimal.Text.render(into:): buffer has \(buffer.count) bytes but this value needs at least \(capacity) bytes for style \(style)."
        )

        var offset = 0

        if base.sign == .negative {
            unsafe buffer[offset] = UInt8(ascii: "-")
            offset += 1
        }

        if base.test.nan {
            let nan: [UInt8] = [UInt8(ascii: "N"), UInt8(ascii: "a"), UInt8(ascii: "N")]
            for byte in nan {
                unsafe buffer[offset] = byte
                offset += 1
            }
            return offset
        }

        if base.test.infinite {
            let inf: [UInt8] = [
                UInt8(ascii: "I"), UInt8(ascii: "n"), UInt8(ascii: "f"), UInt8(ascii: "i"),
                UInt8(ascii: "n"), UInt8(ascii: "i"), UInt8(ascii: "t"), UInt8(ascii: "y"),
            ]
            for byte in inf {
                unsafe buffer[offset] = byte
                offset += 1
            }
            return offset
        }

        if base.test.zero {
            unsafe buffer[offset] = UInt8(ascii: "0")
            return offset + 1
        }

        let coefficient = base.extractCoefficient()
        let exponent = base.extractExponent()

        var digitCodes: [ASCII.Code] = []
        ASCII.Decimal.Serializer().serialize(coefficient, into: &digitCodes)
        let digits: [UInt8] = digitCodes.map(\.underlying)

        let numDigits = digits.count
        let adjustedExponent = exponent.rawValue + numDigits - 1

        switch style {
        case .plain:

            if exponent.rawValue >= 0 {

                for digit in digits {
                    unsafe buffer[offset] = digit
                    offset += 1
                }
                for _ in 0..<exponent.rawValue {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                    offset += 1
                }
            } else if exponent.rawValue >= -numDigits + 1 {

                let decimalPos = numDigits + exponent.rawValue
                for (i, digit) in digits.enumerated() {
                    if i == decimalPos {
                        unsafe buffer[offset] = UInt8(ascii: ".")
                        offset += 1
                    }
                    unsafe buffer[offset] = digit
                    offset += 1
                }
            } else {

                unsafe buffer[offset] = UInt8(ascii: "0")
                offset += 1
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                for _ in 0..<(-exponent.rawValue - numDigits) {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                    offset += 1
                }
                for digit in digits {
                    unsafe buffer[offset] = digit
                    offset += 1
                }
            }

        case .scientific:

            unsafe buffer[offset] = digits[0]
            offset += 1
            if numDigits > 1 {
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                (1..<numDigits).forEach { i in
                    unsafe buffer[offset] = digits[i]
                    offset += 1
                }
            }
            unsafe buffer[offset] = UInt8(ascii: "E")
            offset += 1
            unsafe offset += writeExponent(adjustedExponent, to: buffer, at: offset)

        case .engineering:

            let engExp = (adjustedExponent / 3) * 3
            let shift = adjustedExponent - engExp
            let intDigits = shift + 1

            (0..<intDigits).forEach { i in
                if i < numDigits {
                    unsafe buffer[offset] = digits[i]
                } else {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                }
                offset += 1
            }
            if intDigits < numDigits {
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                (intDigits..<numDigits).forEach { i in
                    unsafe buffer[offset] = digits[i]
                    offset += 1
                }
            }
            if engExp != 0 {
                unsafe buffer[offset] = UInt8(ascii: "E")
                offset += 1
                unsafe offset += writeExponent(engExp, to: buffer, at: offset)
            }
        }

        return offset
    }

    @usableFromInline
    internal func writeExponent(
        _ exp: Int,
        to buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var off = offset
        if exp >= 0 {
            unsafe buffer[off] = UInt8(ascii: "+")
        } else {
            unsafe buffer[off] = UInt8(ascii: "-")
        }
        off += 1

        let absExp = abs(exp)
        var expDigits: [UInt8] = []
        var temp = absExp
        if temp == 0 {
            expDigits.append(UInt8(ascii: "0"))
        }
        while temp > 0 {
            expDigits.append(UInt8(ascii: "0") + UInt8(temp % 10))
            temp /= 10
        }
        expDigits.reverse()
        for digit in expDigits {
            unsafe buffer[off] = digit
            off += 1
        }
        return off - offset
    }

    public func render(
        appending buffer: inout [UInt8],
        style: Decimal.Text.Style = .plain
    ) {

        var temp = [UInt8](repeating: 0, count: requiredCapacity(style: style))
        let count = temp.withUnsafeMutableBufferPointer { ptr in
            unsafe render(into: ptr, style: style)
        }
        buffer.append(contentsOf: temp[0..<count])
    }

    public func requiredCapacity(style: Decimal.Text.Style = .plain) -> Int {
        if base.test.nan {
            return 4
        }
        if base.test.infinite {
            return 9
        }
        if base.test.zero {
            return 2
        }

        let coefficient = base.extractCoefficient()
        let exponent = base.extractExponent()
        var digitCodes: [ASCII.Code] = []
        ASCII.Decimal.Serializer().serialize(coefficient, into: &digitCodes)

        return Self.requiredCapacity(
            numDigits: digitCodes.count,
            exponent: exponent.rawValue,
            style: style
        )
    }

    @usableFromInline
    internal static func requiredCapacity(
        numDigits: Int,
        exponent: Int,
        style: Decimal.Text.Style
    ) -> Int {
        let adjustedExponent = exponent + numDigits - 1

        let zeroRun = max(exponent, -exponent)
        let exponentDigits = decimalDigitCount(adjustedExponent)

        switch style {
        case .plain:

            return 1 + 2 + numDigits + 1 + zeroRun

        case .scientific:

            return 1 + 1 + 1 + numDigits + 1 + 1 + exponentDigits

        case .engineering:

            return 1 + 3 + 1 + numDigits + 1 + 1 + exponentDigits
        }
    }

    @usableFromInline
    internal static func decimalDigitCount(_ value: Int) -> Int {
        var count = 1
        var remainder = value.magnitude / 10
        while remainder > 0 {
            count += 1
            remainder /= 10
        }
        return count
    }
}

extension Decimal.Text where Value == Decimal.Format32 {

    public func render(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        style: Decimal.Text.Style = .plain
    ) -> Int {
        let capacity = requiredCapacity(style: style)
        precondition(
            buffer.count >= capacity,
            "Decimal.Text.render(into:): buffer has \(buffer.count) bytes but this value needs at least \(capacity) bytes for style \(style)."
        )

        var offset = 0

        if base.sign == .negative {
            unsafe buffer[offset] = UInt8(ascii: "-")
            offset += 1
        }

        if base.test.nan {
            let nan: [UInt8] = [UInt8(ascii: "N"), UInt8(ascii: "a"), UInt8(ascii: "N")]
            for byte in nan {
                unsafe buffer[offset] = byte
                offset += 1
            }
            return offset
        }

        if base.test.infinite {
            let inf: [UInt8] = [
                UInt8(ascii: "I"), UInt8(ascii: "n"), UInt8(ascii: "f"), UInt8(ascii: "i"),
                UInt8(ascii: "n"), UInt8(ascii: "i"), UInt8(ascii: "t"), UInt8(ascii: "y"),
            ]
            for byte in inf {
                unsafe buffer[offset] = byte
                offset += 1
            }
            return offset
        }

        if base.test.zero {
            unsafe buffer[offset] = UInt8(ascii: "0")
            return offset + 1
        }

        let coefficient = base.extractCoefficient()
        let exponent = base.extractExponent()

        var digitCodes: [ASCII.Code] = []
        ASCII.Decimal.Serializer().serialize(coefficient, into: &digitCodes)
        let digits: [UInt8] = digitCodes.map(\.underlying)

        let numDigits = digits.count
        let adjustedExponent = exponent.rawValue + numDigits - 1

        switch style {
        case .plain:
            if exponent.rawValue >= 0 {
                for digit in digits {
                    unsafe buffer[offset] = digit
                    offset += 1
                }
                for _ in 0..<exponent.rawValue {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                    offset += 1
                }
            } else if exponent.rawValue >= -numDigits + 1 {
                let decimalPos = numDigits + exponent.rawValue
                for (i, digit) in digits.enumerated() {
                    if i == decimalPos {
                        unsafe buffer[offset] = UInt8(ascii: ".")
                        offset += 1
                    }
                    unsafe buffer[offset] = digit
                    offset += 1
                }
            } else {
                unsafe buffer[offset] = UInt8(ascii: "0")
                offset += 1
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                for _ in 0..<(-exponent.rawValue - numDigits) {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                    offset += 1
                }
                for digit in digits {
                    unsafe buffer[offset] = digit
                    offset += 1
                }
            }

        case .scientific:
            unsafe buffer[offset] = digits[0]
            offset += 1
            if numDigits > 1 {
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                (1..<numDigits).forEach { i in
                    unsafe buffer[offset] = digits[i]
                    offset += 1
                }
            }
            unsafe buffer[offset] = UInt8(ascii: "E")
            offset += 1
            unsafe offset += writeExponent(adjustedExponent, to: buffer, at: offset)

        case .engineering:
            let engExp = (adjustedExponent / 3) * 3
            let shift = adjustedExponent - engExp
            let intDigits = shift + 1

            (0..<intDigits).forEach { i in
                if i < numDigits {
                    unsafe buffer[offset] = digits[i]
                } else {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                }
                offset += 1
            }
            if intDigits < numDigits {
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                (intDigits..<numDigits).forEach { i in
                    unsafe buffer[offset] = digits[i]
                    offset += 1
                }
            }
            if engExp != 0 {
                unsafe buffer[offset] = UInt8(ascii: "E")
                offset += 1
                unsafe offset += writeExponent(engExp, to: buffer, at: offset)
            }
        }

        return offset
    }

    @usableFromInline
    internal func writeExponent(
        _ exp: Int,
        to buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var off = offset
        if exp >= 0 {
            unsafe buffer[off] = UInt8(ascii: "+")
        } else {
            unsafe buffer[off] = UInt8(ascii: "-")
        }
        off += 1

        let absExp = abs(exp)
        var expDigits: [UInt8] = []
        var temp = absExp
        if temp == 0 {
            expDigits.append(UInt8(ascii: "0"))
        }
        while temp > 0 {
            expDigits.append(UInt8(ascii: "0") + UInt8(temp % 10))
            temp /= 10
        }
        expDigits.reverse()
        for digit in expDigits {
            unsafe buffer[off] = digit
            off += 1
        }
        return off - offset
    }

    public func render(
        appending buffer: inout [UInt8],
        style: Decimal.Text.Style = .plain
    ) {

        var temp = [UInt8](repeating: 0, count: requiredCapacity(style: style))
        let count = temp.withUnsafeMutableBufferPointer { ptr in
            unsafe render(into: ptr, style: style)
        }
        buffer.append(contentsOf: temp[0..<count])
    }

    public func requiredCapacity(style: Decimal.Text.Style = .plain) -> Int {
        if base.test.nan {
            return 4
        }
        if base.test.infinite {
            return 9
        }
        if base.test.zero {
            return 2
        }

        let coefficient = base.extractCoefficient()
        let exponent = base.extractExponent()
        var digitCodes: [ASCII.Code] = []
        ASCII.Decimal.Serializer().serialize(coefficient, into: &digitCodes)

        return Self.requiredCapacity(
            numDigits: digitCodes.count,
            exponent: exponent.rawValue,
            style: style
        )
    }

    @usableFromInline
    internal static func requiredCapacity(
        numDigits: Int,
        exponent: Int,
        style: Decimal.Text.Style
    ) -> Int {
        let adjustedExponent = exponent + numDigits - 1
        let zeroRun = max(exponent, -exponent)
        let exponentDigits = decimalDigitCount(adjustedExponent)

        switch style {
        case .plain:
            return 1 + 2 + numDigits + 1 + zeroRun

        case .scientific:
            return 1 + 1 + 1 + numDigits + 1 + 1 + exponentDigits

        case .engineering:
            return 1 + 3 + 1 + numDigits + 1 + 1 + exponentDigits
        }
    }

    @usableFromInline
    internal static func decimalDigitCount(_ value: Int) -> Int {
        var count = 1
        var remainder = value.magnitude / 10
        while remainder > 0 {
            count += 1
            remainder /= 10
        }
        return count
    }
}

extension Decimal.Text where Value == Decimal.Format128 {

    public func render(
        into buffer: UnsafeMutableBufferPointer<UInt8>,
        style: Decimal.Text.Style = .plain
    ) -> Int {
        let capacity = requiredCapacity(style: style)
        precondition(
            buffer.count >= capacity,
            "Decimal.Text.render(into:): buffer has \(buffer.count) bytes but this value needs at least \(capacity) bytes for style \(style)."
        )

        var offset = 0

        if base.sign == .negative {
            unsafe buffer[offset] = UInt8(ascii: "-")
            offset += 1
        }

        if base.test.nan {
            let nan: [UInt8] = [UInt8(ascii: "N"), UInt8(ascii: "a"), UInt8(ascii: "N")]
            for byte in nan {
                unsafe buffer[offset] = byte
                offset += 1
            }
            return offset
        }

        if base.test.infinite {
            let inf: [UInt8] = [
                UInt8(ascii: "I"), UInt8(ascii: "n"), UInt8(ascii: "f"), UInt8(ascii: "i"),
                UInt8(ascii: "n"), UInt8(ascii: "i"), UInt8(ascii: "t"), UInt8(ascii: "y"),
            ]
            for byte in inf {
                unsafe buffer[offset] = byte
                offset += 1
            }
            return offset
        }

        if base.test.zero {
            unsafe buffer[offset] = UInt8(ascii: "0")
            return offset + 1
        }

        let coefficient = base.extractCoefficient()
        let exponent = base.extractExponent()

        var digitCodes: [ASCII.Code] = []
        ASCII.Decimal.Serializer().serialize(coefficient, into: &digitCodes)
        let digits: [UInt8] = digitCodes.map(\.underlying)

        let numDigits = digits.count
        let adjustedExponent = exponent.rawValue + numDigits - 1

        switch style {
        case .plain:
            if exponent.rawValue >= 0 {
                for digit in digits {
                    unsafe buffer[offset] = digit
                    offset += 1
                }
                for _ in 0..<exponent.rawValue {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                    offset += 1
                }
            } else if exponent.rawValue >= -numDigits + 1 {
                let decimalPos = numDigits + exponent.rawValue
                for (i, digit) in digits.enumerated() {
                    if i == decimalPos {
                        unsafe buffer[offset] = UInt8(ascii: ".")
                        offset += 1
                    }
                    unsafe buffer[offset] = digit
                    offset += 1
                }
            } else {
                unsafe buffer[offset] = UInt8(ascii: "0")
                offset += 1
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                for _ in 0..<(-exponent.rawValue - numDigits) {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                    offset += 1
                }
                for digit in digits {
                    unsafe buffer[offset] = digit
                    offset += 1
                }
            }

        case .scientific:
            unsafe buffer[offset] = digits[0]
            offset += 1
            if numDigits > 1 {
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                (1..<numDigits).forEach { i in
                    unsafe buffer[offset] = digits[i]
                    offset += 1
                }
            }
            unsafe buffer[offset] = UInt8(ascii: "E")
            offset += 1
            unsafe offset += writeExponent(adjustedExponent, to: buffer, at: offset)

        case .engineering:
            let engExp = (adjustedExponent / 3) * 3
            let shift = adjustedExponent - engExp
            let intDigits = shift + 1

            (0..<intDigits).forEach { i in
                if i < numDigits {
                    unsafe buffer[offset] = digits[i]
                } else {
                    unsafe buffer[offset] = UInt8(ascii: "0")
                }
                offset += 1
            }
            if intDigits < numDigits {
                unsafe buffer[offset] = UInt8(ascii: ".")
                offset += 1
                (intDigits..<numDigits).forEach { i in
                    unsafe buffer[offset] = digits[i]
                    offset += 1
                }
            }
            if engExp != 0 {
                unsafe buffer[offset] = UInt8(ascii: "E")
                offset += 1
                unsafe offset += writeExponent(engExp, to: buffer, at: offset)
            }
        }

        return offset
    }

    @usableFromInline
    internal func writeExponent(
        _ exp: Int,
        to buffer: UnsafeMutableBufferPointer<UInt8>,
        at offset: Int
    ) -> Int {
        var off = offset
        if exp >= 0 {
            unsafe buffer[off] = UInt8(ascii: "+")
        } else {
            unsafe buffer[off] = UInt8(ascii: "-")
        }
        off += 1

        let absExp = abs(exp)
        var expDigits: [UInt8] = []
        var temp = absExp
        if temp == 0 {
            expDigits.append(UInt8(ascii: "0"))
        }
        while temp > 0 {
            expDigits.append(UInt8(ascii: "0") + UInt8(temp % 10))
            temp /= 10
        }
        expDigits.reverse()
        for digit in expDigits {
            unsafe buffer[off] = digit
            off += 1
        }
        return off - offset
    }

    public func render(
        appending buffer: inout [UInt8],
        style: Decimal.Text.Style = .plain
    ) {

        var temp = [UInt8](repeating: 0, count: requiredCapacity(style: style))
        let count = temp.withUnsafeMutableBufferPointer { ptr in
            unsafe render(into: ptr, style: style)
        }
        buffer.append(contentsOf: temp[0..<count])
    }

    public func requiredCapacity(style: Decimal.Text.Style = .plain) -> Int {
        if base.test.nan {
            return 4
        }
        if base.test.infinite {
            return 9
        }
        if base.test.zero {
            return 2
        }

        let coefficient = base.extractCoefficient()
        let exponent = base.extractExponent()
        var digitCodes: [ASCII.Code] = []
        ASCII.Decimal.Serializer().serialize(coefficient, into: &digitCodes)

        return Self.requiredCapacity(
            numDigits: digitCodes.count,
            exponent: exponent.rawValue,
            style: style
        )
    }

    @usableFromInline
    internal static func requiredCapacity(
        numDigits: Int,
        exponent: Int,
        style: Decimal.Text.Style
    ) -> Int {
        let adjustedExponent = exponent + numDigits - 1
        let zeroRun = max(exponent, -exponent)
        let exponentDigits = decimalDigitCount(adjustedExponent)

        switch style {
        case .plain:
            return 1 + 2 + numDigits + 1 + zeroRun

        case .scientific:
            return 1 + 1 + 1 + numDigits + 1 + 1 + exponentDigits

        case .engineering:
            return 1 + 3 + 1 + numDigits + 1 + 1 + exponentDigits
        }
    }

    @usableFromInline
    internal static func decimalDigitCount(_ value: Int) -> Int {
        var count = 1
        var remainder = value.magnitude / 10
        while remainder > 0 {
            count += 1
            remainder /= 10
        }
        return count
    }
}
