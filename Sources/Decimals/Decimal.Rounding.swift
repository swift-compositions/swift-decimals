extension Decimal {
    public enum Rounding: Sendable, Hashable, CaseIterable {

        case ceiling

        case floor

        case down

        case up

        case even

        case away

        case toward
    }
}

extension Decimal.Rounding {
    public static var `default`: Self { .even }
}
