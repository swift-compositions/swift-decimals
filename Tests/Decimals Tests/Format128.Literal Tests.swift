import Testing

@testable import Decimals

extension Decimal.Format128 {
    @Suite struct Literal {
        @Test func `every sixty-four bit literal is exact`() {
            let largest = Decimal.Format128(integerLiteral: .max)
            #expect(largest.extractCoefficient() == 9_223_372_036_854_775_807)
            #expect(largest.extractExponent() == Decimal.Exponent(0))
        }

        @Test func `the smallest literal keeps its magnitude instead of trapping`() {
            let smallest = Decimal.Format128(integerLiteral: .min)
            #expect(smallest.sign == .minus)
            #expect(smallest.extractCoefficient() == 9_223_372_036_854_775_808)
            #expect(smallest.extractExponent() == Decimal.Exponent(0))
        }

        @Test func `a negative literal keeps its sign`() {
            let value: Decimal.Format128 = -42
            #expect(value.sign == .minus)
            #expect(value.extractCoefficient() == 42)
        }
    }
}
