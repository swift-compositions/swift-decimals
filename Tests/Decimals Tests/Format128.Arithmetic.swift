import Testing

@testable import Decimals

extension Decimal.Format128.Test {
    @Suite struct `Edge Case` {

        @Test func `addition does not overflow coefficient scaling at large exponent difference`() {

            let a = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let b = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-70),
                coefficient: 1
            )
            let result = a.operation.add(b)
            #expect(!result.value.test.nan)
        }

        @Test
        func
            `fuse does not silently combine unaligned coefficients when exponent difference exceeds old cutoff`()
        {

            let x = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let y = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-100),
                coefficient: 1
            )
            let result = x.operation.fuse(y, z)
            #expect(
                result.value
                    == Decimal.Format128.encode(
                        sign: .positive,
                        exponent: Decimal.Exponent(0),
                        coefficient: 1
                    )
            )
        }

        @Test
        func
            `addition computes the exact sum within the guard-digit window instead of dropping a still-significant operand`()
        {

            let a = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 9_999_999_999_999_999_999_999_999_999_999_999
            )
            let b = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(5),
                coefficient: 9_999_999_999_999_999_999_999_999_999_999_999
            )
            let result = a.operation.add(b)
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(6),
                coefficient: 1_000_010_000_000_000_000_000_000_000_000_000
            )
            #expect(result.value != b)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }

        @Test
        func
            `addition beyond the guard-digit window folds the discarded operand into the rounding decision as sticky`()
        {

            let a = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let b = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-40),
                coefficient: 1
            )
            let result = a.operation.add(b)
            #expect(result.value == a)
            #expect(result.status.contains(.inexact))
        }

        @Test
        func
            `fuse computes the exact sum within the guard-digit window instead of dropping a still-significant operand`()
        {

            let x = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let y = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 9_999_999_999_999_999_999_999_999_999_999_999
            )
            let z = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(5),
                coefficient: 9_999_999_999_999_999_999_999_999_999_999_999
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(6),
                coefficient: 1_000_010_000_000_000_000_000_000_000_000_000
            )
            #expect(result.value != z)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }

        @Test
        func
            `addition still computes the exact sum when the near operand has fewer digits than the fixed guard window assumed`()
        {

            let a = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 5_000_000_000_000_000_000_000_000_000_000_000
            )
            let b = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(36),
                coefficient: 1
            )
            let result = a.operation.add(b)
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(3),
                coefficient: 1_005_000_000_000_000_000_000_000_000_000_000
            )
            #expect(result.value != b)
            #expect(result.value == expected)
            #expect(!result.status.contains(.inexact))
        }

        @Test
        func
            `fuse still computes the exact sum when the product has fewer digits than the fixed guard window assumed`()
        {

            let x = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let y = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-50),
                coefficient: 5_000_000_000_000_000_000_000_000_000_000_000
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-33),
                coefficient: 1_000_000_000_000_000_050_000_000_000_000_000
            )
            #expect(result.value != x)
            #expect(result.value == expected)
            #expect(!result.status.contains(.inexact))
        }

        @Test
        func
            `fuse rounds a same-sign near tie in the product's own digits correctly when z is not negligible`()
        {

            let x = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1_698_729_580_379_692_341
            )
            let y = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 2_071_386_661_409_561_673
            )
            let z = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(-19),
                coefficient: 88_215_156_206_619_817_185
            )
            let result = x.operation.fuse(y, z)
            let wrongPreFix = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(3),
                coefficient: 3_518_725_794_140_356_559_346_158_171_405_246
            )
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(3),
                coefficient: 3_518_725_794_140_356_559_346_158_171_405_247
            )
            #expect(result.value != wrongPreFix)
            #expect(result.value == expected)
        }

        @Test
        func
            `fuse rounds an exact tie in the product's own digits toward the correct side when z is opposite sign`()
        {

            let x = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 4_000_000_000_000_000_000_000_000_000_000_001
            )
            let y = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 5
            )
            let z = Decimal.Format128.encode(
                sign: .negative,
                exponent: Decimal.Exponent(-2),
                coefficient: 1
            )
            let result = x.operation.fuse(y, z)
            let wrongPreFix = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 2_000_000_000_000_000_000_000_000_000_000_001
            )
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 2_000_000_000_000_000_000_000_000_000_000_000
            )
            #expect(result.value != wrongPreFix)
            #expect(result.value == expected)
        }

        @Test
        func
            `addition does not drop a still-significant operand across an opposite-sign borrow through a power-of-ten leading digit`()
        {

            let a = Decimal.Format128.encode(
                sign: .negative,
                exponent: Decimal.Exponent(0),
                coefficient: 6
            )
            let b = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(35),
                coefficient: 1
            )
            let result = a.operation.add(b)
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 9_999_999_999_999_999_999_999_999_999_999_999
            )
            #expect(result.value != b)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }

        @Test
        func
            `fuse does not drop a still-significant addend across an opposite-sign borrow when the product is a power of ten`()
        {

            let x = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(35),
                coefficient: 1
            )
            let y = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 1
            )
            let z = Decimal.Format128.encode(
                sign: .negative,
                exponent: Decimal.Exponent(0),
                coefficient: 6
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 9_999_999_999_999_999_999_999_999_999_999_999
            )
            #expect(result.value != x)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }

        @Test
        func
            `fuse computes the exact sum without trapping at the new threshold's worst-case 74-digit Wide span`()
        {

            let x = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 9_999_999_999_999_999_999_999_999_999_999_999
            )
            let y = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(0),
                coefficient: 34_028
            )
            let z = Decimal.Format128.encode(
                sign: .negative,
                exponent: Decimal.Exponent(73),
                coefficient: 1
            )
            let result = x.operation.fuse(y, z)
            let expected = Decimal.Format128.encode(
                sign: .negative,
                exponent: Decimal.Exponent(40),
                coefficient: 1_000_000_000_000_000_000_000_000_000_000_000
            )
            #expect(result.value != z)
            #expect(result.value == expected)
            #expect(result.status.contains(.inexact))
        }
    }
}
