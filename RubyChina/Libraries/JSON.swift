import SwiftyJSON

extension JSON {
    public init(_ object: Any?) {
        self.init(object ?? NSNull())
    }
}
