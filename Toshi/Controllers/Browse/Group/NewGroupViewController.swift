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
import SweetUIKit
import SweetFoundation

open class NewGroupViewController: UIViewController, KeyboardAdjustable, UINavigationControllerDelegate {

    private let viewModel = NewGroupViewModel()

    fileprivate static let profileVisibilitySectionTitle = Localized("Profile visibility")
    fileprivate static let profileVisibilitySectionFooter = Localized("Setting your profile to public will allow it to show up on the Browse page. Other users will be able to message you from there.")

    var scrollViewBottomInset: CGFloat = 0.0

    var scrollView: UIScrollView {
        return tableView
    }

    var keyboardWillShowSelector: Selector {
        return #selector(keyboardShownNotificationReceived(_:))
    }

    var keyboardWillHideSelector: Selector {
        return #selector(keyboardHiddenNotificationReceived(_:))
    }

    @objc private func keyboardShownNotificationReceived(_ notification: NSNotification) {
        keyboardWillShow(notification)
    }

    @objc private func keyboardHiddenNotificationReceived(_ notification: NSNotification) {
        keyboardWillHide(notification)
    }

    fileprivate lazy var tableView: UITableView = {
        let view = UITableView(frame: self.view.frame, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.backgroundColor = nil
        view.isOpaque = false
        ToshiTableViewCell.register(in: view)
        view.delegate = self
        view.dataSource = self
        view.tableFooterView = UIView()
        view.layer.borderWidth = .lineHeight
        view.layer.borderColor = Theme.borderColor.cgColor
        view.alwaysBounceVertical = true

        return view
    }()

    open override var canBecomeFirstResponder: Bool {
        return true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.lightGrayBackgroundColor
        title = "New Group"

        navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: "Create", style: .plain, target: self, action: #selector(self.create))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([.font: Theme.bold(size: 17.0), .foregroundColor: Theme.tintColor], for: .normal)

        addSubviewsAndConstraints()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerForKeyboardNotifications()
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scrollViewBottomInset = tableView.contentInset.bottom
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        unregisterFromKeyboardNotifications()
    }

    func addSubviewsAndConstraints() {
        view.addSubview(tableView)
        view.addSubview(self.activityIndicator)

        self.activityIndicator.set(height: 50.0)
        self.activityIndicator.set(width: 50.0)
        self.activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        self.activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        tableView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    @objc func updateAvatar() {
        let pickerTypeAlertController = UIAlertController(title: Localized("image-picker-select-source-title"), message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: Localized("image-picker-camera-action-title"), style: .default) { _ in
            self.presentImagePicker(sourceType: .camera)
        }

        let libraryAction = UIAlertAction(title: Localized("image-picker-library-action-title"), style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }

        let cancelAction = UIAlertAction(title: Localized("cancel_action_title"), style: .cancel, handler: nil)

        pickerTypeAlertController.addAction(cameraAction)
        pickerTypeAlertController.addAction(libraryAction)
        pickerTypeAlertController.addAction(cancelAction)

        present(pickerTypeAlertController, animated: true)
    }

    fileprivate func presentImagePicker(sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.allowsEditing = true
        imagePicker.delegate = self

        present(imagePicker, animated: true)
    }

    func changeAvatar(to avatar: UIImage?) {
        if let avatar = avatar {
            let scaledImage = avatar.resized(toHeight: 320)
            // CHANGE AVATAR TO SCALED IMAGE
        }
    }

    @objc func cancelAndDismiss() {
        navigationController?.popViewController(animated: true)
    }

    @objc func create() {

    }

    fileprivate func validateName(_ username: String) -> Bool {
        let none = NSRegularExpression.MatchingOptions(rawValue: 0)
        let range = NSRange(location: 0, length: username.characters.count)

        var isValid = true

        if isValid {
            isValid = username.characters.count >= 2
        }

        if isValid {
            isValid = username.characters.count <= 60
        }

        var regex: NSRegularExpression?
        do {
            let pattern = IDAPIClient.usernameValidationPattern
            regex = try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines, .dotMatchesLineSeparators, .useUnicodeWordBoundaries])
        } catch {
            fatalError("Invalid regular expression pattern")
        }

        if isValid {
            if let validationRegex = regex {
                isValid = validationRegex.numberOfMatches(in: username, options: none, range: range) >= 1
            }
        }

        return isValid
    }

    fileprivate func completeEdit(success: Bool, message: String?) {
        activityIndicator.stopAnimating()

        if success == true {
            navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController.dismissableAlert(title: "Error", message: message ?? "Something went wrong")
            Navigator.presentModally(alert)
        }
    }

    @objc private func didTapView(sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            becomeFirstResponder()
        }
    }

    fileprivate lazy var activityIndicator: UIActivityIndicatorView = {
        // need to initialize with large style which is available only white, thus need to set color later
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = Theme.lightGreyTextColor
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        return activityIndicator
    }()
}

extension NewGroupViewController: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        picker.dismiss(animated: true, completion: nil)

        guard let image = info[UIImagePickerControllerEditedImage] as? UIImage else {
            return
        }

        self.changeAvatar(to: image)
    }
}

extension NewGroupViewController: UITableViewDelegate {

    public func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionData = viewModel.sectionModels[indexPath.section]
        let cellData = sectionData.cellsData[indexPath.row]

        switch cellData.tag {
        case NewGroupItemType.participant.rawValue:
            break // open participan details
        case NewGroupItemType.addParticipant.rawValue:
            break // push participants picker
        default:
            break
        }
    }
}

extension NewGroupViewController: UITableViewDataSource {

    public func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionData = viewModel.sectionModels[section]
        return sectionData.headerTitle
    }

    public func tableView(_: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionData = viewModel.sectionModels[section]
        return sectionData.footerTitle
    }

    public func numberOfSections(in _: UITableView) -> Int {
        return viewModel.sectionModels.count
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionData = viewModel.sectionModels[section]
        return sectionData.cellsData.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let configurator = NewGroupConfigurator()

        let sectionData = viewModel.sectionModels[indexPath.section]
        let cellData = sectionData.cellsData[indexPath.row]

        let reuseIdentifier = configurator.cellIdentifier(for: cellData.components)

        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        configurator.configureCell(cell, with: cellData)

        return cell
    }
}

extension NewGroupViewController: ToshiCellActionDelegate {

    func didChangeSwitchState(_ cell: ToshiTableViewCell, _ state: Bool) {

    }

    func didTapLeftImage(_ cell: ToshiTableViewCell) {

    }
}

