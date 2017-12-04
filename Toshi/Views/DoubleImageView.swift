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

class DoubleImageView: UIView {
    static let imageSize: CGFloat = 38.0

    private lazy var firstImageView = UIImageView()
    private lazy var secondImageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(firstImageView)
        addSubview(secondImageView)

        firstImageView.height(DoubleImageView.imageSize)
        firstImageView.width(DoubleImageView.imageSize)
        firstImageView.right(to: self)
        firstImageView.bottom(to: self)

        secondImageView.height(DoubleImageView.imageSize)
        secondImageView.width(DoubleImageView.imageSize)
        secondImageView.left(to: self)
        secondImageView.top(to: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setImages(_ images: (firstImage: UIImage, secondImage: UIImage)?) {
        firstImageView.image = images?.firstImage
        secondImageView.image = images?.secondImage
    }
}
