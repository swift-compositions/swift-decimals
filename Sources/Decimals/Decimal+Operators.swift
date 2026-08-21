extension Decimal.Format64 {
    public static func / (lhs: Self, rhs: Self) -> Self {
        lhs.operation.divide(rhs).value
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }
}

extension Decimal.Format64: @retroactive Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.operation.precedes(rhs)
    }
}

extension Decimal.Format32 {
    public static func / (lhs: Self, rhs: Self) -> Self {
        lhs.operation.divide(rhs).value
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }
}

extension Decimal.Format32: @retroactive Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.operation.precedes(rhs)
    }
}

extension Decimal.Format128 {
    public static func / (lhs: Self, rhs: Self) -> Self {
        lhs.operation.divide(rhs).value
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }
}

extension Decimal.Format128: @retroactive Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.operation.precedes(rhs)
    }
}
