//
//  GroupViewModelProtocol.swift
//  Toshi
//
//  Created by Yuliia Veresklia on 28/11/2017.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import UIKit

enum NewGroupItemType: Int {
    case avatarTitle
    case isPublic
    case participant
    case addParticipant
}

struct GroupInfo {
    let placeholder = Localized("new_group_title")
    var title: String = ""
    var avatar = UIImage(named: "avatar-edit")
    var isPublic = false
    var participantsIDs: [String] = []
}

protocol GroupViewModelProtocol: class {

    var sectionModels: [TableSectionData] { get }
    var viewControllerTitle: String { get }
    var rightBarButtonTitle: String { get }
    var imagePickerTitle: String { get }
    var imagePickerCameraActionTitle: String { get }
    var imagePickerLibraryActionTitle: String { get }
    var imagePickerCancelActionTitle: String { get }

    var errorAlertTitle: String { get }
    var errorAlertMessage: String { get }

    var rightBarButtonSelector: Selector { get }

    var participantsIDs: [String] { get }

    func updateAvatar(_ image: UIImage)
    func updatePublicState(_ isPublic: Bool)
    func updateTitle(_ title: String)

    var isDoneButtonEnabled: Bool { get }
}
