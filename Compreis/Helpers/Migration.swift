import SwiftData

// MARK: - Schema V2  (current — English class names, introduced after Portuguese→English rename)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Item.self, ProductHistory.self, ShoppingList.self,
         Market.self, MarketPrice.self, CustomCategory.self]
    }
}

// MARK: - Migration plan

/// Add a new VersionedSchema + lightweight/custom MigrationStage here whenever
/// a model property or class is renamed. Never remove existing schemas.
///
/// Example for a future V3:
///   enum SchemaV3: VersionedSchema { ... }
///   static var schemas: [any VersionedSchema.Type] { [SchemaV2.self, SchemaV3.self] }
///   static var stages: [MigrationStage] {
///       [.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)]
///   }
enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV2.self] }
    static var stages: [MigrationStage] { [] }
}
