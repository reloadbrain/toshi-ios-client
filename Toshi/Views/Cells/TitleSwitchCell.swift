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

import UIKit

final class TitleSwitchCell: ToshiTableViewCell {

    override func addSubviewsAndConstraints() {
        switchControl = UISwitch(frame: .zero)
        contentView.addSubview(switchControl!)
        switchControl!.trailing(to: contentView, offset: -16.0, priority: .defaultHigh)
        switchControl!.centerY(to: contentView)

        titleTextField = UITextField(frame: .zero)
        contentView.addSubview(titleTextField!)

        titleTextField?.top(to: contentView, offset: 16.0)
        titleTextField?.leading(to: contentView, offset: 16.0, priority: .defaultHigh)
        titleTextField?.rightToLeft(of: switchControl!, offset: -10.0)
        titleTextField?.setContentHuggingPriority(.required, for: .vertical)
        titleTextField?.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleTextField?.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
