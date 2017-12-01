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

final class GroupInfoViewModel {

    private var groupModel: TSGroupModel
    var groupInfo: GroupInfo {
        didSet {
            setup()
        }
    }

    init(_ groupModel: TSGroupModel) {
        self.groupModel = groupModel
        groupInfo = GroupInfo()
        groupInfo.title = groupModel.groupName
        groupInfo.participantsIDs = groupModel.groupMemberIds

        setup()
    }

    private var models: [TableSectionData] = []

    private func setup() {
        let avatarTitleData = TableCellData(title: groupInfo.title, leftImage: groupInfo.avatar)
        avatarTitleData.isPlaceholder = groupInfo.title.length > 0
        avatarTitleData.tag = NewGroupItemType.avatarTitle.rawValue

        let avatarTitleSectionData = TableSectionData(cellsData: [avatarTitleData])
        let publicData = TableCellData(title: Localized("new_group_public_settings_title"), switchState: groupInfo.isPublic)
        publicData.tag = NewGroupItemType.isPublic.rawValue
        let publicSectionData = TableSectionData(cellsData: [publicData], headerTitle: Localized("new_group_settings_header_title"))

        let addParticipantsData = TableCellData(title: Localized("new_group_add_participants_action_title"))
        addParticipantsData.tag = NewGroupItemType.addParticipant.rawValue
        let addParticipantsSectionData = TableSectionData(cellsData: [addParticipantsData], headerTitle: Localized("new_group_participants_header_title"))

        models = [avatarTitleSectionData, publicSectionData, addParticipantsSectionData]
    }

    @objc private func updateGroup() {
        ChatInteractor.updateGroup(with: groupModel)
    }
}

extension GroupInfoViewModel: GroupViewModelProtocol {

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

    var rightBarButtonSelector: Selector { return #selector(updateGroup) }

    var viewControllerTitle: String { return Localized("group_info_title") }
    var rightBarButtonTitle: String { return Localized("update_group_button_title") }
    var imagePickerTitle: String { return Localized("image-picker-select-source-title") }
    var imagePickerCameraActionTitle: String { return Localized("image-picker-camera-action-title") }
    var imagePickerLibraryActionTitle: String { return Localized("image-picker-library-action-title") }
    var imagePickerCancelActionTitle: String { return Localized("cancel_action_title") }

    var errorAlertTitle: String { return Localized("error_title") }
    var errorAlertMessage: String { return Localized("toshi_generic_error") }

    var isDoneButtonEnabled: Bool { return groupInfo.title.length > 0 }
}

