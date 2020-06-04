//
//  CoreDataSoupMetadataFactory.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 06.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData
import MobileSync

class CoreDataSoupMetadataFactory {
    struct Keys {
        static let entitySfName = "sfName"
        static let fieldSfName = "sfName"
        static let id = kId // "Id"
        static let syncId = kSyncTargetSyncId // "__sync_id__"
        static let isUnique = "isUnique"
        static let urlFieldName = "urlField"
        static let shouldRemoveUnlinked = "shouldRemoveUnlinked"
        static let shouldUnlinkAbsent = "shouldUnlinkAbsent"
    }

    let entity: NSEntityDescription
    let sfMetadata: Metadata
    let soupEntryIdConverter: SoupEntryIdConverter
    let warningLogger: WarningLogger

    internal init(entity: NSEntityDescription,
                  sfMetadata: Metadata,
                  soupEntryIdConverter: SoupEntryIdConverter,
                  warningLogger: WarningLogger) {
        self.entity = entity
        self.sfMetadata = sfMetadata
        self.soupEntryIdConverter = soupEntryIdConverter
        self.warningLogger = warningLogger
    }

    public enum CustomError: Error {
        case validIdFieldNotFound
    }

    lazy var sfFieldsForNames: [String: SFField] = (sfMetadata.fields ?? []).reduce(into: [:]) { result, fieldDict in
        guard let sfField = (Result { try SFField(metadata: fieldDict) })
            .check(warningLogger, "Cannot create field metadata: \(fieldDict)")
            else { return }
        result[sfField.name] = sfField
    }

    lazy var sfChildRelationshipsForNames: [String: SFChildRelationship] = (sfMetadata.childRelationships ?? []).reduce(into: [:]) { result, childRelationshipDict in
        guard let sfChildRelationship = (Result { try SFChildRelationship(metadata: childRelationshipDict) })
            .check(warningLogger, "Cannot create child relationship metadata: \(childRelationshipDict)")
            else { return }
        result[sfChildRelationship.name] = sfChildRelationship
    }

    typealias SFIdField = FetchableField & HavingMOField

    lazy var sfName: String? = entity.sfName
    var sfIdField: SFIdField?
    var syncIdField: FetchableField?
    var otherUniqueFields: [FetchableField] = []
    var fieldMappers: [EntryMapper] = []
    var sfFieldsForMOFields: [MOField: SFField] = [:]

    lazy var metadata: Result<CoreDataSoupMetadata, Error> = Result {
        processAllMetadata()

        guard let sfIdField = sfIdField else {
            throw CustomError.validIdFieldNotFound
        }

        return .init(
            entity: entity,
            sfName: sfName,
            sfIdField: sfIdField,
            soupEntryIdField: soupEntryIdMapper,
            syncIdField: syncIdField,
            attributesMapper: attributesMapper,
            otherUniqueFields: otherUniqueFields,
            sfFieldsForMOFields: sfFieldsForMOFields,
            soupMapper: CompoundEntryMapper(childMappers: fieldMappers)
        )
    }

    open func processAllMetadata() {
        if let attributesMapper = attributesMapper {
            fieldMappers.append(attributesMapper)
        }
        fieldMappers.append(soupEntryIdMapper)

        for moField in entity.properties {
            process(moField: moField)
        }
    }

    open func process(moField: MOField) {
        let sfName = moField.sfName
        let sfField = sfName.flatMap { sfFieldsForNames[$0] }
        guard let fieldMapper = makeMapper(moField: moField,
                                           sfName: sfName,
                                           sfField: sfField)
            else { return }
        fieldMappers.append(fieldMapper)
        sfFieldsForMOFields[moField] = sfField

        if sfName == Keys.id {
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

    open func makeMapper(moField: MOField, sfName: String?, sfField: SFField?) -> EntryMapper? {
        guard let sfName = sfName else { return nil }
        // TODO: Handle all available SF field types.
        func failure(_ message: String) -> EntryMapper? {
            warningLogger.logWarning(message)
            return nil
        }
        func incompatible() -> EntryMapper? {
            failure("Incompatible CoreData and SF field types: \(moField)")
        }
        if let moAttribute = moField as? NSAttributeDescription {
            let moFieldType = moAttribute.attributeType

            if sfName == Keys.syncId {
                guard moFieldType == .integer64AttributeType else { return incompatible() }
                let syncIdMapper = SyncIdMapper(moField: moField, sfKey: sfName, warningLogger: warningLogger)
                self.syncIdField = syncIdMapper
                return syncIdMapper
            }

            guard let sfField = sfField else { return failure("SF metadata not found for field \(moField)") }

            switch sfField.type {
            case .anyType:
                guard moFieldType == .transformableAttributeType else { return incompatible() }
                return BaseField(moField: moField, sfField: sfField, warningLogger: warningLogger)
            case .base64:
                guard moFieldType == .transformableAttributeType else { return incompatible() }
                guard let urlFieldName = moField.userInfo?[Keys.urlFieldName] as? String else { return failure("Base64 URL field name not found: \(moField)") }
                guard let urlMoField = entity.propertiesByName[urlFieldName] else { return failure("Base64 URL field not found: \(moField)") }
                guard (urlMoField as? NSAttributeDescription)?.attributeType == .stringAttributeType else { return failure("Base64 URL field must be of string type: \(moField)")}
                return Base64Field(bodyMoField: moField, urlMoField: urlMoField, sfField: sfField, warningLogger: warningLogger)
            case .currency:
                guard moFieldType == .decimalAttributeType else { return incompatible() }
                guard let scale = sfField.scale else { return failure("Currency scale not found: \(moField), \(sfField.metadata)")}
                return CurrencyField(moField: moField, sfField: sfField, warningLogger: warningLogger, scale: scale)
            case .id, .string, .reference:
                if warningLogger.isEnabled {
                    let isIdType = sfField.type == .id
                    let isIdField = sfField.name == Keys.id
                    warningLogger.assert(isIdType == isIdField,
                                         "Id type doesn't match with id field name: isIdType = \(isIdType), isIdField = \(isIdField), field = \(moField)")
                }
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
        } else if let moRelationship = moField as? NSRelationshipDescription {
            if moRelationship.isToMany {
                guard let sfChildRelationship = sfChildRelationshipsForNames[sfName] else { return failure("SF metadata not found for child relationship \(sfName)") }
                return ChildRelationship(moRelationship: moRelationship,
                                         sfChildRelationship: sfChildRelationship,
                                         shouldUnlinkAbsent: moRelationship.isMarkedShouldUnlinkAbsent,
                                         shouldRemoveUnlinked: moRelationship.isMarkedShouldRemoveUnlinked,
                                         warningLogger: warningLogger)
            } else {
                guard let sfField = sfField else { return failure("SF metadata not found for relationship \(moRelationship)") }
                guard let sfRelationshipName = sfField.relationshipName else { return failure("SF relationship metadata has no sfRelationshipName: \(moRelationship), \(sfField.metadata)") }
                guard sfField.type == .reference else { return incompatible() }
                return Relationship(moRelationship: moRelationship,
                                    sfField: sfField,
                                    sfRelationshipName: sfRelationshipName,
                                    shouldRemoveUnlinked: moRelationship.isMarkedShouldRemoveUnlinked,
                                    warningLogger: warningLogger)
            }
        } else {
            return failure("Unknown CoreData field type: \(moField)")
        }
    }

    lazy var soupEntryIdMapper: EntryMapper & FetchableField = resolveSoupEntryIdMapper()
    open func resolveSoupEntryIdMapper() -> EntryMapper & FetchableField {
        SoupEntryIdMapper(soupEntryIdConverter: soupEntryIdConverter, warningLogger: warningLogger)
    }

    lazy var attributesMapper: EntryMapper? = resolveAttributesMapper()
    open func resolveAttributesMapper() -> EntryMapper? {
        guard let sfName = sfName
            .check(warningLogger, "Entity sfName not found")
            else { return nil }
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

    var isMarkedShouldRemoveUnlinked: Bool {
        userInfo?[CoreDataSoupMetadataFactory.Keys.shouldRemoveUnlinked] as? Bool ?? false
    }

    var isMarkedShouldUnlinkAbsent: Bool {
        userInfo?[CoreDataSoupMetadataFactory.Keys.shouldUnlinkAbsent] as? Bool ?? false
    }
}

extension NSEntityDescription {
    var sfName: String? {
        userInfo?[CoreDataSoupMetadataFactory.Keys.entitySfName] as? String
    }
}
