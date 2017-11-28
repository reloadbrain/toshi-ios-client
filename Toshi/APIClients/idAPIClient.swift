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
import AwesomeCache
import SweetFoundation
import Teapot

@objc public enum UserRegisterStatus: Int {
    case existing = 0, registered, failed
}

@objc public class IDAPIClient: NSObject, CacheExpiryDefault {
    @objc public static let shared: IDAPIClient = IDAPIClient()

    public static let usernameValidationPattern = "^[a-zA-Z][a-zA-Z0-9_]+$"

    public static let didFetchContactInfoNotification = Notification.Name(rawValue: "DidFetchContactInfo")

    public static let allowedSearchTermCharacters = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: ":/?#[]@!$&'()*+,;= "))

    public var teapot: Teapot

    private let topRatedUsersCachedDataKey = "topRatedUsersCachedData"
    private let latestUsersCachedDataKey = "latestUsersCachedData"

    private let topRatedUsersCachedData = TokenUsersCacheData()
    private let latestUsersCachedData = TokenUsersCacheData()

    private lazy var cache: Cache<TokenUsersCacheData> = {
        do {
            return try Cache<TokenUsersCacheData>(name: "usersCache")
        } catch {
            fatalError("Couldn't instantiate the apps cache")
        }
    }()

    private lazy var contactCache: Cache<TokenUser> = {
        do {
            return try Cache<TokenUser>(name: "tokenContactCache")
        } catch {
            fatalError("Couldn't instantiate the contact cache")
        }
    }()

    private lazy var updateOperationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 2 //we update collections under "storedContactKey" and "favoritesCollectionKey" concurrently
        queue.name = "Update contacts queue"

        return queue
    }()

    public var baseURL: URL

    convenience init(teapot: Teapot, cacheEnabled: Bool = true) {
        self.init()
        self.teapot = teapot

        if !cacheEnabled {
            self.cache.removeAllObjects()
        }
    }

    private override init() {
        baseURL = URL(string: ToshiIdServiceBaseURLPath)!
        teapot = Teapot(baseURL: baseURL)

        super.init()
    }

    /// We use a background queue and a semaphore to ensure we only update the UI
    /// once all the contacts have been processed.
    func updateContacts() {
        updateOperationQueue.cancelAllOperations()

        updateContacts(for: TokenUser.storedContactKey)
        updateContacts(for: TokenUser.favoritesCollectionKey)
    }

    private func updateContacts(for collectionKey: String) {
        let operation = BlockOperation()
        operation.addExecutionBlock { [weak self] in
            guard let contactsData = Yap.sharedInstance.retrieveObjects(in: collectionKey) as? [Data] else { return }

            for contactData in contactsData {
                guard let dictionary = try? JSONSerialization.jsonObject(with: contactData, options: []) else { continue }

                if let dictionary = dictionary as? [String: Any] {
                    let tokenContact = TokenUser(json: dictionary)
                    self?.findContact(name: tokenContact.address) { updatedContact in

                        if let updatedContact = updatedContact {
                            Yap.sharedInstance.insert(object: updatedContact.json, for: updatedContact.address, in: collectionKey)
                        }

                    }
                }
            }
        }

        updateOperationQueue.addOperation(operation)
    }

    func updateContact(with identifier: String) {
        findContact(name: identifier) { updatedContact in
            if let updatedContact = updatedContact {

                Yap.sharedInstance.insert(object: updatedContact.json, for: updatedContact.address, in: TokenUser.storedContactKey)

                guard identifier != Cereal.shared.address else {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .currentUserUpdated, object: nil)
                    }
                    return
                }

                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                appDelegate.contactsManager.refreshContact(updatedContact)
            }
        }
        
    }

    func fetchTimestamp(_ completion: @escaping ((_ timestamp: Int?, _ error: ToshiError?) -> Void)) {

        self.teapot.get("/v1/timestamp") { (result: NetworkResult) in
            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary, let timestamp = json["timestamp"] as? Int else {
                    print("No response json - Fetch timestamp")
                    completion(nil, .invalidResponseJSON)
                    return
                }

                completion(timestamp, nil)
            case .failure(_, _, let error):
                completion(nil, ToshiError(withTeapotError: error))
            }
        }
    }

    public func migrateCurrentUserIfNeeded() {
        guard let user = TokenUser.current, user.paymentAddress != Cereal.shared.paymentAddress else {
            return
        }

        var userDict = user.dict
        userDict[TokenUser.Constants.paymentAddress] = Cereal.shared.paymentAddress

        updateUser(userDict) { _, _ in }
    }

    @objc public func registerUserIfNeeded(_ success: @escaping ((_ userRegisterStatus: UserRegisterStatus) -> Void)) {
        retrieveUser(username: Cereal.shared.address) { user in

            guard user == nil else {
                success(.existing)
                return
            }

            self.fetchTimestamp { timestamp, error in
                guard let timestamp = timestamp else {
                    success(.failed)
                    return
                }
                
                let cereal = Cereal.shared
                let path = "/v1/user"
                let parameters = [
                    "payment_address": cereal.paymentAddress
                ]

                guard let data = try? JSONSerialization.data(withJSONObject: parameters, options: []), let parametersString = String(data: data, encoding: .utf8) else {
                    success(.failed)
                    return
                }

                let hashedParameters = cereal.sha3WithID(string: parametersString)
                let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedParameters)"))"

                let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]

                let json = RequestParameter(parameters)

                self.teapot.post(path, parameters: json, headerFields: fields) { result in
                    var status: UserRegisterStatus = .failed

                    switch result {
                    case .success(let json, let response):
                        guard response.statusCode == 200 else { return }
                        guard let json = json?.dictionary else { return }

                        TokenUser.createCurrentUser(with: json)
                        status = .registered
                    case .failure(_, _, let error):
                        print(error)
                        status = .failed
                    }

                    DispatchQueue.main.async {
                        success(status)
                    }
                }
                
            }
        }
    }

    public func updateAvatar(_ avatar: UIImage, completion: @escaping ((_ success: Bool, _ error: ToshiError?) -> Void)) {
        fetchTimestamp { timestamp, error in
            guard let timestamp = timestamp else {
                completion(false, error)
                return
            }

            let cereal = Cereal.shared
            let path = "/v1/user"
            let boundary = "teapot.boundary"
            let payload = self.teapot.multipartData(from: avatar, boundary: boundary, filename: "avatar.png")
            let hashedPayload = cereal.sha3WithID(data: payload)
            let signature = "0x\(cereal.signWithID(message: "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp), "Content-Length": String(describing: payload.count), "Content-Type": "multipart/form-data; boundary=\(boundary)"]
            let json = RequestParameter(payload)

            self.teapot.put(path, parameters: json, headerFields: fields) { result in
                var succeeded = false
                var toshiError: ToshiError?

                switch result {
                case .success(let json, _):
                    guard let userDict = json?.dictionary else {
                        completion(false, .invalidResponseJSON)
                        return
                    }

                    if let path = userDict["avatar"] as? String {
                        AvatarManager.shared.refreshAvatar(at: path)
                        TokenUser.current?.update(avatar: avatar, avatarPath: path)
                    }

                    succeeded = true
                case .failure(_, _, let error):
                    print(error)
                    toshiError = ToshiError(withTeapotError: error)
                }

                DispatchQueue.main.async {
                    completion(succeeded, toshiError)
                }
            }
            
        }
    }

    public func updateUser(_ userDict: [String: Any], completion: @escaping ((_ success: Bool, _ error: ToshiError?) -> Void)) {
        fetchTimestamp { timestamp, error in
            guard let timestamp = timestamp else {
                completion(false, error)
                return
            }

            let cereal = Cereal.shared
            let path = "/v1/user"

            guard let payload = try? JSONSerialization.data(withJSONObject: userDict, options: []), let payloadString = String(data: payload, encoding: .utf8) else {
                completion(false, .invalidPayload)
                return
            }

            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let signature = "0x\(cereal.signWithID(message: "PUT\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let json = RequestParameter(userDict)

            self.teapot.put("/v1/user", parameters: json, headerFields: fields) { result in
                var succeeded = false
                var toshiError: ToshiError?

                switch result {
                case .success(let json, let response):
                    guard response.statusCode == 200, let json = json?.dictionary else {
                        print("Invalid response - Update user")
                        completion(false, ToshiError(withType: .invalidResponseStatus, description: "User could not be updated", responseStatus: response.statusCode))
                        return
                    }

                    TokenUser.current?.update(json: json)
                    succeeded = true
                case .failure(let json, _, let error):

                    if let errors = json?.dictionary?["errors"] as? [[String: Any]], let errorMessage = (errors.first?["message"] as? String) {
                        toshiError = ToshiError(withTeapotError: error, errorDescription: errorMessage)
                    } else {
                        toshiError = ToshiError(withTeapotError: error)
                    }

                }

                DispatchQueue.main.async {
                    completion(succeeded, toshiError)
                }
            }
        }
    }

    /// Used to retrieve the server-side data for the current user. For contacts use retrieveContact(username:completion:)
    ///
    /// - Parameters:
    ///   - username: username of id address
    ///   - completion: called on completion
    @objc public func retrieveUser(username: String, completion: @escaping ((TokenUser?) -> Void)) {

        self.teapot.get("/v1/user/\(username)", headerFields: ["Token-Timestamp": String(Int(Date().timeIntervalSince1970))]) { (result: NetworkResult) in
            var resultUser: TokenUser?

            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else {
                    completion(nil)
                    return
                }

                resultUser = TokenUser(json: json)
            case .failure(_, _, let error):
                print(error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion(resultUser)
            }
        }
    }

    public func findContact(name: String, completion: @escaping ((TokenUser?) -> Void)) {

        self.teapot.get("/v1/user/\(name)") { [weak self] (result: NetworkResult) in
            guard let strongSelf = self else {
                completion(nil)
                return
            }

            var contact: TokenUser?

            switch result {
            case .success(let json, _):
                guard let json = json?.dictionary else {
                    completion(nil)
                    return
                }

                contact = TokenUser(json: json)
                if contact != nil {
                    strongSelf.contactCache.setObject(contact!, forKey: name, expires: strongSelf.cacheExpiry)
                }
                NotificationCenter.default.post(name: IDAPIClient.didFetchContactInfoNotification, object: contact)
            case .failure(_, _, let error):
                print(error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion(contact)
            }
        }
    }

    public func searchContacts(name: String, completion: @escaping (([TokenUser]) -> Void)) {
        let query = name.addingPercentEncoding(withAllowedCharacters: IDAPIClient.allowedSearchTermCharacters) ?? name
        self.teapot.get("/v1/search/user?query=\(query)") { (result: NetworkResult) in
            var results: [TokenUser] = []

            switch result {
            case .success(let json, _):
                guard let dictionary = json?.dictionary, var json = dictionary["results"] as? [[String: Any]] else {
                    completion([])
                    return
                }

                var contacts = [TokenUser]()
                json = json.filter { item -> Bool in
                    guard let address = item[TokenUser.Constants.address] as? String else { return true }
                    return address != Cereal.shared.address
                }

                for item in json {
                    contacts.append(TokenUser(json: item))
                }

                results = contacts
            case .failure(_, _, let error):
                print(error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion(results)
            }
        }
    }

    public func getTopRatedPublicUsers(limit: Int = 10, completion: @escaping TokenUserResults) {

        if let data = self.cache.object(forKey: topRatedUsersCachedDataKey), let ratedUsers = data.objects {
            completion(ratedUsers, nil)
        }

        self.teapot.get("/v1/search/user?public=true&top=true&recent=false&limit=\(limit)") { [weak self] (result: NetworkResult) in
            var results: [TokenUser] = []
            var resultError: ToshiError?

            switch result {
            case .success(let json, _):
                guard let strongSelf = self, let dictionary = json?.dictionary, let json = dictionary["results"] as? [[String: Any]] else {
                    completion([], nil)
                    return
                }

                let contacts = json.map { userJSON in
                    TokenUser(json: userJSON)
                }

                contacts.forEach { AvatarManager.shared.downloadAvatar(for: $0.avatarPath) }

                strongSelf.topRatedUsersCachedData.objects = contacts
                strongSelf.cache.setObject(strongSelf.topRatedUsersCachedData, forKey: strongSelf.topRatedUsersCachedDataKey)

                results = contacts
            case .failure(_, _, let error):
                print(error.localizedDescription)
                resultError = ToshiError(withTeapotError: error)
            }

            DispatchQueue.main.async {
                completion(results, resultError)
            }
        }
    }

    public func getLatestPublicUsers(limit: Int = 10, completion: @escaping TokenUserResults) {

        if let data = self.cache.object(forKey: latestUsersCachedDataKey), let ratedUsers = data.objects {
            completion(ratedUsers, nil)
        }

        self.teapot.get("/v1/search/user?public=true&top=false&recent=true&limit=\(limit)") { [weak self] (result: NetworkResult) in
            var results: [TokenUser] = []
            var resultError: ToshiError?

            switch result {
            case .success(let json, _):
                guard let strongSelf = self, let dictionary = json?.dictionary, let json = dictionary["results"] as? [[String: Any]] else {
                    completion([], nil)
                    return
                }

                let contacts = json.map { userJSON in
                    TokenUser(json: userJSON)
                }

                contacts.forEach { AvatarManager.shared.downloadAvatar(for: $0.avatarPath) }

                strongSelf.latestUsersCachedData.objects = contacts
                strongSelf.cache.setObject(strongSelf.latestUsersCachedData, forKey: strongSelf.latestUsersCachedDataKey)

                results = contacts
            case .failure(_, _, let error):
                print(error.localizedDescription)
                resultError = ToshiError(withTeapotError: error)
            }

            DispatchQueue.main.async {
                completion(results, resultError)
            }
        }
    }

    public func reportUser(address: String, reason: String = "", completion: @escaping ((_ success: Bool, _ error: ToshiError?) -> Void) = { (Bool, String) in }) {
        fetchTimestamp { timestamp, error in
            guard let timestamp = timestamp else {
                completion(false, error)
                return
            }

            let cereal = Cereal.shared
            let path = "/v1/report"

            let payload = [
                "token_id": address,
                "details": reason
            ]

            guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: []), let payloadString = String(data: payloadData, encoding: .utf8) else {
                completion(false, .invalidPayload)
                return
            }

            let hashedPayload = cereal.sha3WithID(string: payloadString)
            let signature = "0x\(cereal.signWithID(message: "POST\n\(path)\n\(timestamp)\n\(hashedPayload)"))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]
            let json = RequestParameter(payload)

            self.teapot.post(path, parameters: json, headerFields: fields) { result in
                var succeeded = false
                var toshiError: ToshiError?

                switch result {
                case .success(_, let response):
                    guard response.statusCode == 204 else {
                        print("Invalid response - Report user")
                        completion(false, ToshiError(withType: .invalidResponseStatus, description: "Request to report user could not be completed", responseStatus: response.statusCode))
                        return
                    }

                    succeeded = true
                case .failure(let json, _, let error):
                    if let errors = json?.dictionary?["errors"] as? [[String: Any]], let errorMessage = errors.first?["message"] as? String {
                        toshiError = ToshiError(withTeapotError: error, errorDescription: errorMessage)
                    } else {
                        toshiError = ToshiError(withTeapotError: error)
                    }
                }

                DispatchQueue.main.async {
                    completion(succeeded, toshiError)
                }
            }
        }
    }

    public func adminLogin(loginToken: String, completion: @escaping ((_ success: Bool, _ error: ToshiError?) -> Void) = { (Bool, String) in }) {
        fetchTimestamp { timestamp, error in
            guard let timestamp = timestamp else {
                completion(false, error)
                return
            }

            let cereal = Cereal.shared
            let path = "/v1/login/\(loginToken)"

            let signature = "0x\(cereal.signWithID(message: "GET\n\(path)\n\(timestamp)\n"))"

            let fields: [String: String] = ["Token-ID-Address": cereal.address, "Token-Signature": signature, "Token-Timestamp": String(timestamp)]

            self.teapot.get(path, headerFields: fields) { result in
                var succeeded = false
                var toshiError: ToshiError?

                switch result {
                case .success(_, let response):
                    guard response.statusCode == 204 else {
                        print("Invalid response - Login")
                        completion(false, ToshiError(withType: .invalidResponseStatus, description: "Request to login as admin could not be completed", responseStatus: response.statusCode))
                        return
                    }

                    succeeded = true
                case .failure(let json, _, let error):
                    if let errors = json?.dictionary?["errors"] as? [[String: Any]], let errorMessage = (errors.first?["message"] as? String) {
                        toshiError = ToshiError(withTeapotError: error, errorDescription: errorMessage)
                    } else {
                        toshiError = ToshiError(withTeapotError: error)
                    }
                }

                DispatchQueue.main.async {
                    completion(succeeded, toshiError)
                }
            }
        }
    }
}
