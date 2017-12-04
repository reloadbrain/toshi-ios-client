// Copyright (c) 2017 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation
import UIKit

final class NewGroupViewModel {

    let filteredDatabaseViewName = "filteredDatabaseViewName"

    private var groupInfo: GroupInfo {
        didSet {
            setup()
        }
    }

    private var models: [TableSectionData] = []

    init(_ groupModel: TSGroupModel) {
        groupInfo = GroupInfo()
        groupInfo.title = groupModel.groupName
        groupInfo.participantsIDs = groupModel.groupMemberIds

        setup()
    }

    private func setup() {
        let avatarTitleData = TableCellData(title: groupInfo.title, leftImage: groupInfo.avatar)
        avatarTitleData.isPlaceholder = groupInfo.title.length > 0
        avatarTitleData.tag = NewGroupItemType.avatarTitle.rawValue

        let avatarTitleSectionData = TableSectionData(cellsData: [avatarTitleData])
        let publicData = TableCellData(title: Localized("new_group_public_settings_title"), switchState: groupInfo.isPublic)
        publicData.tag = NewGroupItemType.isPublic.rawValue
        let publicSectionData = TableSectionData(cellsData: [publicData], headerTitle: Localized("new_group_settings_header_title"))

        models = [avatarTitleSectionData, publicSectionData]
    }

    @objc private func createChat() {

       // guard let membersIds = groupInfo.participantsIDs as? NSMutableArray else { return } //TEST
        let membersIds = NSMutableArray()
        membersIds.addObjects(from: ["0x718f6d24b48a6c01f9178baf849a100d7cf55a05", "0xa826278610d81fae6e6e181e6b44689ea7ff7f4b", Cereal.shared.address])

        ChatInteractor.createGroup(with: membersIds, name: groupInfo.title, avatar: groupInfo.avatar)
    }
}

extension NewGroupViewModel: GroupViewModelProtocol {
    
    var sectionModels: [TableSectionData] {
        return models
    }

    func updateAvatar(_ image: UIImage) {
        groupInfo.avatar = image
    }

    func updateTitle(_ title: String) {
        groupInfo.title = title
    }

    func updatePublicState(_ isPublic: Bool) {
        groupInfo.isPublic = isPublic
    }

    var rightBarButtonSelector: Selector {
        return #selector(createChat)
    }

    var viewControllerTitle: String { return Localized("new_group_title") }
    var rightBarButtonTitle: String { return Localized("create_group_button_title") }
    var imagePickerTitle: String { return Localized("image-picker-select-source-title") }
    var imagePickerCameraActionTitle: String { return Localized("image-picker-camera-action-title") }
    var imagePickerLibraryActionTitle: String { return Localized("image-picker-library-action-title") }
    var imagePickerCancelActionTitle: String { return Localized("cancel_action_title") }

    var errorAlertTitle: String { return Localized("error_title") }
    var errorAlertMessage: String { return Localized("toshi_generic_error") }

    var isDoneButtonEnabled: Bool { return groupInfo.title.length > 0 }

    var participantsIDs: [String] { return groupInfo.participantsIDs }
}
