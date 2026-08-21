import Testing

@testable import Decimals

extension Decimal.Format32.Test {
    @Suite struct `Edge Case` {

        @Test func `addition does not overflow coefficient scaling at large exponent difference`() {

            let a = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let b = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-20),
                coefficient: 1
            )
            let result = a.operation.add(b)
            #expect(!result.value.test.nan)
        }

        @Test
        func
            `fuse does not silently combine unaligned coefficients when exponent difference exceeds old cutoff`()
        {

            let x = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let y = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-30),
                coefficient: 1
            )
            let result = x.operation.fuse(y, z)
            #expect(
                result.value
                    == Decimal.Format32.encode(
                        sign: .positive,
                        exponent: Decimal.Exponent(0),
                        coefficient: 1
                    )
            )
        }

        @Test func `divide does not double-round an exact-looking tie that is actually above half`()
        {

            var context = Decimal.Context.format32
            context.rounding = .toward
            let a = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let b = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 56239
            )
            let result = a.operation.divide(b, context: context)
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-11),
                coefficient: 1_778_126
            )
            #expect(result.value == expected)
        }

        @Test
        func
            `fuse computes the exact sum within the guard-digit window instead of dropping a still-significant operand`()
        {

            let x = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 5_000_000
            )
            let y = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 7_000_001
            )
            let z = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-7),
                coefficient: 1_234_567
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(7),
                coefficient: 3_500_001
            )
            #expect(result.value != z)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }

        @Test
        func
            `fuse still computes the exact sum when the product has fewer digits than the fixed guard window assumed`()
        {

            let x = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let y = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-11),
                coefficient: 5_000_000
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-6),
                coefficient: 1_000_050
            )
            #expect(result.value != x)
            #expect(result.value == expected)
            #expect(!result.status.contains(.inexact))
        }

        @Test
        func
            `fuse rounds a same-sign near tie in the product's own digits correctly when z is not negligible`()
        {

            let x = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 965_551
            )
            let y = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 6_929_998
            )
            let z = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-3),
                coefficient: 7_424_422
            )
            let result = x.operation.fuse(y, z)
            let wrongPreFix = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(6),
                coefficient: 6_691_266
            )
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(6),
                coefficient: 6_691_267
            )
            #expect(result.value != wrongPreFix)
            #expect(result.value == expected)
        }

        @Test
        func
            `fuse rounds a second same-sign near tie in the product's own digits correctly when z is not negligible`()
        {

            let x = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 5_070_194
            )
            let y = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 4_010_670
            )
            let z = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-2),
                coefficient: 3_247_266
            )
            let result = x.operation.fuse(y, z)
            let wrongPreFix = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(7),
                coefficient: 2_033_487
            )
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(7),
                coefficient: 2_033_488
            )
            #expect(result.value != wrongPreFix)
            #expect(result.value == expected)
        }

        @Test
        func
            `fuse rounds an exact tie in the product's own digits toward the correct side when z is opposite sign`()
        {

            let x = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 4_000_001
            )
            let y = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 5
            )
            let z = Decimal.Format32.encode(
                sign: .negative,
                exponent: Decimal.Exponent(-2),
                coefficient: 1
            )
            let result = x.operation.fuse(y, z)
            let wrongPreFix = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 2_000_001
            )
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 2_000_000
            )
            #expect(result.value != wrongPreFix)
            #expect(result.value == expected)
        }

        @Test
        func
            `fuse does not drop a still-significant addend across an opposite-sign borrow when the product is a power of ten`()
        {

            let x = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(8),
                coefficient: 1
            )
            let y = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format32.encode(
                sign: .negative,
                exponent: Decimal.Exponent(0),
                coefficient: 6
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 9_999_999
            )
            #expect(result.value != x)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }

        @Test
        func
            `fuse does not corrupt a Form-2-encoded coefficient input via the swift-decimal-primitives BID Form-2 decode bug`()
        {

            let x = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 8_665_773
            )
            let y = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-1),
                coefficient: 1
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 8_665_773
            )
            #expect(!result.value.test.nan)
            #expect(!result.value.test.infinite)
            #expect(result.value == expected)
        }
    }
}
