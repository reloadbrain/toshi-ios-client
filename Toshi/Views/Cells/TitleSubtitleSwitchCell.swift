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

final class TitleSubtitleSwitchCell: ToshiTableViewCell {

    override func addSubviewsAndConstraints() {

        switchControl = UISwitch(frame: .zero)
        contentView.addSubview(switchControl!)
        switchControl!.trailing(to: contentView, offset: -16.0, priority: .defaultHigh)
        switchControl!.centerY(to: contentView)

        titleLabel = UILabel(frame: .zero)
        contentView.addSubview(titleLabel!)

        titleLabel?.top(to: contentView, offset: 16.0, priority: .defaultHigh)
        titleLabel?.leading(to: contentView, offset: 16.0, priority: .defaultHigh)
        titleLabel?.rightToLeft(of: switchControl!, offset: -10.0)
        titleLabel?.setContentHuggingPriority(.required, for: .vertical)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)

        subtitleLabel = UILabel(frame: .zero)
        contentView.addSubview(subtitleLabel!)

        subtitleLabel?.leading(to: contentView, offset: 16.0, priority: .defaultHigh)
        subtitleLabel?.topToBottom(of: titleLabel!, offset: 5.0, priority: .defaultHigh)
        subtitleLabel?.bottom(to: contentView, offset: -16.0, priority: .required)
        subtitleLabel?.setContentHuggingPriority(.required, for: .horizontal)
        subtitleLabel?.setContentHuggingPriority(.required, for: .vertical)
        subtitleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        subtitleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
