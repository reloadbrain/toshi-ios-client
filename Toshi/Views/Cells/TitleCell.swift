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
        titleTextField = UITextField(frame: .zero)
        contentView.addSubview(titleTextField!)

        titleTextField?.edgesToSuperview(excluding: .right, insets: TinyEdgeInsets(top: 10, left: 16, bottom: 10, right: 0))
        titleTextField?.setContentHuggingPriority(.required, for: .horizontal)
        titleTextField?.setContentHuggingPriority(.required, for: .vertical)
        titleTextField?.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleTextField?.setContentCompressionResistancePriority(.required, for: .vertical)
    }
}
