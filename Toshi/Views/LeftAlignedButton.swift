import Foundation
import UIKit
import TinyConstraints

class LeftAlignedButton: UIControl {
    
    var icon: UIImage? {
        didSet {
            iconImageView.image = icon
        }
    }
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    private lazy var iconImageView = UIImageView()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = Theme.preferredRegularMedium()
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        
        iconImageView.left(to: self, offset: 15)
        iconImageView.centerY(to: self)
        iconImageView.size(CGSize(width: 38, height: 38))
        
        titleLabel.edgesToSuperview(excluding: .left, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -15))
        titleLabel.leftToRight(of: iconImageView, offset: 10)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
