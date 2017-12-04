//
//  ProfilesAddedToGroupHeader.swift
//  Debug
//
//  Created by Ellen Shapiro (Work) on 12/4/17.
//  Copyright © 2017 Bakken&Baeck. All rights reserved.
//

import TinyConstraints
import UIKit

class ProfilesAddedToGroupHeader: UIView {
    
    lazy var profilesAddedLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    private(set) var profiles = Set<TokenUser>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(profilesAddedLabel)
        profilesAddedLabel.edgesToSuperview()
        updateDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Use init(frame:)!")
    }
    
    var sortedProfiles: [TokenUser] {
        return profiles.sorted(by: { $0.name < $1.name })
    }
    
    func add(profile: TokenUser) {
        profiles.insert(profile)
        updateDisplay()
    }
    
    func remove(profile: TokenUser) {
        profiles.remove(profile)
        updateDisplay()
    }
    
    private func updateDisplay() {
        let nonNameAttributes = [ NSAttributedStringKey.foregroundColor: Theme.lightGreyTextColor ]
        let prefix = NSMutableAttributedString(string: "To: ", attributes: nonNameAttributes)
        let nameStrings = profiles.map { NSAttributedString(string: $0.name, attributes: [ .foregroundColor: Theme.tintColor ]) }
        
        // `join(with:)` doesn't work on attributed strings, so:
        let singleNamesString = nameStrings.reduce(NSMutableAttributedString(), { accumulated, next in
            accumulated.append(next)
            
            // Don't add a comma after the last item
            guard next != nameStrings.last else { return accumulated }
            accumulated.append(NSAttributedString(string: ",", attributes: nonNameAttributes))
            
            return accumulated
        })
    
        return prefix.append(singleNamesString)
    }
}
