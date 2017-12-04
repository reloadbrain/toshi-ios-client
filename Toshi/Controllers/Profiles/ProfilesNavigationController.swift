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

public class ProfilesNavigationController: UINavigationController {
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    public override init(rootViewController: UIViewController) {
        
        if let rootViewController = rootViewController as? ProfilesViewController, let profilesView = rootViewController.profilesView, let address = UserDefaultsWrapper.selectedContact, rootViewController.type != .newChat {
            super.init(nibName: nil, bundle: nil)
            
            profilesView.databaseConnection.read { [weak self] transaction in
                if let data = transaction.object(forKey: address, inCollection: TokenUser.favoritesCollectionKey) as? Data, let user = TokenUser.user(with: data) {
                    self?.viewControllers = [rootViewController, ProfileViewController(profile: user)]
                    self?.configureTabBarItem()
                }
            }
        } else {
            super.init(rootViewController: rootViewController)
        }
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configureTabBarItem()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureTabBarItem() {
        tabBarItem = UITabBarItem(title: Localized("tab_bar_title_favorites"), image: #imageLiteral(resourceName: "tab4"), tag: 1)
        tabBarItem.titlePositionAdjustment.vertical = TabBarItemTitleOffset
    }
    
    public override func popViewController(animated: Bool) -> UIViewController? {
        UserDefaultsWrapper.selectedContact = nil
        return super.popViewController(animated: animated)
    }
    
    public override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedContact = nil
        return super.popToRootViewController(animated: animated)
    }
    
    public override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        UserDefaultsWrapper.selectedContact = nil
        return super.popToViewController(viewController, animated: animated)
    }
}
