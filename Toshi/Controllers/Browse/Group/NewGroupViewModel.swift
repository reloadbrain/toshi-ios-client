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

enum NewGroupItemType: Int {
    case avatarTitle
    case isPublic
    case participant
    case addParticipant
}

struct GroupInfo {
    let placeholder = "New Group"
    var title: String = ""
    var avatar = UIImage(named: "avatar-edit")
    var isPublic = false
    var participantsIDs: [TokenUser] = []
}

final class NewGroupViewModel {

    var groupInfo: GroupInfo {
        didSet {
            setup()
        }
    }

    init() {
        groupInfo = GroupInfo()
        setup()
    }

    private(set) var sectionModels: [TableSectionData] = []

    private func setup() {
        let avatarTitleData = TableCellData(title: groupInfo.title, leftImage: groupInfo.avatar)
        avatarTitleData.isPlaceholder = groupInfo.title.length > 0
        avatarTitleData.tag = NewGroupItemType.avatarTitle.rawValue

        let avatarTitleSectionData = TableSectionData(cellsData: [avatarTitleData])
        let publicData = TableCellData(title: "Public", switchState: groupInfo.isPublic)
        publicData.tag = NewGroupItemType.isPublic.rawValue
        let publicSectionData = TableSectionData(cellsData: [publicData], headerTitle: "Group settings")

        let addParticipantsData = TableCellData(title: "Add Participants")
        addParticipantsData.tag = NewGroupItemType.addParticipant.rawValue
        let addParticipantsSectionData = TableSectionData(cellsData: [addParticipantsData], headerTitle: "Participants")

        sectionModels = [avatarTitleSectionData, publicSectionData, addParticipantsSectionData]
    }
}
