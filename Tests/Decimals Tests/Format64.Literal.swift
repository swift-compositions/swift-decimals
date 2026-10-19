import Testing

@testable import Decimals

extension Decimal.Format64 {
    @Suite struct Literal {
        @Test func `a literal within sixteen digits is exact`() {
            let value: Decimal.Format64 = 9_999_999_999_999_999
            #expect(value.extractCoefficient() == 9_999_999_999_999_999)
            #expect(value.extractExponent() == Decimal.Exponent(0))
        }

        @Test func `a seventeen digit literal rounds to sixteen digits`() {
            let value: Decimal.Format64 = 12_345_678_901_234_567
            #expect(value.extractCoefficient() == 1_234_567_890_123_457)
            #expect(value.extractExponent() == Decimal.Exponent(1))
        }

        @Test func `a literal rounds half to even`() {
            let value: Decimal.Format64 = 10_000_000_000_000_005
            #expect(value.extractCoefficient() == 1_000_000_000_000_000)
            #expect(value.extractExponent() == Decimal.Exponent(1))
        }

        @Test func `the largest literal rounds instead of trapping`() {
            let value = Decimal.Format64(integerLiteral: .max)
            #expect(value.extractCoefficient() == 9_223_372_036_854_776)
            #expect(value.extractExponent() == Decimal.Exponent(3))
        }

        @Test func `a negative literal keeps its sign`() {
            let value: Decimal.Format64 = -42
            #expect(value.sign == .negative)
            #expect(value.extractCoefficient() == 42)
        }
    }
}
