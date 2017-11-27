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
import SweetFoundation
import SweetUIKit

public extension NSNotification.Name {
    public static let ChatDatabaseCreated = NSNotification.Name(rawValue: "ChatDatabaseCreated")
}

open class RecentViewController: SweetTableController, Emptiable {

    let emptyView = EmptyView(title: Localized("chats_empty_title"), description: Localized("chats_empty_description"), buttonTitle: Localized("invite_friends_action_title"))

    lazy var mappings: YapDatabaseViewMappings = {
        let mappings = YapDatabaseViewMappings(groups: [TSInboxGroup], view: TSThreadDatabaseViewExtensionName)
        mappings.setIsReversed(true, forGroup: TSInboxGroup)

        return mappings
    }()

    lazy var uiDatabaseConnection: YapDatabaseConnection = {
        let database = TSStorageManager.shared().database()!
        let dbConnection = database.newConnection()
        dbConnection.beginLongLivedReadTransaction()

        return dbConnection
    }()

    fileprivate var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    fileprivate var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    public init() {
        super.init()

        title = "Recent"

        loadViewIfNeeded()

        if TokenUser.current != nil {
            self.loadMessages()
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(chatDBCreated(_:)), name: .ChatDatabaseCreated, object: nil)
        }
    }

    fileprivate func loadMessages() {
        uiDatabaseConnection.asyncRead { [weak self] transaction in
            self?.mappings.update(with: transaction)

            DispatchQueue.main.async {
                self?.showEmptyStateIfNeeded()
            }
        }

        registerNotifications()
    }

    public required init?(coder _: NSCoder) {
        fatalError()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        addSubviewsAndConstraints()

        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatCell.self)
        ToshiTableViewCell.register(in: tableView)

        tableView.showsVerticalScrollIndicator = true
        tableView.alwaysBounceVertical = true
    }

    @objc func emptyViewButtonPressed(_ button: ActionButton) {
        let shareController = UIActivityViewController(activityItems: ["Get Toshi, available for iOS and Android! (https://toshi.org)"], applicationActivities: [])
        Navigator.presentModally(shareController)
    }

    @objc fileprivate func chatDBCreated(_ notification: Notification) {
        loadMessages()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferLargeTitleIfPossible(true)
        tabBarController?.tabBar.isHidden = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didPressCompose(_:)))

        let configurator = CellConfigurator()
        var reuseIdentifier = ""

        let titleComponent: TableCellDataComponents = .title
        reuseIdentifier = configurator.cellIdentifier(for: titleComponent)
        print(reuseIdentifier)

        let titleSubtitle: TableCellDataComponents = .titleSubtitle
        reuseIdentifier = configurator.cellIdentifier(for: titleSubtitle)
        print(reuseIdentifier)

        let titleLeftImageComponents: TableCellDataComponents = .titleLeftImage
        reuseIdentifier = configurator.cellIdentifier(for: titleLeftImageComponents)
        print(reuseIdentifier)

        let titleSubtitleLeftImage: TableCellDataComponents = .titleSubtitleLeftImage
        reuseIdentifier = configurator.cellIdentifier(for: titleSubtitleLeftImage)
        print(reuseIdentifier)

        let titleSwitchComponents: TableCellDataComponents = .titleSwitchControl
        reuseIdentifier = configurator.cellIdentifier(for: titleSwitchComponents)
        print(reuseIdentifier)

        let titleSubtitleSwitchComponents: TableCellDataComponents = .titleSubtitleSwitchControl
        reuseIdentifier = configurator.cellIdentifier(for: titleSubtitleSwitchComponents)
        print(reuseIdentifier)

        let titleSubtitleImageSwitchComponents: TableCellDataComponents = .titleSubtitleSwitchControlLeftImage
        reuseIdentifier = configurator.cellIdentifier(for: titleSubtitleImageSwitchComponents)
        print(reuseIdentifier)
    }
    
    @objc private func didPressCompose(_ barButtonItem: UIBarButtonItem) {
        let favoritesController = FavoritesNavigationController(rootViewController: FavoritesController())
        Navigator.presentModally(favoritesController)
    }

    fileprivate func addSubviewsAndConstraints() {
        let tableHeaderHeight = navigationController?.navigationBar.frame.height ?? 0
        
        view.addSubview(emptyView)
        emptyView.actionButton.addTarget(self, action: #selector(emptyViewButtonPressed(_:)), for: .touchUpInside)
        emptyView.edges(to: layoutGuide(), insets: UIEdgeInsets(top: tableHeaderHeight, left: 0, bottom: 0, right: 0))
    }

    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(yapDatabaseDidChange(notification:)), name: .YapDatabaseModified, object: nil)
    }

    @objc func yapDatabaseDidChange(notification _: NSNotification) {
        let notifications = uiDatabaseConnection.beginLongLivedReadTransaction()

        // If changes do not affect current view, update and return without updating collection view
        // swiftlint:disable force_cast
        let threadViewConnection = uiDatabaseConnection.ext(TSThreadDatabaseViewExtensionName) as! YapDatabaseViewConnection
        // swiftlint:enable force_cast

        let hasChangesForCurrentView = threadViewConnection.hasChanges(for: notifications)
        guard hasChangesForCurrentView else {
            uiDatabaseConnection.read { transaction in
                self.mappings.update(with: transaction)
            }

            return
        }

        let yapDatabaseChanges = threadViewConnection.getChangesFor(notifications: notifications, with: mappings)
        let isDatabaseChanged = yapDatabaseChanges.rowChanges.count != 0 || yapDatabaseChanges.sectionChanges.count != 0

        guard isDatabaseChanged else { return }

        if let insertedRow = yapDatabaseChanges.rowChanges.first(where: { $0.type == .insert }) {

            if let newIndexPath = insertedRow.newIndexPath {
                if let thread = self.thread(at: newIndexPath) {

                    if let contactIdentifier = thread.contactIdentifier() {
                        IDAPIClient.shared.updateContact(with: contactIdentifier)
                    }

                    if thread.isGroupThread() && ProfileManager.shared().isThread(inProfileWhitelist: thread) == false {
                        ProfileManager.shared().addThread(toProfileWhitelist: thread)

                        (thread as? TSGroupThread)?.groupModel.groupMemberIds.forEach { AvatarManager.shared.downloadAvatar(for: $0) }
                    }
                }
            }
        }

        // No need to animate the tableview if not being presented.
        // Avoids an issue where tableview will actually cause a crash on update
        // during a chat update.
        if navigationController?.topViewController == self && tabBarController?.selectedViewController == navigationController {
            tableView.beginUpdates()

            for rowChange in yapDatabaseChanges.rowChanges {

                switch rowChange.type {
                case .delete:
                    guard let indexPath = rowChange.indexPath else { continue }
                    tableView.deleteRows(at: [indexPath], with: .left)
                case .insert:
                    guard let newIndexPath = rowChange.newIndexPath else { continue }

                    updateContactIfNeeded(at: newIndexPath)
                    tableView.insertRows(at: [newIndexPath], with: .right)
                case .move:
                    guard let indexPath = rowChange.indexPath, let newIndexPath = rowChange.newIndexPath else { continue }

                    tableView.deleteRows(at: [indexPath], with: .left)
                    tableView.insertRows(at: [newIndexPath], with: .right)
                case .update:
                    guard let indexPath = rowChange.indexPath else { continue }

                    tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            }

            tableView.endUpdates()
        } else {
            tableView.reloadData()
        }

        showEmptyStateIfNeeded()
    }

    private func showEmptyStateIfNeeded() {
        let shouldHideEmptyState = mappings.numberOfItems(inSection: 0) > 0

        emptyView.isHidden = shouldHideEmptyState
    }

    func updateContactIfNeeded(at indexPath: IndexPath) {
        if let thread = self.thread(at: indexPath), let address = thread.contactIdentifier() {
            print("Updating contact infor for address: \(address).")

            idAPIClient.retrieveUser(username: address) { contact in
                if let contact = contact {
                    print("Updated contact info for \(contact.username)")
                }
            }
        }
    }

    func thread(at indexPath: IndexPath) -> TSThread? {
        var thread: TSThread?

        uiDatabaseConnection.read { transaction in
            guard let dbExtension = transaction.extension(TSThreadDatabaseViewExtensionName) as? YapDatabaseViewTransaction else { return }
            guard let object = dbExtension.object(at: indexPath, with: self.mappings) as? TSThread else { return }

            thread = object
        }

        return thread
    }

    func thread(withAddress address: String) -> TSThread? {
        var thread: TSThread?

        uiDatabaseConnection.read { transaction in
            transaction.enumerateRows(inCollection: TSThread.collection()) { _, object, _, stop in
                if let possibleThread = object as? TSThread {
                    if possibleThread.contactIdentifier() == address {
                        thread = possibleThread
                        stop.pointee = true
                    }
                }
            }
        }

        return thread
    }

    func thread(withIdentifier identifier: String) -> TSThread? {
        var thread: TSThread?

        uiDatabaseConnection.read { transaction in
            transaction.enumerateRows(inCollection: TSThread.collection()) { _, object, _, stop in
                if let possibleThread = object as? TSThread {
                    if possibleThread.uniqueId == identifier {
                        thread = possibleThread
                        stop.pointee = true
                    }
                }
            }
        }

        return thread
    }
}

extension RecentViewController: UITableViewDelegate {

    open func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    open func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let thread = self.thread(at: indexPath) {
            let chatViewController = ChatViewController(thread: thread)
            navigationController?.pushViewController(chatViewController, animated: true)
        }
    }

    public func tableView(_: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action = UITableViewRowAction(style: .destructive, title: "Delete") { _, indexPath in
            if let thread = self.thread(at: indexPath) {

                TSStorageManager.shared().dbReadWriteConnection?.asyncReadWrite { transaction in
                    thread.remove(with: transaction)
                }
            }
        }

        return [action]
    }
}

extension RecentViewController: UITableViewDataSource {

    open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7// Int(mappings.numberOfItems(inSection: UInt(section)))
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let configurator = CellConfigurator()
        var reuseIdentifier = ""


        var tableData: TableCellData!

        if indexPath.row == 0 {
            tableData = TableCellData(title: "Toshi  title cell")
        } else if indexPath.row == 1 {
            tableData = TableCellData(title: "Toshi title and subtitle cell", subtitle: "The subtitle")
        } else if indexPath.row == 2 {
            tableData = TableCellData(title: "Title, subtitle and switch cell", subtitle: "some subtitle", switchState: false)
        } else if indexPath.row == 3 {
            tableData = TableCellData(title: "Title, subtitle and avatar cell", subtitle: "some subtitle", leftImage: UIImage(named: "CameraExposureIcon")!)
        } else if indexPath.row == 4 {
            tableData = TableCellData(title: "Title and avatar cell", leftImage: UIImage(named: "CameraExposureIcon")!)
        } else if indexPath.row == 5 {
            tableData = TableCellData(title: "Title and switch cell", switchState: true)
        } else if indexPath.row == 6 {
            tableData = TableCellData(title: "Title avatar, subtitle and details cell", subtitle: "Some subtitle", leftImage: UIImage(named: "CameraExposureIcon")!, details: "Detail")
        }

        reuseIdentifier = configurator.cellIdentifier(for: tableData.components)

        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        configurator.configureCell(cell, with: tableData)

        //let thread = self.thread(at: indexPath)

        // TODO: deal with last message from thread. It should be last visible message.
        //cell.thread = thread

        return cell
    }
}
