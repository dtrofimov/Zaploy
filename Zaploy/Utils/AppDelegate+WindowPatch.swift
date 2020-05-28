//
//  AppDelegate+WindowPatch.swift
//  Zaploy
//
//  Created by Dmitrii Trofimov on 28.05.2020.
//  Copyright © 2020 Dmitrii Trofimov. All rights reserved.
//

import UIKit

extension AppDelegate {
    // That's to prevent a crash when SF SDK calls sharedApplication.delegate.window
    @objc var window: UIWindow? {
        get { nil }
        set { fatalError("Trying to set AppDelegate.window") }
    }
}
