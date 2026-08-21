extension Decimal {
    public enum Clamp: Sendable, Hashable {

        case none

        case preferred
    }
}

extension Decimal.Clamp {
    public static var `default`: Self { .none }
}
