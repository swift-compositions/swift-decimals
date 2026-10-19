import Testing

@testable import Decimals

extension Decimal.Format64 {
    @Suite struct Quantize {
        func context(_ rounding: Decimal.Rounding) -> Decimal.Context {
            var context = Decimal.Context.format64
            context.rounding = rounding
            return context
        }

        @Test func `rounding a credit up to whole euros`() {
            let credit: Decimal.Format64 = 155_533 / 100
            let outcome = credit.operation.quantize(Decimal.Exponent(0), context: context(.ceiling))
            #expect(Int64(exactly: outcome.value) == 1_556)
            #expect(outcome.status.contains(.inexact))
        }

        @Test func `rounding a rate down to two decimals`() {
            let rate: Decimal.Format64 = 342_583 / 10_000
            let outcome = rate.operation.quantize(Decimal.Exponent(-2), context: context(.down))
            #expect(Int64(exactly: outcome.value * 100) == 3_425)
        }

        @Test func `rounding half to even`() {
            let two: Decimal.Format64 = 25 / 10
            let four: Decimal.Format64 = 35 / 10
            #expect(Int64(exactly: two.operation.quantize(Decimal.Exponent(0)).value) == 2)
            #expect(Int64(exactly: four.operation.quantize(Decimal.Exponent(0)).value) == 4)
        }

        @Test func `rounding half away from zero`() {
            let value: Decimal.Format64 = 25 / 10
            #expect(Int64(exactly: value.operation.quantize(Decimal.Exponent(0), context: context(.away)).value) == 3)
        }

        @Test func `rounding a negative value toward positive infinity`() {
            let value: Decimal.Format64 = -15 / 10
            #expect(Int64(exactly: value.operation.quantize(Decimal.Exponent(0), context: context(.ceiling)).value) == -1)
        }

        @Test func `an exact value keeps its value at a smaller exponent`() {
            let value: Decimal.Format64 = 12
            let outcome = value.operation.quantize(Decimal.Exponent(-2))
            #expect(Int64(exactly: outcome.value) == 12)
            #expect(outcome.status == .none)
        }

        @Test func `a value smaller than the unit rounds to zero or one`() {
            let value: Decimal.Format64 = 4 / 1_000
            #expect(Int64(exactly: value.operation.quantize(Decimal.Exponent(0)).value) == 0)
            #expect(Int64(exactly: value.operation.quantize(Decimal.Exponent(0), context: context(.up)).value) == 1)
        }

        @Test func `too many digits is invalid`() {
            let value: Decimal.Format64 = 9_999_999_999_999_999
            let outcome = value.operation.quantize(Decimal.Exponent(-1))
            #expect(outcome.value.test.nan)
            #expect(outcome.status.contains(.invalid))
        }

        @Test func `infinity is invalid`() {
            let outcome = Decimal.Format64.infinity().operation.quantize(Decimal.Exponent(0))
            #expect(outcome.value.test.nan)
            #expect(outcome.status.contains(.invalid))
        }
    }
}
