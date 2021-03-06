//
//  CommonNotificationsRequestAlertDataSource.swift
//  Stepic
//
//  Created by Ivan Magda on 29/10/2018.
//  Copyright © 2018 Alex Karpov. All rights reserved.
//

import UIKit

final class CommonNotificationsRequestAlertDataSource: NotificationsRequestAlertDataSource {
    var positiveAction: (() -> Void)?
    var negativeAction: (() -> Void)?

    func alert(
        for alertType: NotificationsRegistrationServiceAlertType,
        in context: NotificationRequestAlertContext
    ) -> UIViewController {
        switch alertType {
        case .permission:
            let alert = NotificationRequestAlertViewController(context: context)
            alert.yesAction = self.positiveAction
            alert.noAction = self.negativeAction

            return alert
        case .settings:
            let alert = UIAlertController(
                title: NSLocalizedString("DeniedNotificationsDefaultAlertTitle", comment: ""),
                message: NSLocalizedString("DeniedNotificationsDefaultAlertMessage", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: NSLocalizedString("Settings", comment: ""),
                    style: .default,
                    handler: { _ in
                        self.positiveAction?()
                    }
                )
            )
            alert.addAction(
                UIAlertAction(
                    title: NSLocalizedString("No", comment: ""),
                    style: .cancel,
                    handler: { _ in
                        self.negativeAction?()
                    }
                )
            )

            return alert
        }
    }
}
