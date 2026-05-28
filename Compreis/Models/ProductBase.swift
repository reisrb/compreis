import Foundation
import SwiftData

struct ProductSeed {
    let name: String
    let category: ItemCategory
    let unit: ItemUnit
}

enum ListTemplate: String, CaseIterable, Hashable {
    case empty     = "Vazia"
    case essential = "Essencial"
    case monthly   = "Do mês"

    var icon: String {
        switch self {
        case .empty:     return "doc"
        case .essential: return "cart"
        case .monthly:   return "calendar"
        }
    }

    var detail: String {
        switch self {
        case .empty: return "Em branco"
        default:     return "\(products.count) itens"
        }
    }

    var products: [ProductSeed] {
        switch self {
        case .empty:     return []
        case .essential: return ProductBase.essential
        case .monthly:   return ProductBase.monthly
        }
    }
}

enum ProductBase {

    // MARK: - Essential list

    static let essential: [ProductSeed] = [
        // Hygiene
        .init(name: "Papel higiênico",      category: .hygiene,    unit: .each),
        .init(name: "Cotonete",              category: .hygiene,    unit: .each),
        .init(name: "Algodão",               category: .hygiene,    unit: .each),
        .init(name: "Shampoo",               category: .hygiene,    unit: .each),
        .init(name: "Condicionador",         category: .hygiene,    unit: .each),
        .init(name: "Pasta de dente",        category: .hygiene,    unit: .each),
        .init(name: "Sabonete líquido",      category: .hygiene,    unit: .each),
        // Cleaning
        .init(name: "Desengordurante",       category: .cleaning,   unit: .each),
        .init(name: "Detergente",            category: .cleaning,   unit: .each),
        .init(name: "Desinfetante Sanol",    category: .cleaning,   unit: .each),
        .init(name: "Água sanitária",        category: .cleaning,   unit: .each),
        .init(name: "Bucha de cozinha",      category: .cleaning,   unit: .each),
        .init(name: "Bucha de banho",        category: .cleaning,   unit: .each),
        // Dairy
        .init(name: "Leite",                 category: .dairy,      unit: .each),
        .init(name: "Creme de leite",        category: .dairy,      unit: .each),
        // Meat
        .init(name: "Carne moída",           category: .meat,       unit: .kg),
        .init(name: "Frango",                category: .meat,       unit: .kg),
        .init(name: "Bife de fígado",        category: .meat,       unit: .kg),
        // Grocery
        .init(name: "Feijão",                category: .grocery,    unit: .each),
        .init(name: "Arroz",                 category: .grocery,    unit: .each),
        .init(name: "Óleo de soja",          category: .grocery,    unit: .each),
        .init(name: "Vinagre",               category: .grocery,    unit: .each),
        .init(name: "Macarrão",              category: .grocery,    unit: .each),
        .init(name: "Molho de tomate",       category: .grocery,    unit: .each),
        .init(name: "Extrato de tomate",     category: .grocery,    unit: .each),
        .init(name: "Ketchup",               category: .grocery,    unit: .each),
        .init(name: "Mostarda",              category: .grocery,    unit: .each),
        .init(name: "Café",                  category: .grocery,    unit: .each),
        .init(name: "Chocolate em pó",       category: .grocery,    unit: .each),
        .init(name: "Sal",                   category: .grocery,    unit: .each),
        .init(name: "Chimichurri",           category: .grocery,    unit: .each),
        .init(name: "Alho em pó",            category: .grocery,    unit: .each),
        .init(name: "Páprica defumada",      category: .grocery,    unit: .each),
        .init(name: "Bicarbonato de sódio",  category: .grocery,    unit: .each),
    ]

    // MARK: - Monthly list (essential + extras)

    static let monthly: [ProductSeed] = essential + [
        // Produce
        .init(name: "Alface",               category: .produce,    unit: .each),
        .init(name: "Tomate",               category: .produce,    unit: .kg),
        .init(name: "Cebola",               category: .produce,    unit: .kg),
        .init(name: "Cenoura",              category: .produce,    unit: .kg),
        .init(name: "Batata",               category: .produce,    unit: .kg),
        .init(name: "Banana",               category: .produce,    unit: .kg),
        .init(name: "Maçã",                 category: .produce,    unit: .kg),
        .init(name: "Laranja",              category: .produce,    unit: .kg),
        .init(name: "Limão",                category: .produce,    unit: .each),
        .init(name: "Alho",                 category: .produce,    unit: .each),
        // Dairy extras
        .init(name: "Queijo mussarela",     category: .dairy,      unit: .kg),
        .init(name: "Iogurte",              category: .dairy,      unit: .each),
        .init(name: "Manteiga",             category: .dairy,      unit: .each),
        .init(name: "Requeijão",            category: .dairy,      unit: .each),
        .init(name: "Ovo",                  category: .dairy,      unit: .each),
        // Meat extras
        .init(name: "Costela",              category: .meat,       unit: .kg),
        .init(name: "Linguiça",             category: .meat,       unit: .kg),
        // Grocery extras
        .init(name: "Açúcar",               category: .grocery,    unit: .each),
        .init(name: "Farinha de trigo",     category: .grocery,    unit: .each),
        .init(name: "Azeite",               category: .grocery,    unit: .each),
        .init(name: "Maionese",             category: .grocery,    unit: .each),
        // Bakery
        .init(name: "Pão de forma",         category: .bakery,     unit: .each),
        // Beverages
        .init(name: "Água mineral",         category: .beverages,  unit: .each),
        // Hygiene extras
        .init(name: "Fio dental",           category: .hygiene,    unit: .each),
        .init(name: "Desodorante",          category: .hygiene,    unit: .each),
        // Cleaning extras
        .init(name: "Saco de lixo",         category: .cleaning,   unit: .each),
        .init(name: "Esponja de aço",       category: .cleaning,   unit: .each),
        .init(name: "Sabão em pó",          category: .cleaning,   unit: .each),
    ]

    // MARK: - Seed (idempotent — checks DB state, not UserDefaults)

    static func seed(context: ModelContext) {
        // Catalogue: insert any product from monthly list that doesn't exist yet
        let allProducts = (try? context.fetch(FetchDescriptor<ProductHistory>())) ?? []
        let existingProducts = Set(allProducts.map { $0.name.lowercased() })
        for p in monthly where !existingProducts.contains(p.name.lowercased()) {
            context.insert(ProductHistory(name: p.name, price: 0,
                                          unit: p.unit, category: p.category))
        }

        // Predefined templates: insert any that are missing
        let existingTemplates = (try? context.fetch(FetchDescriptor<ShoppingList>(
            predicate: #Predicate { $0.isPredefined }
        ))) ?? []
        let existingTemplateNames = Set(existingTemplates.map { $0.name })

        for (name, products) in [("Essencial", essential), ("Do mês", monthly)] {
            guard !existingTemplateNames.contains(name) else { continue }
            let t = ShoppingList(name: name)
            t.isTemplate = true
            t.isPredefined = true
            for p in products {
                t.items.append(Item(name: p.name, price: 0,
                                    unit: p.unit, quantity: 1, category: p.category))
            }
            context.insert(t)
        }
    }

    // MARK: - Create items from template with historical prices

    static func createItems(for list: ShoppingList, template: ListTemplate, context: ModelContext) {
        guard template != .empty else { return }

        let history = (try? context.fetch(FetchDescriptor<ProductHistory>())) ?? []
        let map = Dictionary(uniqueKeysWithValues:
            Dictionary(grouping: history, by: { $0.name.lowercased() })
                .compactMap { k, v -> (String, ProductHistory)? in v.first.map { (k, $0) } }
        )

        // Prefer stored template (user may have edited it)
        let templateName = template.rawValue
        let storedFetch = FetchDescriptor<ShoppingList>(
            predicate: #Predicate { $0.isPredefined == true && $0.name == templateName }
        )
        let stored = (try? context.fetch(storedFetch))?.first

        let seeds: [(name: String, unit: ItemUnit, category: ItemCategory)] = stored.map { t in
            t.items.map { ($0.name, $0.unit, $0.category) }
        } ?? template.products.map { ($0.name, $0.unit, $0.category) }

        for p in seeds {
            let hist = map[p.name.lowercased()]
            list.items.append(Item(
                name: p.name,
                price: hist?.price ?? 0.0,
                unit: hist?.unit ?? p.unit,
                quantity: 1.0,
                category: p.category
            ))
        }
    }
}
