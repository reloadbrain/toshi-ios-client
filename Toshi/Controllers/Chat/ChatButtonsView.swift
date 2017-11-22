import Foundation
import UIKit
import TinyConstraints

protocol ChatButtonsSelectionDelegate: class {
    func didSelectButton(at indexPath: IndexPath)
}

final class ChatButtonsView: UIView {
    static let height: CGFloat = 59
    
    weak var delegate: ChatButtonsSelectionDelegate?
    private var heightConstraint: NSLayoutConstraint?
    
    var buttons: [SofaMessage.Button]? = [] {
        didSet {
            heightConstraint?.constant = buttons == nil ? 0 : ChatButtonsView.height
            collectionView.reloadData()
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor(white: 1.0, alpha: 0.0).cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.white.cgColor]
        gradientLayer.startPoint.y = 0.01

        return gradientLayer
    }()
    
    private(set) lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: ChatButtonsViewLayout())
        view.backgroundColor = .clear
        view.isOpaque = false
        view.delegate = self
        view.dataSource = self
        view.contentInset = UIEdgeInsets(top: 8, left: 15, bottom: 0, right: 15)
        view.alwaysBounceHorizontal = true

        view.register(ChatButtonsViewCell.self, forCellWithReuseIdentifier: ChatButtonsViewCell.reuseIdentifier)
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        heightConstraint = height(0)

        layer.addSublayer(gradientLayer)
        addSubview(collectionView)

        layer.shadowColor = UIColor.white.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: -14)

        collectionView.edgesToSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer.frame = bounds
    }
}

extension ChatButtonsView : UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectButton(at: indexPath)
    }
}

extension ChatButtonsView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return buttons?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatButtonsViewCell.reuseIdentifier, for: indexPath)
        
        if let cell = cell as? ChatButtonsViewCell, let button = buttons?.element(at: indexPath.item) {
            cell.title = button.label
            cell.shouldShowArrow = button.type == .group
        }
        
        return cell
    }
}
