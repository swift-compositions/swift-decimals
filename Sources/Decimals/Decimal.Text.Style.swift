extension Decimal {
    public enum _TextStyle: Sendable, Hashable {

        case plain

        case scientific

        case engineering
    }
}

extension Decimal.Text {
    public typealias Style = Decimal._TextStyle
}
