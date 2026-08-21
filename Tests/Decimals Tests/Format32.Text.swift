import Testing

@testable import Decimals

extension Decimal.Format32 {
    @Suite struct Test {}
}

extension Decimal.Format32.Test {
    @Suite struct Text {

        @Test
        func
            `render appending does not overflow scratch buffer for large positive exponent plain style`()
        {

            let value = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(90),
                coefficient: 1
            )
            var buffer: [UInt8] = []
            value.text.render(appending: &buffer, style: .plain)
            let rendered = String(decoding: buffer, as: UTF8.self)
            #expect(rendered.hasPrefix("1"))
            #expect(rendered.count == 1 + 90)
        }

        @Test
        func
            `render appending does not overflow scratch buffer for min negative exponent plain style`()
        {
            let value = Decimal.Format32.encode(
                sign: .negative,
                exponent: Decimal.Exponent.Format32.min,
                coefficient: 1
            )
            var buffer: [UInt8] = []
            value.text.render(appending: &buffer, style: .plain)
            let rendered = String(decoding: buffer, as: UTF8.self)
            #expect(rendered.hasPrefix("-0."))
        }

        @Test func `render into traps when buffer is smaller than required capacity`() {
            let value = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(90),
                coefficient: 1
            )
            let needed = value.text.requiredCapacity(style: .plain)
            #expect(needed > 32)
        }

        @Test func `parse exponent digit overflow resolves to high instead of trapping`() {

            #expect(throws: Decimal._TextError.high) {
                _ = try Decimal.Format32.text([UInt8]("1E9999999999999999999999999".utf8))
            }
        }

        @Test func `parse NaN rejects trailing garbage`() {
            #expect(throws: Decimal._TextError.self) {
                _ = try Decimal.Format32.text([UInt8]("NaN123garbage".utf8))
            }
        }

        @Test func `parse NaN preserves sign`() throws {
            let value = try Decimal.Format32.text([UInt8]("-NaN".utf8))
            #expect(value.test.nan)
            #expect(value.test.negative)
        }

        @Test func `parse rounds over precision coefficient instead of corrupting encoding`() throws
        {

            let value = try Decimal.Format32.text([UInt8]("12345677".utf8))
            let expected = Decimal.Format32.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: 1_234_568
            )
            #expect(value == expected)
        }
    }
}
