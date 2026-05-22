import Foundation

extension Double {
    var brl: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f.string(from: NSNumber(value: self)) ?? "R$ 0,00"
    }
}
