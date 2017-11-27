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
import TinyConstraints

final class TitleCell: ToshiTableViewCell {

    override open func addSubviewsAndConstraints() {
        titleLabel = UILabel(frame: .zero)
        contentView.addSubview(titleLabel!)

        titleLabel?.edgesToSuperview(excluding: .right, insets: TinyEdgeInsets(top: 10, left: 16, bottom: 10, right: 0))
        titleLabel?.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel?.setContentHuggingPriority(.required, for: .vertical)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
