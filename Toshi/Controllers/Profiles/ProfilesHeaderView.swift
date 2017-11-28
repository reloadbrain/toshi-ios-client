import Foundation
import UIKit
import TinyConstraints

protocol ProfilesHeaderViewDelegate: class {
    func newGroup()
}

final class ProfilesHeaderView: UIView {
    
    private let type: ProfilesViewControllerType
    private let searchBar: UISearchBar?
    
    private lazy var button: LeftAlignedButton = {
        let view = LeftAlignedButton()
        view.icon = UIImage(named: "")
        view.title = Localized("profiles_new_group")
        
        return view
    }()
    
    required init(with searchBar: UISearchBar? = nil, type: ProfilesViewControllerType) {
        self.type = type
        self.searchBar = searchBar
        super.init(frame: .zero)
        
        height(100)
        width(UIScreen.main.bounds.width)
        
        backgroundColor = .red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
