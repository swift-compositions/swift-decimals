import Testing

@testable import Decimals

extension Decimal.Format32 {
    @Suite struct FloatingPoint {
        func value(_ coefficient: UInt32, _ exponent: Int, _ sign: FloatingPointSign = .plus) -> Decimal.Format32 {
            .encode(sign: sign, exponent: Decimal.Exponent(exponent), coefficient: coefficient)
        }

        @Test func `the radix is ten`() {
            #expect(Decimal.Format32.radix == 10)
        }

        @Test func `exponent and significand decompose a value in base ten`() {
            let amount = value(155_533, -2)
            #expect(amount.exponent == 3)
            #expect(amount.significand == value(155_533, -5))
            #expect(Decimal.Format32(sign: .plus, exponent: amount.exponent, significand: amount.significand) == amount)
            #expect(Decimal.Format32(sign: .minus, exponent: 2, significand: 3) == -300)
        }

        @Test(arguments: [
            (FloatingPointRoundingRule.up, 1_556 as Int32),
            (.down, 1_555),
            (.towardZero, 1_555),
            (.awayFromZero, 1_556),
            (.toNearestOrEven, 1_555),
            (.toNearestOrAwayFromZero, 1_555),
        ])
        func `rounding to an integer follows each standard rule`(rule: FloatingPointRoundingRule, expected: Int32) {
            #expect(value(155_533, -2).rounded(rule) == Decimal.Format32(integerLiteral: expected))
        }

        @Test func `halfway values round to even or away as the rule says`() {
            #expect(value(25, -1).rounded(.toNearestOrEven) == 2)
            #expect(value(35, -1).rounded(.toNearestOrEven) == 4)
            #expect(value(25, -1).rounded(.toNearestOrAwayFromZero) == 3)
            #expect(value(25, -1, .minus).rounded(.down) == -3)
            #expect(value(3, -1, .minus).rounded(.towardZero).sign == .minus)
        }

        @Test func `the square root is exact when it can be and correctly rounded otherwise`() {
            #expect(Decimal.Format32(144).squareRoot() == 12)
            #expect(value(225, -2).squareRoot() == value(15, -1))
            #expect(Decimal.Format32(2).squareRoot() == value(1_414_214, -6))
            #expect(Decimal.Format32(-4).squareRoot().isNaN)
            #expect((-Decimal.Format32.infinity).squareRoot().isNaN)
        }

        @Test func `the IEEE remainder rounds the quotient to nearest even`() {
            #expect(Decimal.Format32(7).remainder(dividingBy: 2) == -1)
            #expect(Decimal.Format32(5).remainder(dividingBy: 2) == 1)
            #expect(Decimal.Format32(7).truncatingRemainder(dividingBy: 2) == 1)
            #expect(value(1_000_000, 0).truncatingRemainder(dividingBy: value(3, -1)) == value(1, -1))
            #expect(Decimal.Format32(1).remainder(dividingBy: value(1, 20)) == 1)
        }

        @Test func `next up and ulp step by one unit in the last place`() {
            #expect(Decimal.Format32(1).nextUp == value(1_000_001, -6))
            #expect(Decimal.Format32(-1).nextUp == value(9_999_999, -7, .minus))
            #expect(Decimal.Format32(1).ulp == Decimal.Format32.ulpOfOne)
            #expect(Decimal.Format32.zero.nextUp == Decimal.Format32.leastNonzeroMagnitude)
            #expect(Decimal.Format32.greatestFiniteMagnitude.nextUp == .infinity)
        }

        @Test func `integers beyond seven digits round instead of trapping`() {
            #expect(Decimal.Format32(Int.max) == value(9_223_372, 12))
            #expect(Decimal.Format32(UInt64.max) == value(1_844_674, 13))
            #expect(Decimal.Format32(exactly: 12_345_678) == nil)
            #expect(Decimal.Format32(exactly: 12_345_670) == value(1_234_567, 1))
        }

        @Test func `comparison follows IEEE, not total order`() {
            #expect(!(Decimal.Format32.zero(sign: .minus) < .zero))
            let notANumber = Decimal.Format32.nan
            #expect(!(notANumber < 1))
            #expect(!(Decimal.Format32(1) < notANumber))
            #expect(Decimal.Format32.zero(sign: .minus).isTotallyOrdered(belowOrEqualTo: .zero))
            #expect(Decimal.Format32(1) < 2)
        }

        @Test func `generic floating-point code accepts decimals`() {
            func half<T: Swift.FloatingPoint>(_ value: T) -> T { value / 2 }
            #expect(half(Decimal.Format32(3)) == value(15, -1))
        }
    }
}
