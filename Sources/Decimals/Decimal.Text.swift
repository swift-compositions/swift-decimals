extension Decimal {

    public struct Text<Value> {
        @usableFromInline
        let base: Value

        @usableFromInline
        internal init(_ base: Value) {
            self.base = base
        }
    }
}

extension Decimal.Text: Sendable where Value: Sendable {}

extension Decimal.Text {

    public struct Parse {
        @usableFromInline
        internal init() {}
    }
}

extension Decimal.Text.Parse: Sendable {}

extension Decimal.Format64 {

    public var text: Decimal.Text<Self> {
        Decimal.Text(self)
    }

    public static var text: Decimal.Text<Self>.Parse {
        Decimal.Text<Self>.Parse()
    }
}

extension Decimal.Format32 {

    public var text: Decimal.Text<Self> {
        Decimal.Text(self)
    }

    public static var text: Decimal.Text<Self>.Parse {
        Decimal.Text<Self>.Parse()
    }
}

extension Decimal.Format128 {

    public var text: Decimal.Text<Self> {
        Decimal.Text(self)
    }

    public static var text: Decimal.Text<Self>.Parse {
        Decimal.Text<Self>.Parse()
    }
}
