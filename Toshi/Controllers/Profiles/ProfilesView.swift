import Foundation
import UIKit
import TinyConstraints

protocol ProfilesViewDelegate: class {
    func didSelectProfile(profile: TokenUser)
}

class ProfilesView: UITableView {
    
    weak var selectionDelegate: ProfilesViewDelegate?
    static let filteredProfilesKey = "Filtered_Profiles_Key"
    
    private let type: ProfilesViewControllerType
    
    private(set) lazy var databaseConnection: YapDatabaseConnection = {
        let database = Yap.sharedInstance.database
        let dbConnection = database!.newConnection()
        dbConnection.beginLongLivedReadTransaction()
        
        return dbConnection
    }()
    
    private(set) lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TokenUser.favoritesCollectionKey], view: ProfilesView.filteredProfilesKey)
        mappings.setIsReversed(true, forGroup: TokenUser.favoritesCollectionKey)
        
        return mappings
    }()
    
    required public init(frame: CGRect, style: UITableViewStyle, type: ProfilesViewControllerType) {
        self.type = type
        super.init(frame: frame, style: style)
        
        estimatedRowHeight = 80
        dataSource = self
        delegate = self
        backgroundColor = Theme.viewBackgroundColor
        separatorStyle = .none
        
        register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func profile(at indexPath: IndexPath) -> TokenUser? {
        var profile: TokenUser?
        
        databaseConnection.read { [weak self] transaction in
            guard let strongSelf = self,
                let dbExtension: YapDatabaseViewTransaction = transaction.extension(ProfilesView.filteredProfilesKey) as? YapDatabaseViewTransaction,
                let data = dbExtension.object(at: indexPath, with: strongSelf.mappings) as? Data else { return }
            
            profile = TokenUser.user(with: data, shouldUpdate: false)
        }
        
        return profile
    }
    
    func updateProfileIfNeeded(at indexPath: IndexPath) {
        guard let profile = profile(at: indexPath) else { return }
        
        print("Updating profile infor for address: \(profile.address).")
        
        IDAPIClient.shared.findContact(name: profile.address) { [weak self] _ in
            self?.beginUpdates()
            self?.reloadRows(at: [indexPath], with: .automatic)
            self?.endUpdates()
        }
    }
}

extension ProfilesView: UITableViewDataSource {
    
    func numberOfSections(in _: UITableView) -> Int {
        return Int(mappings.numberOfSections())
    }
    
    open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(mappings.numberOfItems(inSection: UInt(section)))
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileCell.reuseIdentifier, for: indexPath)
        
        if let cell = cell as? ProfileCell {
            cell.profile = profile(at: indexPath)
        }
        
        return cell
    }
}

extension ProfilesView: UITableViewDelegate {
    
    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let profile = profile(at: indexPath) else { return }
        selectionDelegate?.didSelectProfile(profile: profile)
    }
}
