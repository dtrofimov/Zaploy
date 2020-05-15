//
//  CoreDataSoup.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 06.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import CoreData
import MobileSync
import Then

typealias MOField = NSPropertyDescription

class CoreDataSoup {
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
    let sfIdMapper: StringFieldMapper
    let soupEntryIdMapper: SoupEntryIdMapper
    let uniqueMappers: [UniqueFieldMapper]
    let mappers: [FieldMapper]

    public enum CustomError: Error {
        case entityHasNoName
        case entitySfNameNotFound
        case fieldMetadataNotFound(fieldName: String)
        case idFieldNotFound
        case unsupportedFieldTypeCombination(moField: MOField, sfField: SFField)
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
        let soupEntryIdMapper = SoupEntryIdMapper(soupEntryIdConverter: soupEntryIdConverter, warningLogger: warningLogger)
        let mappers: [FieldMapper] = try [].with {
            $0.append(soupEntryIdMapper)
            $0.append(AttributesFieldMapper(entity: entity, entitySfName: sfName, warningLogger: warningLogger))
            for moField in entity.properties {
                guard let sfName = moField.userInfo?[Keys.fieldSfName] as? String else { continue }
                guard let sfField = sfFieldsForNames[sfName] else {
                    throw CustomError.fieldMetadataNotFound(fieldName: moField.name)
                }
                $0.append(try Self.makeMapper(moField: moField, sfField: sfField, warningLogger: warningLogger))
            }
        }
        let sfIdMapper: StringFieldMapper = try {
            for mapper in mappers {
                if let stringMapper = mapper as? StringFieldMapper,
                    stringMapper.sfField.name == Keys.idFieldName {
                    return stringMapper
                }
            }
            throw CustomError.idFieldNotFound
        }()

        self.entity = entity
        self.entityName = entityName
        self.soupEntryIdConverter = soupEntryIdConverter
        self.sfName = sfName
        self.sfIdMapper = sfIdMapper
        self.soupEntryIdMapper = soupEntryIdMapper
        self.uniqueMappers = [soupEntryIdMapper, sfIdMapper].with {
            for mapper in mappers {
                if let mapper = mapper as? BaseFieldMapper & UniqueFieldMapper,
                    let isUniqueNum = mapper.moField.userInfo?[Keys.isUnique] as? NSNumber,
                    isUniqueNum.boolValue {
                    $0.append(mapper)
                }
            }
        }
        self.mappers = mappers
    }

    static func makeMapper(moField: MOField, sfField: SFField, warningLogger: WarningLogger) throws -> FieldMapper {
        // TODO: Handle all available SF field types.
        // TODO: Support overriding with an external mapper.
        func fallback() throws -> Never {
            throw CustomError.unsupportedFieldTypeCombination(moField: moField, sfField: sfField)
        }
        let moFieldType = (moField as? NSAttributeDescription)?.attributeType
        switch sfField.type {
        case .id, .string:
            guard moFieldType == .stringAttributeType else { try fallback() }
            return StringFieldMapper(moField: moField, sfField: sfField, warningLogger: warningLogger)
        case .boolean:
            guard moFieldType == .booleanAttributeType else { try fallback() }
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
            default: try fallback()
            }
            return NumberFieldMapper(moField: moField, sfField: sfField, warningLogger: warningLogger)
        default:
            try fallback()
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
