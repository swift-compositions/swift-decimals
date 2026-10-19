import Testing

@testable import Decimals

extension Decimal.Format32 {
    @Suite struct Literal {
        @Test func `a literal within seven digits is exact`() {
            let value: Decimal.Format32 = 9_999_999
            #expect(value.extractCoefficient() == 9_999_999)
            #expect(value.extractExponent() == Decimal.Exponent(0))
        }

        @Test func `an eight digit literal rounds to seven digits`() {
            let value: Decimal.Format32 = 12_345_678
            #expect(value.extractCoefficient() == 1_234_568)
            #expect(value.extractExponent() == Decimal.Exponent(1))
        }

        @Test func `a literal rounds half to even`() {
            let value: Decimal.Format32 = 10_000_005
            #expect(value.extractCoefficient() == 1_000_000)
            #expect(value.extractExponent() == Decimal.Exponent(1))
        }

        @Test func `the extreme literals round instead of trapping`() {
            let largest = Decimal.Format32(integerLiteral: .max)
            #expect(largest.extractCoefficient() == 2_147_484)
            #expect(largest.extractExponent() == Decimal.Exponent(3))
            let smallest = Decimal.Format32(integerLiteral: .min)
            #expect(smallest.sign == .minus)
            #expect(smallest.extractCoefficient() == 2_147_484)
            #expect(smallest.extractExponent() == Decimal.Exponent(3))
        }

        @Test func `a negative literal keeps its sign`() {
            let value: Decimal.Format32 = -42
            #expect(value.sign == .minus)
            #expect(value.extractCoefficient() == 42)
        }
    }
}
