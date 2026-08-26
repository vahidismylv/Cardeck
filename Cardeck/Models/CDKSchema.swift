//
//  CDKSchema.swift
//  Cardeck
//

import Foundation
import SwiftData

/// Первая версия схемы хранилища.
///
/// Версионирование заведено сразу, хотя миграций пока нет: добавить его задним
/// числом, когда на устройствах уже лежат данные, заметно дороже.
public enum CDKSchemaV1: VersionedSchema {

    public static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    public static var models: [any PersistentModel.Type] { [CDKCard.self] }
}

/// План миграций схемы.
///
/// Пока содержит одну версию и ни одного этапа. Новая версия добавляется в
/// ``schemas``, переход между версиями — в ``stages``.
public enum CDKMigrationPlan: SchemaMigrationPlan {

    public static var schemas: [any VersionedSchema.Type] { [CDKSchemaV1.self] }

    public static var stages: [MigrationStage] { [] }
}

/// Сборка контейнера SwiftData.
public enum CDKModelContainerFactory {

    /// Результат создания контейнера.
    public struct Result {
        /// Готовый контейнер.
        public let container: ModelContainer
        /// Данные лежат только в памяти: диск оказался недоступен.
        public let isEphemeral: Bool
    }

    /// Создаёт контейнер на диске, а при неудаче — в памяти.
    ///
    /// Диск может быть заполнен или файл повреждён. Ронять приложение из-за этого
    /// нельзя: карты нужны у кассы прямо сейчас, поэтому работаем в памяти
    /// и сообщаем об этом флагом ``Result/isEphemeral``.
    public static func make(inMemory: Bool = false) -> Result {
        let schema = Schema(versionedSchema: CDKSchemaV1.self)
        if !inMemory, let container = try? makeContainer(schema: schema, inMemory: false) {
            return Result(container: container, isEphemeral: false)
        }
        if let container = try? makeContainer(schema: schema, inMemory: true) {
            return Result(container: container, isEphemeral: true)
        }
        // Контейнер не собрался даже в памяти — дальше работать не с чем.
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
