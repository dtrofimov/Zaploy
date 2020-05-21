//
//  CoreDataSoupMetadataFactory.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 06.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData
import MobileSync
import Then

class CoreDataSoupMetadataFactory {
    struct Keys {
        static let entitySfName = "sfName"
        static let fieldSfName = "sfName"
        static let idFieldName = kId // "Id"
        static let syncIdFieldName = kSyncTargetSyncId // "__sync_id__"
        static let isUnique = "isUnique"
    }

    let entity: NSEntityDescription
    let sfMetadata: Metadata
    let soupEntryIdConverter: SoupEntryIdConverter
    let warningLogger: WarningLogger

    internal init(entity: NSEntityDescription, sfMetadata: Metadata, soupEntryIdConverter: SoupEntryIdConverter, warningLogger: WarningLogger) {
        self.entity = entity
        self.sfMetadata = sfMetadata
        self.soupEntryIdConverter = soupEntryIdConverter
        self.warningLogger = warningLogger
    }

    public enum CustomError: Error {
        case validIdFieldNotFound
    }

    lazy var sfFieldsForNames: [String: SFField] = (sfMetadata.fields ?? []).reduce(into: [:]) { result, fieldDict in
        guard let sfField = warningLogger.handle({
            try SFField(metadata: fieldDict)
        }, "Cannot create field metadata: \(fieldDict)")
            else { return }
        result[sfField.name] = sfField
    }

    typealias SFIdField = FetchableField & HavingMOField

    var sfIdField: SFIdField?
    var otherUniqueFields: [FetchableField] = []
    var fieldMappers: [EntryMapper] = []
    var sfFieldsForMOFields: [MOField: SFField] = [:]

    struct Output {
        let metadata: CoreDataSoupMetadata
        let soupMapper: EntryMapper
    }

    lazy var output: Result<Output, Error> = Result {
        processAllMetadata()

        let soupEntryIdField = resolveSoupEntryIdMapper()
        fieldMappers.append(soupEntryIdField)

        guard let sfIdField = sfIdField else {
            throw CustomError.validIdFieldNotFound
        }

        return Output(metadata: .init(entity: entity,
                                      sfIdField: sfIdField,
                                      soupEntryIdField: soupEntryIdField,
                                      otherUniqueFields: otherUniqueFields,
                                      sfFieldsForMOFields: sfFieldsForMOFields),
                      soupMapper: CompoundEntryMapper(childMappers: fieldMappers))
    }

    open func processAllMetadata() {
        if let attributesMapper = resolveAttributesMapper() {
            fieldMappers.append(attributesMapper)
        }
        for moField in entity.properties {
            process(moField: moField)
        }
    }

    open func process(moField: MOField) {
        guard let sfName = moField.sfName else { return }
        let sfField = sfFieldsForNames[sfName]
        guard let fieldMapper = Self.makeMapper(moField: moField,
                                                sfName: sfName,
                                                sfField: sfField,
                                                warningLogger: warningLogger)
            else { return }
        fieldMappers.append(fieldMapper)
        sfFieldsForMOFields[moField] = sfField

        if sfName == Keys.idFieldName {
            if let sfIdField = fieldMapper as? SFIdField {
                if let existingSfIdField = self.sfIdField {
                    warningLogger.logWarning("SFIdField duplicate found: \(existingSfIdField) vs \(sfIdField)")
                } else {
                    self.sfIdField = sfIdField
                }
            } else {
                warningLogger.logWarning("Id mapper type doesn't correspond to SFIdField: \(fieldMapper)")
            }
        } else if moField.isMarkedUnique {
            if let uniqueMapper = fieldMapper as? FetchableField {
                otherUniqueFields.append(uniqueMapper)
            } else {
                warningLogger.logWarning("Unique mapper type doesn't correspond to FetchableField: \(fieldMapper)")
            }
        }
    }

    open class func makeMapper(moField: MOField, sfName: String, sfField: SFField?, warningLogger: WarningLogger) -> EntryMapper? {
        // TODO: Handle all available SF field types.
        func incompatible() -> EntryMapper? {
            warningLogger.logWarning("Incompatible CoreData and SF field types: \(moField)")
            return nil
        }
        let moFieldType = (moField as? NSAttributeDescription)?.attributeType

        if sfName == Keys.syncIdFieldName {
            guard moFieldType == .integer64AttributeType else { return incompatible() }
            return SyncIdMapper(moField: moField, sfKey: sfName, warningLogger: warningLogger)
        }

        guard let sfField = sfField else {
            warningLogger.logWarning("SF metadata not found for field \(moField)")
            return nil
        }

        switch sfField.type {
        case .id, .string:
            // TODO: Check id metadata type with Keys.idFieldName matching
            guard moFieldType == .stringAttributeType else { return incompatible() }
            return StringField(moField: moField, sfField: sfField, warningLogger: warningLogger)
        case .boolean:
            guard moFieldType == .booleanAttributeType else { return incompatible() }
            return BoolField(moField: moField, sfField: sfField, warningLogger: warningLogger)
        case .double, .int:
            switch moFieldType {
            case .integer16AttributeType,
                 .integer32AttributeType,
                 .integer64AttributeType,
                 .decimalAttributeType,
                 .doubleAttributeType,
                 .floatAttributeType:
                break
            default: return incompatible()
            }
            return NumberField(moField: moField, sfField: sfField, warningLogger: warningLogger)
        default:
            return incompatible()
        }
    }

    open func resolveSoupEntryIdMapper() -> EntryMapper & FetchableField {
        SoupEntryIdMapper(soupEntryIdConverter: soupEntryIdConverter, warningLogger: warningLogger)
    }

    open func resolveAttributesMapper() -> EntryMapper? {
        guard let sfName = entity.sfName else {
            warningLogger.logWarning("Entity sfName not found")
            return nil
        }
        return AttributesMapper(entity: entity, entitySfName: sfName, warningLogger: warningLogger)
    }
}

extension NSPropertyDescription {
    var isMarkedUnique: Bool {
        userInfo?[CoreDataSoupMetadataFactory.Keys.isUnique] as? Bool ?? false
    }

    var sfName: String? {
        userInfo?[CoreDataSoupMetadataFactory.Keys.fieldSfName] as? String
    }
}

extension NSEntityDescription {
    var sfName: String? {
        userInfo?[CoreDataSoupMetadataFactory.Keys.entitySfName] as? String
    }
}
