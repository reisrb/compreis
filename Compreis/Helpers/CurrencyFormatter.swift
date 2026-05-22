import Foundation

extension Double {
    var brl: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        return f.string(from: NSNumber(value: self)) ?? "0"
    }
}
