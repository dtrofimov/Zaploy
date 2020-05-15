//
//  CoreDataSoupMapper.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 06.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData
import MobileSync
import Then

typealias MOField = NSPropertyDescription

protocol CoreDataSoupMapper: FieldMapper {
    var entity: NSEntityDescription { get }
    var entityName: String { get }
    var sfIdMapper: SFIdMapper { get }
    var soupEntryIdMapper: UniqueFieldMapper { get }
    var uniqueMappers: [UniqueFieldMapper] { get }
}

class CoreDataSoupMapperImpl: CoreDataSoupMapper {
    struct Keys {
        static let entitySfName = "sfName"
        static let fieldSfName = "sfName"
        static let idFieldName = kId // "Id"
        static let isUnique = "isUnique"
    }

    static func sfName(entity: NSEntityDescription) -> String? {
        entity.userInfo?[Keys.entitySfName] as? String
    }

    let entity: NSEntityDescription
    let entityName: String
    let sfName: String
    let soupEntryIdConverter: SoupEntryIdConverter
    let sfIdMapper: SFIdMapper
    let soupEntryIdMapper: UniqueFieldMapper
    let uniqueMappers: [UniqueFieldMapper]
    let mappers: [FieldMapper]

    public enum CustomError: Error {
        case entityHasNoName
        case entitySfNameNotFound
        case validIdFieldNotFound
    }

    init(entity: NSEntityDescription, sfMetadata: Metadata, soupEntryIdConverter: SoupEntryIdConverter, warningLogger: WarningLogger) throws {
        guard let entityName = entity.name else {
            throw CustomError.entityHasNoName
        }
        guard let sfName = Self.sfName(entity: entity) else {
            throw CustomError.entitySfNameNotFound
        }
        let sfFieldsForNames: [String: SFField] = try (sfMetadata.fields ?? []).reduce(into: [:]) {
            let sfField = try SFField(metadata: $1)
            $0[sfField.name] = sfField
        }

        var uniqueMappers: [UniqueFieldMapper] = []
        var childMappers: [FieldMapper] = []
        var unsafeSfIdMapper: SFIdMapper?

        let soupEntryIdMapper = SoupEntryIdMapper(soupEntryIdConverter: soupEntryIdConverter, warningLogger: warningLogger)
        uniqueMappers.append(soupEntryIdMapper)
        childMappers.append(soupEntryIdMapper)

        let attributesMapper = AttributesFieldMapper(entity: entity, entitySfName: sfName, warningLogger: warningLogger)
        childMappers.append(attributesMapper)

        // TODO: Add syncId mapper

        for moField in entity.properties {
            guard let sfName = moField.userInfo?[Keys.fieldSfName] as? String else { continue }
            guard let sfField = sfFieldsForNames[sfName] else {
                warningLogger.logWarning("SF metadata not found for field \(moField)")
                continue
            }
            guard let fieldMapper = Self.makeMapper(moField: moField, sfField: sfField, warningLogger: warningLogger) else { continue }
            childMappers.append(fieldMapper)

            let isSfId = sfName == Keys.idFieldName
            let isMarkedUnique = moField.userInfo?[Keys.isUnique] as? Bool ?? false
            if isSfId {
                if let sfIdMapper = fieldMapper as? SFIdMapper {
                    uniqueMappers.append(sfIdMapper)
                    unsafeSfIdMapper = sfIdMapper
                } else {
                    warningLogger.logWarning("Id mapper type doesn't correspond to UniqueFieldMapper: \(fieldMapper)")
                }
            } else if isMarkedUnique {
                if let uniqueMapper = fieldMapper as? UniqueFieldMapper {
                    uniqueMappers.append(uniqueMapper)
                } else {
                    warningLogger.logWarning("Unique mapper type doesn't correspond to UniqueFieldMapper: \(fieldMapper)")
                }
            }
        }
        guard let sfIdMapper = unsafeSfIdMapper else {
            throw CustomError.validIdFieldNotFound
        }

        self.entity = entity
        self.entityName = entityName
        self.soupEntryIdConverter = soupEntryIdConverter
        self.sfName = sfName
        self.sfIdMapper = sfIdMapper
        self.soupEntryIdMapper = soupEntryIdMapper
        self.uniqueMappers = uniqueMappers
        self.mappers = childMappers
    }

    class func makeMapper(moField: MOField, sfField: SFField, warningLogger: WarningLogger) -> (FieldMapper & HavingMOField)? {
        // TODO: Handle all available SF field types.
        // TODO: Support overriding with an external mapper.
        func incompatible() -> (FieldMapper & HavingMOField)? {
            warningLogger.logWarning("Incompatible CoreData and SF field types: \(moField)")
            return nil
        }
        let moFieldType = (moField as? NSAttributeDescription)?.attributeType
        switch sfField.type {
        case .id, .string:
            guard moFieldType == .stringAttributeType else { return incompatible() }
            return StringFieldMapper(moField: moField, sfField: sfField, warningLogger: warningLogger)
        case .boolean:
            guard moFieldType == .booleanAttributeType else { return incompatible() }
            return BoolFieldMapper(moField: moField, sfField: sfField, warningLogger: warningLogger)
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
            return NumberFieldMapper(moField: moField, sfField: sfField, warningLogger: warningLogger)
        default:
            return incompatible()
        }
    }

    func map(from managedObject: NSManagedObject, to soupEntry: inout SoupEntry) {
        for mapper in mappers {
            mapper.map(from: managedObject, to: &soupEntry)
        }
    }

    func map(from soupEntry: SoupEntry, to managedObject: NSManagedObject) {
        for mapper in mappers {
            mapper.map(from: soupEntry, to: managedObject)
        }
    }
}
