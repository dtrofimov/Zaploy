//
//  HavingCoreDataSoupMetadata+Soql.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 09.06.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import Foundation

extension HavingCoreDataSoupMetadata {
    var fieldNamesForSoql: [String] {
        metadata.sfFieldsForMOFields.map { $0.value.name }
    }

    func soqlQuery(fieldNames: [String]? = nil, otherFieldNames: [String] = [], filter: String? = nil, from subset: String? = nil) -> String {
        let fieldNames = fieldNames ?? fieldNamesForSoql + otherFieldNames
        return [String]().with {
            $0.append("select \(fieldNames.joined(separator: ", "))")
            $0.append("from \(subset ?? metadata.sfName ?? "")")
            if let filter = filter {
                $0.append("where \(filter)")
            }
        }
        .joined(separator: " ")
    }
}
