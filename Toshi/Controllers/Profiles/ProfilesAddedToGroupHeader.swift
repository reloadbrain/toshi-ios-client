//
//  ProfilesAddedToGroupHeader.swift
//  Debug
//
//  Created by Ellen Shapiro (Work) on 12/4/17.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import SweetUIKit
import TinyConstraints
import UIKit

class ProfilesAddedToGroupHeader: UIView {
    
    lazy var profilesAddedLabel: UILabel = {
        let label = UILabel(withAutoLayout: true)
        label.numberOfLines = 0
        return label
    }()
    
    convenience init(margin: CGFloat) {
        self.init(withAutoLayout: true)
        addSubview(profilesAddedLabel)
        profilesAddedLabel.edgesToSuperview(insets: UIEdgeInsets(top: margin / 2, left: margin, bottom: margin / 2, right: -margin))
        updateDisplay(with: [])
    }
    
    func updateDisplay(with profiles: Set<TokenUser>) {
        let sortedProfiles = profiles.sorted(by: { $0.name < $1.name })
        
        let nonNameAttributes = [ NSAttributedStringKey.foregroundColor: Theme.lightGreyTextColor ]
        let toAttributedString = NSMutableAttributedString(string: Localized("profiles_add_to_group_prefix"), attributes: nonNameAttributes)
        
        let nameStrings = sortedProfiles.map { NSAttributedString(string: $0.name, attributes: [ .foregroundColor: Theme.tintColor ]) }
        
        // `join(with:)` doesn't work on attributed strings, so:
        let singleNamesString = nameStrings.reduce(NSMutableAttributedString(), { accumulated, next in
            accumulated.append(next)
            
            // Don't add a comma after the last item
            guard next != nameStrings.last else { return accumulated }
            accumulated.append(NSAttributedString(string: ", ", attributes: nonNameAttributes))
            
            return accumulated
        })
    
        toAttributedString.append(singleNamesString)
        profilesAddedLabel.attributedText = toAttributedString
    }
}
