extension Decimal {

    public enum Tininess: Sendable, Hashable {

        case before

        case after
    }
}

extension Decimal.Tininess {
    public static var `default`: Self { .after }
}
