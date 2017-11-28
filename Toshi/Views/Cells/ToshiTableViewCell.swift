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

import Foundation
import UIKit
import TinyConstraints

protocol ToshiCellActionDelegate {
    func didTapLeftImage(_ cell: ToshiTableViewCell)
    func didChangeSwitchState(_ cell: ToshiTableViewCell, _ state: Bool)
    func didFinishTitleInput(_ cell: ToshiTableViewCell, text: String?)
}

//extenstion with default implementation which is alternative for optional functions in protocols
extension ToshiCellActionDelegate {
    func didTapLeftImage(_ cell: ToshiTableViewCell) {}
    func didChangeSwitchState(_ cell: ToshiTableViewCell, _ state: Bool) {}
    func didFinishTitleInput(_ cell: ToshiTableViewCell, text: String?) {}
}

class ToshiTableViewCell: UITableViewCell {

    var actionDelegate: ToshiCellActionDelegate? {
        didSet {
            setupActions()
        }
    }

    var titleTextField: UITextField?
    var subtitleLabel: UILabel?
    var detailsLabel: UILabel?
    var leftImageView: UIImageView?
    var switchControl: UISwitch?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubviewsAndConstraints()
        setupTextStyles()

        selectionStyle = .none
        leftImageView?.isUserInteractionEnabled = true
        titleTextField?.delegate = self
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func addSubviewsAndConstraints() {
        fatalError("addSubviewsAndConstraints() should be overriden")
    }

    private func setupTextStyles() {
        titleTextField?.font = Theme.preferredRegular()
        titleTextField?.isUserInteractionEnabled = false

        subtitleLabel?.font = Theme.preferredRegularSmall()
        detailsLabel?.font = Theme.preferredFootnote()

        subtitleLabel?.textColor = Theme.lightGreyTextColor
    }

    private func setupActions() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapLeftImage(_:)))
        leftImageView?.addGestureRecognizer(tapGesture)

        switchControl?.addTarget(self, action: #selector(didChangeSwitchState(_:)), for: .valueChanged)
    }

    @objc private func didTapLeftImage(_ tapGesture: UITapGestureRecognizer) {
        actionDelegate?.didTapLeftImage(self)
    }

    @objc private func didChangeSwitchState(_ switchControl: UISwitch) {
        actionDelegate?.didChangeSwitchState(self, switchControl.isOn)
    }

    public static func register(in tableView: UITableView) {
        tableView.register(TitleCell.self)
        tableView.register(TitleSubtitleCell.self)
        tableView.register(AvatarTitleCell.self)
        tableView.register(TitleSwitchCell.self)
        tableView.register(AvatarTitleSubtitleCell.self)
        tableView.register(TitleSubtitleSwitchCell.self)
        tableView.register(AvatarTitleSubtitleCell.self)
        tableView.register(AvatarTitleSubtitleDetailsCell.self)
    }
}

extension ToshiTableViewCell: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        self.actionDelegate?.didFinishTitleInput(self, text: textField.text)
    }
}
