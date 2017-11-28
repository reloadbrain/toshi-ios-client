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
    case addParticipant
}

final class NewGroupViewModel {

    private(set) var sectionModels: [TableSectionData] = []

    init() {
        prepare()
    }

    private func prepare() {
        var avatarTitleData = TableCellData(title: "New Group", leftImage: UIImage(named: "avatar-edit"))
        avatarTitleData.tag = NewGroupItemType.avatarTitle.rawValue

        let avatarTitleSectionData = TableSectionData(cellsData: [avatarTitleData])
        var publicData = TableCellData(title: "Public", switchState: false)
        publicData.tag = NewGroupItemType.isPublic.rawValue
        let publicSectionData = TableSectionData(cellsData: [publicData], headerTitle: "Group settings")

        var addParticipantsData = TableCellData(title: "Add Participants")
        addParticipantsData.tag = NewGroupItemType.addParticipant.rawValue
        let addParticipantsSectionData = TableSectionData(cellsData: [addParticipantsData], headerTitle: "Participants")

        sectionModels = [avatarTitleSectionData, publicSectionData, addParticipantsSectionData]
    }
}
