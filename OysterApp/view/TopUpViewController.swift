import UIKit

class TopUpViewController: UIViewController {

    var selectedCard: CardDTO?
    var cards: [CardDTO] = []

    @IBOutlet weak var cardInfoLabel: UILabel!
    @IBOutlet weak var topUpAmountTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Top Up Card"
        topUpAmountTextField.keyboardType = .decimalPad
        
        self.selectedCard = APIService.shared.getSelectedCard()

        updateCardInfo()

        confirmButton.isEnabled = selectedCard != nil
    }

    private func updateCardInfo() {
        if let selectedCard = selectedCard {
            cardInfoLabel.text = "Card Number: \(selectedCard.cardNumber)\nBalance: \(selectedCard.balance)"
        } else {
            cardInfoLabel.text = "No Card Selected"
        }
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        guard let selectedCard = selectedCard else {
            showError("No card selected.")
            return
        }

        guard let amountText = topUpAmountTextField.text, let topUpAmount = Double(amountText), topUpAmount > 0 else {
            showError("Please enter a valid top-up amount.")
            return
        }

        APIService.shared.topUpCard(cardNumber: selectedCard.cardNumber, amount: topUpAmount) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self?.showSuccess("Top-up successful!")
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self?.showError("Top up failed: \(errorMessage)")
                        } else {
                            self?.showError("Top up failed: \(nsError)")
                        }
                    } else {
                        self?.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }

    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
