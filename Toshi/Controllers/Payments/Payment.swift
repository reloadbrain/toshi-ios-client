import Foundation
import UIKit

let Payment = PaymentManager.shared

class PaymentManager {
    
    static let shared = PaymentManager()
    
    typealias SuccessCompletion = ((UIAlertAction) -> Void)
    
    func send(_ valueInWei: NSDecimalNumber, to paymentAddress: String, completion: @escaping SuccessCompletion) {
        
        let parameters: [String: Any] = [
            "from": Cereal.shared.paymentAddress,
            "to": paymentAddress,
            "value": valueInWei.toHexString
        ]
        
        EthereumAPIClient.shared.createUnsignedTransaction(parameters: parameters) { [weak self] transaction, error in
            
            guard let transaction = transaction else {
                
                if let error = error {
                    DispatchQueue.main.async {
                        self?.showPaymentFailedMessage(for: error.description)
                    }
                }
                
                return
            }
            
            let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction))"

            EthereumAPIClient.shared.sendSignedTransaction(originalTransaction: transaction, transactionSignature: signedTransaction) { [weak self] success, _, error in

                DispatchQueue.main.async {
                    guard success else {
                        self?.showPaymentFailedMessage(for: error?.description ?? ToshiError.genericError.description)
                        return
                    }

                    self?.showPaymentSucceededMessage(completion)
                }
            }
        }
    }
    
    func showPaymentFailedMessage(for errorMessage: String) {
        let alertController = UIAlertController(title: Localized("payment_message_failure_title"), message: errorMessage, preferredStyle: .alert)
        
        let action = UIAlertAction(title: Localized("payment_message_button"), style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(action)
        
        Navigator.presentModally(alertController)
    }
    
    func showPaymentSucceededMessage(_ completion: @escaping SuccessCompletion) {
        let action = UIAlertAction(title: Localized("payment_message_button"), style: .default, handler: completion)
        
        let alertController = UIAlertController(title: Localized("payment_message_success_title"), message: Localized("payment_message_success_message"), preferredStyle: .alert)
        alertController.addAction(action)
        
        Navigator.presentModally(alertController)
    }
}
