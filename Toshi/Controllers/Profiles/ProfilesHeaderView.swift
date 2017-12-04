import Foundation
import UIKit
import TinyConstraints
import SweetUIKit

final class ProfilesHeaderView: UIView {
    
    private let type: ProfilesViewControllerType
    private let searchBar: UISearchBar?
    
    required init(with searchBar: UISearchBar? = nil, type: ProfilesViewControllerType, delegate: ProfilesAddGroupHeaderDelegate?) {
        self.type = type
        self.searchBar = searchBar
        super.init(frame: .zero)
        
        height(80)
        width(UIScreen.main.bounds.width)
        configure(for: type, with: delegate)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure(for type: ProfilesViewControllerType, with delegate: ProfilesAddGroupHeaderDelegate?) {
        switch type {
        case .favorites,
             .newChat:
            let addGroupHeader = ProfilesAddGroupHeader(with: delegate)
            self.addSubview(addGroupHeader)
            addGroupHeader.edgesToSuperview()
            self.backgroundColor = .red
        case .newGroupChat:
            var frame = self.bounds
            frame.origin = .zero
            let addedToGroupHeader = ProfilesAddedToGroupHeader(frame: frame)
            self.addSubview(addedToGroupHeader)
            addedToGroupHeader.edgesToSuperview()
            self.backgroundColor = .blue
        }
    }
}
