import Testing

@testable import Decimals

extension Decimal.Format128 {
    @Suite struct FloatingPoint {
        func value(_ coefficient: UInt128, _ exponent: Int, _ sign: FloatingPointSign = .plus) -> Decimal.Format128 {
            .encode(sign: sign, exponent: Decimal.Exponent(exponent), coefficient: coefficient)
        }

        @Test func `the radix is ten`() {
            #expect(Decimal.Format128.radix == 10)
        }

        @Test func `exponent and significand decompose a value in base ten`() {
            let amount = value(155_533, -2)
            #expect(amount.exponent == 3)
            #expect(amount.significand == value(155_533, -5))
            #expect(Decimal.Format128(sign: .plus, exponent: amount.exponent, significand: amount.significand) == amount)
            #expect(Decimal.Format128(sign: .minus, exponent: 2, significand: 3) == -300)
        }

        @Test(arguments: [
            (FloatingPointRoundingRule.up, 1_556 as Int64),
            (.down, 1_555),
            (.towardZero, 1_555),
            (.awayFromZero, 1_556),
            (.toNearestOrEven, 1_555),
            (.toNearestOrAwayFromZero, 1_555),
        ])
        func `rounding to an integer follows each standard rule`(rule: FloatingPointRoundingRule, expected: Int64) {
            #expect(value(155_533, -2).rounded(rule) == Decimal.Format128(integerLiteral: expected))
        }

        @Test func `halfway values round to even or away as the rule says`() {
            #expect(value(25, -1).rounded(.toNearestOrEven) == 2)
            #expect(value(35, -1).rounded(.toNearestOrEven) == 4)
            #expect(value(25, -1).rounded(.toNearestOrAwayFromZero) == 3)
            #expect(value(25, -1, .minus).rounded(.down) == -3)
            #expect(value(3, -1, .minus).rounded(.towardZero).sign == .minus)
        }

        @Test func `the square root is exact when it can be and correctly rounded otherwise`() {
            #expect(Decimal.Format128(144).squareRoot() == 12)
            #expect(value(225, -2).squareRoot() == value(15, -1))
            #expect(Decimal.Format128(2).squareRoot() == value(1_414_213_562_373_095_048_801_688_724_209_698, -33))
            #expect(Decimal.Format128(3).squareRoot() == value(1_732_050_807_568_877_293_527_446_341_505_872, -33))
            #expect(Decimal.Format128(-4).squareRoot().isNaN)
            #expect((-Decimal.Format128.infinity).squareRoot().isNaN)
        }

        @Test func `the IEEE remainder rounds the quotient to nearest even`() {
            #expect(Decimal.Format128(7).remainder(dividingBy: 2) == -1)
            #expect(Decimal.Format128(5).remainder(dividingBy: 2) == 1)
            #expect(Decimal.Format128(7).truncatingRemainder(dividingBy: 2) == 1)
            #expect(value(1_000_000, 0).truncatingRemainder(dividingBy: value(3, -1)) == value(1, -1))
            #expect(Decimal.Format128(1).remainder(dividingBy: value(1, 40)) == 1)
            #expect(Decimal.Format128(1).remainder(dividingBy: value(1_000_000_000_000_000_000_000_000_000_000_000, 5)) == 1)
        }

        @Test func `next up and ulp step by one unit in the last place`() {
            #expect(Decimal.Format128(1).nextUp == value(1_000_000_000_000_000_000_000_000_000_000_001, -33))
            #expect(Decimal.Format128(-1).nextUp == value(9_999_999_999_999_999_999_999_999_999_999_999, -34, .minus))
            #expect(Decimal.Format128(1).ulp == Decimal.Format128.ulpOfOne)
            #expect(Decimal.Format128.zero.nextUp == Decimal.Format128.leastNonzeroMagnitude)
            #expect(Decimal.Format128.greatestFiniteMagnitude.nextUp == .infinity)
        }

        @Test func `integers beyond thirty-four digits round instead of trapping`() {
            #expect(Decimal.Format128(UInt128.max) == value(3_402_823_669_209_384_634_633_746_074_317_682, 5))
            #expect(Decimal.Format128(Int128.min) == value(1_701_411_834_604_692_317_316_873_037_158_841, 5, .minus))
        }

        @Test func `comparison follows IEEE, not total order`() {
            #expect(!(Decimal.Format128.zero(sign: .minus) < .zero))
            let notANumber = Decimal.Format128.nan
            #expect(!(notANumber < 1))
            #expect(!(Decimal.Format128(1) < notANumber))
            #expect(Decimal.Format128.zero(sign: .minus).isTotallyOrdered(belowOrEqualTo: .zero))
            #expect(Decimal.Format128(1) < 2)
        }

        @Test func `generic floating-point code accepts decimals`() {
            func half<T: Swift.FloatingPoint>(_ value: T) -> T { value / 2 }
            #expect(half(Decimal.Format128(3)) == value(15, -1))
        }
    }
}
