import Testing

@testable import Decimals

@Suite
struct `Leading zeros in text` {
    private static let text = String(repeating: "0", count: 40) + "1"

    @Test
    func `leading zeros do not use up a Format32 coefficient`() throws {
        #expect(try Decimal.Format32.text([UInt8](Self.text.utf8)) == Decimal.Format32.text([UInt8]("1".utf8)))
    }

    @Test
    func `leading zeros do not use up a Format64 coefficient`() throws {
        #expect(try Decimal.Format64.text([UInt8](Self.text.utf8)) == Decimal.Format64.text([UInt8]("1".utf8)))
    }

    @Test
    func `leading zeros do not use up a Format128 coefficient`() throws {
        #expect(try Decimal.Format128.text([UInt8](Self.text.utf8)) == Decimal.Format128.text([UInt8]("1".utf8)))
    }

    @Test
    func `leading zeros before a fraction keep its digits`() throws {
        let value = try Decimal.Format64.text([UInt8]((String(repeating: "0", count: 40) + "12.5").utf8))
        #expect(Int64(exactly: value + value) == 25)
    }
}
