import Testing

@testable import Decimals

extension Decimal.Format64 {
    @Suite struct Test {

        @Test func `addition Basic`() {
            let a: Decimal.Format64 = 10
            let b: Decimal.Format64 = 5
            let result = a + b
            #expect(Int64(exactly: result) == 15)
        }

        @Test func `addition Negative`() {
            let a: Decimal.Format64 = 10
            let b: Decimal.Format64 = -3
            let result = a + b
            #expect(Int64(exactly: result) == 7)
        }

        @Test func `addition Zero`() {
            let a: Decimal.Format64 = 42
            let b: Decimal.Format64 = 0
            let result = a + b
            #expect(Int64(exactly: result) == 42)
        }

        @Test func `addition Infinity`() {
            let a: Decimal.Format64 = 42
            let inf = Decimal.Format64.infinity()
            let result = a + inf
            #expect(result.test.infinite)
        }

        @Test func `addition Opposite Infinity`() {
            let posInf = Decimal.Format64.infinity()
            let negInf = Decimal.Format64.infinity(sign: .negative)
            let result = posInf + negInf
            #expect(result.test.nan)
        }

        @Test func `subtraction Basic`() {
            let a: Decimal.Format64 = 10
            let b: Decimal.Format64 = 3
            let result = a - b
            #expect(Int64(exactly: result) == 7)
        }

        @Test func `subtraction Negative Result`() {
            let a: Decimal.Format64 = 3
            let b: Decimal.Format64 = 10
            let result = a - b
            #expect(Int64(exactly: result) == -7)
        }

        @Test func `multiplication Basic`() {
            let a: Decimal.Format64 = 6
            let b: Decimal.Format64 = 7
            let result = a * b
            #expect(Int64(exactly: result) == 42)
        }

        @Test func `multiplication By Zero`() {
            let a: Decimal.Format64 = 42
            let b: Decimal.Format64 = 0
            let result = a * b
            #expect(result.test.zero)
        }

        @Test func `multiplication By Negative`() {
            let a: Decimal.Format64 = 6
            let b: Decimal.Format64 = -7
            let result = a * b
            #expect(Int64(exactly: result) == -42)
        }

        @Test func `multiplication Infinity By Zero`() {
            let inf = Decimal.Format64.infinity()
            let zero: Decimal.Format64 = 0
            let result = inf * zero
            #expect(result.test.nan)
        }

        @Test func `division Basic`() {
            let a: Decimal.Format64 = 42
            let b: Decimal.Format64 = 6
            let result = a / b
            #expect(Int64(exactly: result) == 7)
        }

        @Test func `division By Zero`() {
            let a: Decimal.Format64 = 42
            let b: Decimal.Format64 = 0
            let result = a / b
            #expect(result.test.infinite)
        }

        @Test func `division Zero By Zero`() {
            let a: Decimal.Format64 = 0
            let b: Decimal.Format64 = 0
            let result = a / b
            #expect(result.test.nan)
        }

        @Test func `division Infinity By Infinity`() {
            let a = Decimal.Format64.infinity()
            let b = Decimal.Format64.infinity()
            let result = a / b
            #expect(result.test.nan)
        }

        @Test func `comparison Less`() {
            let a: Decimal.Format64 = 5
            let b: Decimal.Format64 = 10
            #expect(a < b)
            #expect(!(b < a))
        }

        @Test func `comparison Equal`() {
            let a: Decimal.Format64 = 42
            let b: Decimal.Format64 = 42
            #expect(!(a < b))
            #expect(!(b < a))
        }

        @Test func `integer Conversion`() {
            let a: Decimal.Format64 = 12345
            #expect(Int64(exactly: a) == 12345)
        }

        @Test func `negative Integer Conversion`() {
            let a: Decimal.Format64 = -9876
            #expect(Int64(exactly: a) == -9876)
        }
    }
}

extension Decimal.Format64.Test {
    @Suite struct `Edge Case` {

        @Test func `addition does not overflow coefficient scaling at large exponent difference`() {

            let a = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 9_007_199_254_740_991
            )
            let b = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-38),
                coefficient: 1
            )
            let result = a.operation.add(b)
            #expect(!result.value.test.nan)
        }

        @Test
        func
            `fuse does not silently combine unaligned coefficients when exponent difference exceeds old cutoff`()
        {

            let x = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let y = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-100),
                coefficient: 1
            )
            let result = x.operation.fuse(y, z)
            #expect(Int64(exactly: result.value) == 1)
        }

        @Test
        func
            `fuse computes the exact sum within the guard-digit window instead of dropping a still-significant operand`()
        {

            let x = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 5_000_000_000_000_000
            )
            let y = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 7_000_000_000_000_001
            )
            let z = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-10),
                coefficient: 1_234_567
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(16),
                coefficient: 3_500_000_000_000_001
            )
            #expect(result.value != z)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }

        @Test
        func
            `fuse still computes the exact sum when the product has fewer digits than the fixed guard window assumed`()
        {

            let x = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let y = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-25),
                coefficient: 5_000_000_000_000_000
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-15),
                coefficient: 1_000_000_000_500_000
            )
            #expect(result.value != x)
            #expect(result.value == expected)
            #expect(!result.status.contains(.inexact))
        }

        @Test
        func
            `fuse rounds a same-sign near tie in the product's own digits correctly when z is not negligible`()
        {

            let x = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 8_190_249_936_086_788
            )
            let y = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 917_372_637_240_375
            )
            let z = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-3),
                coefficient: 6_635_049_452_689_808
            )
            let result = x.operation.fuse(y, z)
            let wrongPreFix = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(15),
                coefficient: 7_513_511_183_525_749
            )
            let expected = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(15),
                coefficient: 7_513_511_183_525_750
            )
            #expect(result.value != wrongPreFix)
            #expect(result.value == expected)
        }

        @Test
        func
            `fuse rounds an exact tie in the product's own digits toward the correct side when z is opposite sign`()
        {

            let x = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 4_000_000_000_000_001
            )
            let y = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 5
            )
            let z = Decimal.Format64.encode(
                sign: .negative,
                exponent: Decimal.Exponent(-2),
                coefficient: 1
            )
            let result = x.operation.fuse(y, z)
            let wrongPreFix = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 2_000_000_000_000_001
            )
            let expected = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 2_000_000_000_000_000
            )
            #expect(result.value != wrongPreFix)
            #expect(result.value == expected)
        }

        @Test
        func
            `fuse does not drop a still-significant addend across an opposite-sign borrow when the product is a power of ten`()
        {

            let x = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(17),
                coefficient: 1
            )
            let y = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format64.encode(
                sign: .negative,
                exponent: Decimal.Exponent(0),
                coefficient: 6
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format64.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 9_999_999_999_999_999
            )
            #expect(result.value != x)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }
    }
}
