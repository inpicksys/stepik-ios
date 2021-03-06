//
//  CertificatesPresentationContainer.swift
//  Stepic
//
//  Created by Ostrenkiy on 18.04.17.
//  Copyright © 2017 Alex Karpov. All rights reserved.
//

import Foundation

final class CertificatesPresentationContainer {
    private let defaults = UserDefaults.standard

    private let certificatesStoredKey = "certificatesStoredIdsKey"

    var certificatesIds: [Int] {
        get {
            if let ids = defaults.object(forKey: certificatesStoredKey) as? [Int] {
                return ids
            } else {
                return []
            }
        }
        set(value) {
            defaults.set(value, forKey: certificatesStoredKey)
            defaults.synchronize()
        }
    }
}
