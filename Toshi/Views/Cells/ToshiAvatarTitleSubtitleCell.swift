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

final class AvatarTitleSubtitleCell: ToshiTableViewCell {

    override func addSubviewsAndConstraints() {
        leftImageView = UIImageView(frame: .zero)
        leftImageView?.contentMode = .scaleAspectFill
        contentView.addSubview(leftImageView!)
        leftImageView?.leading(to: contentView, offset: 16.0, priority: .required)
        leftImageView?.centerY(to: contentView, priority: .defaultHigh)
        leftImageView?.set(width: 40.0)
        leftImageView?.set(height: 40.0)

        titleLabel = UILabel(frame: .zero)
        contentView.addSubview(titleLabel!)

        titleLabel?.top(to: contentView, offset: 16.0, priority: .defaultHigh)
        titleLabel?.leftToRight(of: leftImageView!, offset: 10.0)
        titleLabel?.trailing(to: contentView, offset: -16.0, priority: .defaultHigh)
        titleLabel?.setContentHuggingPriority(.required, for: .vertical)
        titleLabel?.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)

        subtitleLabel = UILabel(frame: .zero)
        contentView.addSubview(subtitleLabel!)

        subtitleLabel?.leftToRight(of: leftImageView!, offset: 10.0)
        subtitleLabel?.topToBottom(of: titleLabel!, offset: 5.0, priority: .defaultHigh)
        subtitleLabel?.bottom(to: contentView, offset: -16.0, priority: .required)
        subtitleLabel?.setContentHuggingPriority(.required, for: .horizontal)
        subtitleLabel?.setContentHuggingPriority(.required, for: .vertical)
        subtitleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        subtitleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)

        subtitleLabel?.backgroundColor = .yellow
        contentView.backgroundColor = .purple
    }
}
