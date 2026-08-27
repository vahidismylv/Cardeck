import Foundation
import SwiftData

public enum CDKSchemaV1: VersionedSchema {

    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public static var models: [any PersistentModel.Type] { [CDKCard.self] }
}

public enum CDKMigrationPlan: SchemaMigrationPlan {

    public static var schemas: [any VersionedSchema.Type] { [CDKSchemaV1.self] }

    public static var stages: [MigrationStage] { [] }
}

public enum CDKModelContainerFactory {

    public struct Result {

        public let container: ModelContainer

        public let isEphemeral: Bool
    }

    public static func make(inMemory: Bool = false) -> Result {
        let schema = Schema(versionedSchema: CDKSchemaV1.self)
        if !inMemory, let container = try? makeContainer(schema: schema, inMemory: false) {
            return Result(container: container, isEphemeral: false)
        }
        if let container = try? makeContainer(schema: schema, inMemory: true) {
            return Result(container: container, isEphemeral: true)
        }

        fatalError("Не удалось создать ModelContainer ни на диске, ни в памяти")
    }

    private static func makeContainer(
        schema: Schema,
        inMemory: Bool
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: schema,
            migrationPlan: CDKMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
