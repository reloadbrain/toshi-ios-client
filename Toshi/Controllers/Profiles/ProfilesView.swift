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
    private var selectedProfiles = Set<TokenUser>()
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
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
        
        IDAPIClient.shared.findContact(name: profile.address) { [weak self] _ in
            self?.beginUpdates()
            self?.reloadRows(at: [indexPath], with: .automatic)
            self?.endUpdates()
        }
    }
    
    @objc private func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = databaseConnection.beginLongLivedReadTransaction()
        
        // swiftlint:disable:next force_cast
        let threadViewConnection = databaseConnection.ext(ProfilesView.filteredProfilesKey) as! YapDatabaseViewConnection
        
        if !threadViewConnection.hasChanges(for: notifications) {
            databaseConnection.read { [weak self] transaction in
                self?.mappings.update(with: transaction)
            }
            
            return
        }
        
        let yapDatabaseChanges = threadViewConnection.getChangesFor(notifications: notifications, with: mappings)
        let isDatabaseChanged = yapDatabaseChanges.rowChanges.count != 0 || yapDatabaseChanges.sectionChanges.count != 0
        
        guard isDatabaseChanged else { return }
                
        beginUpdates()
        
        for rowChange in yapDatabaseChanges.rowChanges {
            
            switch rowChange.type {
            case .delete:
                guard let indexPath = rowChange.indexPath else { continue }
                deleteRows(at: [indexPath], with: .none)
            case .insert:
                guard let newIndexPath = rowChange.newIndexPath else { continue }
                updateProfileIfNeeded(at: newIndexPath)
                insertRows(at: [newIndexPath], with: .none)
            case .move:
                guard let newIndexPath = rowChange.newIndexPath, let indexPath = rowChange.indexPath else { continue }
                deleteRows(at: [indexPath], with: .none)
                insertRows(at: [newIndexPath], with: .none)
            case .update:
                guard let indexPath = rowChange.indexPath else { continue }
                reloadRows(at: [indexPath], with: .none)
            }
        }
        
        endUpdates()
    }
}

extension ProfilesView: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Int(mappings.numberOfSections())
    }
    
    open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(mappings.numberOfItems(inSection: UInt(section)))
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileCell.reuseIdentifier, for: indexPath) as? ProfileCell else {
            assertionFailure("This is not a profile cell!")
            return UITableViewCell()
        }
        
        guard let rowProfile = profile(at: indexPath) else {
            assertionFailure("Could not get profile at indexPath: \(indexPath)")
            return cell
        }
        cell.profile = rowProfile
        
        if type == .newGroupChat {
            cell.checkmarkView.checked = selectedProfiles.contains(rowProfile)
        }
        
        return cell
    }
}

extension ProfilesView: UITableViewDelegate {
    
    public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let profile = profile(at: indexPath) else { return }
        
        switch type {
        case .favorites,
             .newChat:
            selectionDelegate?.didSelectProfile(profile: profile)
        case .newGroupChat:
            if selectedProfiles.contains(profile) {
                selectedProfiles.remove(profile)
            } else {
                selectedProfiles.insert(profile)
            }
            
            guard
                let header = tableHeaderView as? ProfilesHeaderView,
                let selectedProfilesView = header.subviews[0] as? ProfilesAddedToGroupHeader else {
                    assertionFailure("Couldn't access header!")
                    return
            }
            
            selectedProfilesView.updateDisplay(with: selectedProfiles)
            
            reloadData()
        }
    }
}
