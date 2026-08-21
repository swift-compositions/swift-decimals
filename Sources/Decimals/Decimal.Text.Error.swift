extension Decimal {
    public enum _TextError: Swift.Error, Sendable, Hashable {

        case empty

        case syntax(offset: Int)

        case high

        case low
    }
}

extension Decimal.Text {
    public typealias Error = Decimal._TextError
}
