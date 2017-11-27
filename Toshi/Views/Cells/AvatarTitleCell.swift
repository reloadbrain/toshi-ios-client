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

final class AvatarTitleCell: ToshiTableViewCell {

    open override func addSubviewsAndConstraints() {
        leftImageView = UIImageView(frame: .zero)
        leftImageView?.contentMode = .scaleAspectFill
        contentView.addSubview(leftImageView!)
        leftImageView?.leading(to: contentView, offset: 16.0, priority: .required)
        leftImageView?.top(to: contentView, offset: 16.0)
        leftImageView?.bottom(to: contentView, offset: -16.0)
        leftImageView?.set(width: 40.0)
        leftImageView?.set(height: 40.0)

        titleLabel = UILabel(frame: .zero)
        contentView.addSubview(titleLabel!)

        titleLabel?.centerY(to: contentView)
        titleLabel?.leftToRight(of: leftImageView!, offset: 10.0)
        titleLabel?.trailing(to: contentView, offset: -16.0)
        titleLabel?.setContentHuggingPriority(.required, for: .vertical)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
