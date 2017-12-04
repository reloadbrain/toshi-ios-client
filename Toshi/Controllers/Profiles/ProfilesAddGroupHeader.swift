//
//  ProfilesAddGroupHeader.swift
//  Debug
//
//  Created by Ellen Shapiro (Work) on 12/4/17.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import SweetUIKit
import TinyConstraints
import UIKit

protocol ProfilesAddGroupHeaderDelegate: class {
    func newGroup()
}

class ProfilesAddGroupHeader: UIView {
    
    private weak var delegate: ProfilesAddGroupHeaderDelegate?

    private lazy var button: LeftAlignedButton = {
        let view = LeftAlignedButton()
        view.icon = UIImage(color: .lightGray, size: CGSize(width: 48, height: 48))
        view.title = Localized("profiles_new_group")
        view.titleColor = Theme.tintColor
        view.addTarget(self,
                       action: #selector(tappedAddGroup),
                       for: .touchUpInside)
        return view
    }()
    
    convenience init(with delegate: ProfilesAddGroupHeaderDelegate?) {
        self.init(withAutoLayout: true)
        self.delegate = delegate
        self.addSubview(button)
        button.edgesToSuperview()
    }
    
    @objc private func tappedAddGroup() {
        guard let delegate = delegate else {
            assertionFailure("No delegate for you!")
            return
        }
        
        delegate.newGroup()
    }
}
