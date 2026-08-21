import Testing

@testable import Decimals

extension Decimal.Format128 {
    @Suite struct Test {}
}

extension Decimal.Format128.Test {
    @Suite struct Text {

        @Test
        func
            `render appending does not overflow scratch buffer for large positive exponent plain style`()
        {

            let value = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(6111),
                coefficient: 1
            )
            var buffer: [UInt8] = []
            value.text.render(appending: &buffer, style: .plain)
            let rendered = String(decoding: buffer, as: UTF8.self)
            #expect(rendered.hasPrefix("1"))
            #expect(rendered.count == 1 + 6111)
        }

        @Test
        func
            `render appending does not overflow scratch buffer for min negative exponent plain style`()
        {
            let value = Decimal.Format128.encode(
                sign: .negative,
                exponent: Decimal.Exponent.Format128.min,
                coefficient: 1
            )
            var buffer: [UInt8] = []
            value.text.render(appending: &buffer, style: .plain)
            let rendered = String(decoding: buffer, as: UTF8.self)
            #expect(rendered.hasPrefix("-0."))
        }

        @Test func `render into traps when buffer is smaller than required capacity`() {
            let value = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(6111),
                coefficient: 1
            )
            let needed = value.text.requiredCapacity(style: .plain)
            #expect(needed > 64)
        }

        @Test func `parse exponent digit overflow resolves to high instead of trapping`() {

            #expect(throws: Decimal._TextError.high) {
                _ = try Decimal.Format128.text([UInt8]("1E9999999999999999999999999".utf8))
            }
        }

        @Test func `parse NaN rejects trailing garbage`() {
            #expect(throws: Decimal._TextError.self) {
                _ = try Decimal.Format128.text([UInt8]("NaN123garbage".utf8))
            }
        }

        @Test func `parse NaN preserves sign`() throws {
            let value = try Decimal.Format128.text([UInt8]("-NaN".utf8))
            #expect(value.test.nan)
            #expect(value.test.negative)
        }

        @Test func `parse rounds over precision coefficient instead of corrupting encoding`() throws
        {

            let value = try Decimal.Format128.text(
                [UInt8]((String(repeating: "1", count: 34) + "7").utf8)
            )
            let expected = Decimal.Format128.encode(
                sign: .positive,
                exponent: Decimal.Exponent(1),
                coefficient: UInt128(String(repeating: "1", count: 33) + "2")!
            )
            #expect(value == expected)
        }
    }
}
