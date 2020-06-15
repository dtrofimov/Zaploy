//
//  NSObject+LifetimeAttachments.swift
//  Unshift
//
//  Created by Dmitrii Trofimov on 28.10.2019.
//  Copyright © 2019 Dmitrii Trofimov. All rights reserved.
//

import Foundation
import ObjectiveC

private var LifetimeAttachmentsHandle = 0

extension NSObject {
    private var lifetimeAttachments: NSMutableArray? {
        get {
            return objc_getAssociatedObject(self, &LifetimeAttachmentsHandle) as? NSMutableArray
        }
        set {
            objc_setAssociatedObject(self, &LifetimeAttachmentsHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func attachForLifetime(_ object: AnyObject) {
        let attachments: NSMutableArray = {
            if let attachments = lifetimeAttachments { return attachments }
            let attachments = NSMutableArray()
            lifetimeAttachments = attachments
            return attachments
        }()
        attachments.add(object)
    }

    func attachForLifetime(_ objects: [AnyObject]) {
        for object in objects {
            attachForLifetime(object)
        }
    }
}
