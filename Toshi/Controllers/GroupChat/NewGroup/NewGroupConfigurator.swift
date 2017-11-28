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

final class NewGroupConfigurator: ToshiCellConfigurator {

    func configureCell(_ cell: UITableViewCell, with cellData: TableCellData) {
        guard let cell = cell as? ToshiTableViewCell else { return }

        switch cellData.tag {
        case NewGroupItemType.addParticipant.rawValue:
            cell.titleTextField?.textAlignment = .center
            cell.titleTextField?.textColor = Theme.tintColor
        case NewGroupItemType.avatarTitle.rawValue:
            cell.titleTextField?.isUserInteractionEnabled = true
            cell.titleTextField?.returnKeyType = .done
        default:
            break
        }

        cell.titleTextField?.placeholder = "New group"
        cell.titleTextField?.text = cellData.title

        cell.subtitleLabel?.text = cellData.subtitle
        cell.detailsLabel?.text = cellData.details
        cell.leftImageView?.image = cellData.leftImage
        cell.switchControl?.isOn = cellData.switchState == true

        cell.leftImageView?.layer.cornerRadius = 20
        cell.leftImageView?.layer.masksToBounds = true
    }
}
