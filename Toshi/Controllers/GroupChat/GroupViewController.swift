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

open class GroupViewController: UIViewController, KeyboardAdjustable, UINavigationControllerDelegate {

    private var configurator: ToshiCellConfigurator
    private var viewModel: GroupViewModelProtocol

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

    init(_ viewModel: GroupViewModelProtocol, configurator: ToshiCellConfigurator) {
        self.viewModel = viewModel
        self.configurator = configurator
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
            self.navigationController?.navigationBar.prefersLargeTitles = false
        }

        view.backgroundColor = Theme.lightGrayBackgroundColor
        title = viewModel.viewControllerTitle

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: viewModel.rightBarButtonTitle, style: .plain, target:
            viewModel, action: viewModel.rightBarButtonSelector)
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([.font: Theme.bold(size: 17.0), .foregroundColor: Theme.tintColor], for: .normal)

        addSubviewsAndConstraints()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        registerForKeyboardNotifications()
        adjustDoneButton()
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

        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    @objc func updateAvatar() {
        let pickerTypeAlertController = UIAlertController(title: viewModel.imagePickerTitle, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: viewModel.imagePickerCameraActionTitle, style: .default) { _ in
            self.presentImagePicker(sourceType: .camera)
        }

        let libraryAction = UIAlertAction(title: viewModel.imagePickerLibraryActionTitle, style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }

        let cancelAction = UIAlertAction(title: viewModel.imagePickerCancelActionTitle, style: .cancel, handler: nil)

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
            viewModel.updateAvatar(avatar)
            tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }
    }

    @objc func cancelAndDismiss() {
        navigationController?.popViewController(animated: true)
    }

    fileprivate func completeEdit(success: Bool, message: String?) {
        activityIndicator.stopAnimating()

        if success == true {
            navigationController?.popViewController(animated: true)
        } else {
            let alert = UIAlertController.dismissableAlert(title: viewModel.errorAlertTitle, message: message ?? viewModel.errorAlertMessage)
            Navigator.presentModally(alert)
        }
    }

    @objc private func didTapView(sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            becomeFirstResponder()
        }
    }

    private lazy var activityIndicator: UIActivityIndicatorView = {
        // need to initialize with large style which is available only white, thus need to set color later
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = Theme.lightGreyTextColor
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        return activityIndicator
    }()

    private func adjustDoneButton() {
        navigationItem.rightBarButtonItem?.isEnabled = viewModel.isDoneButtonEnabled
    }
}

extension GroupViewController: UIImagePickerControllerDelegate {

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

extension GroupViewController: UITableViewDelegate {

    public func tableView(_: UITableView, estimatedHeightForRowAt _: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let sectionData = viewModel.sectionModels[indexPath.section]
        let cellData = sectionData.cellsData[indexPath.row]

        switch cellData.tag {
        case NewGroupItemType.addParticipant.rawValue:
            break // push participants picker
        default:
            break
        }
    }
}

extension GroupViewController: UITableViewDataSource {

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

        let sectionData = viewModel.sectionModels[indexPath.section]
        let cellData = sectionData.cellsData[indexPath.row]

        let reuseIdentifier = configurator.cellIdentifier(for: cellData.components)

        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as? ToshiTableViewCell else { return UITableViewCell(frame: .zero) }
        configurator.configureCell(cell, with: cellData)
        cell.actionDelegate = self

        return cell
    }
}

extension GroupViewController: ToshiCellActionDelegate {

    func didChangeSwitchState(_ cell: ToshiTableViewCell, _ state: Bool) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        viewModel.updatePublicState(state)
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func didTapLeftImage(_ cell: ToshiTableViewCell) {
        cell.titleTextField?.resignFirstResponder()
        updateAvatar()
    }

    func didFinishTitleInput(_ cell: ToshiTableViewCell, text: String?) {
        let title = text?.trimmingCharacters(in: .whitespaces) ?? ""
        viewModel.updateTitle(title)
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }

    func titleShouldChangeCharactersInRange(_ cell: ToshiTableViewCell, text: String?, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let resultText = (text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
        viewModel.updateTitle(resultText)
        adjustDoneButton()

        return true
    }
}

