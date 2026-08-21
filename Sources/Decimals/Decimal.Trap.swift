extension Decimal {

    public struct Trap<Value>: Swift.Error, Hashable where Value: Hashable {

        public let flag: Flag

        public let status: Status

        public let value: Value

        public init(flag: Flag, status: Status, value: Value) {
            self.flag = flag
            self.status = status
            self.value = value
        }
    }
}

extension Decimal.Trap: Sendable where Value: Sendable {}
