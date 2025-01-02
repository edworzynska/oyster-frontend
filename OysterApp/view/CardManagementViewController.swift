import UIKit

class CardManagementViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var cardPicker: UIPickerView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var transactionsTableView: UITableView!
    @IBOutlet weak var allTransactionsButton: UIButton!
    @IBOutlet weak var topUpButton: UIButton!
    @IBOutlet weak var issueNewCardButton: UIButton!
    @IBOutlet weak var registerCardButton: UIButton!

    var cards: [CardDTO] = []
    var selectedCard: CardDTO? {
        didSet {
            updateCardDetails()
        }
    }

    var transactions: [TransactionDTO] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        cardPicker.delegate = self
        cardPicker.dataSource = self
        transactionsTableView.delegate = self
        transactionsTableView.dataSource = self

        transactionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TransactionCell")

        fetchCards()
    }

    func fetchCards() {
        APIService.shared.getCards { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let cards):
                    self.cards = cards
                    self.cardPicker.reloadAllComponents()
                    self.selectedCard = cards.first
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self.showError("Unable to fetch cards: \(errorMessage)")
                        } else {
                            self.showError("Unable to fetch cards: \(nsError)")
                        }
                    } else {
                        self.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }

    func fetchTransactions(for card: CardDTO) {
        transactions = []
        transactionsTableView.reloadData()

        APIService.shared.getPaginatedTransactions(cardNumber: card.cardNumber, page: 0, size: 10) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let paginatedResponse):
                    self.transactions = paginatedResponse.content
                    self.transactionsTableView.reloadData()
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self.showError("Unable to load transactions: \(errorMessage)")
                        } else {
                            self.showError("Unable to load transactions: \(nsError)")
                        }
                    } else {
                        self.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }
    
    @IBAction func issueNewCardTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Issue New Card", message: "Are you sure you want to issue a new card?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [weak self] _ in
            self?.issueNewCard()
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        
        present(alert, animated: true)
    }

    func issueNewCard() {
        APIService.shared.issueNewCard { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cardDTO):
                    self?.fetchCards()
                    self?.cardPicker.reloadAllComponents()
                    self?.selectedCard = cardDTO
                    self?.updateCardDetails()
                    self?.showSuccess("New card issued successfully.")
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self?.showError("Unable to issue new card: \(errorMessage)")
                        } else {
                            self?.showError("Unable to issue new card: \(nsError)")
                        }
                    } else {
                        self?.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }
    @IBAction func registerCardTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Register Card", message: "Please enter your card number", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Card Number"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Register", style: .default, handler: { [weak self] _ in
            if let cardNumber = alert.textFields?.first?.text, let number = Int64(cardNumber) {
                self?.registerCard(cardNumber: number)
            }
//            else {
//                self?.showError("Invalid card number.")
//            }
        }))
        
        present(alert, animated: true)
    }

    func registerCard(cardNumber: Int64) {
        APIService.shared.registerCard(cardNumber: cardNumber) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cardDTO):
                    self?.fetchCards()
                    self?.cardPicker.reloadAllComponents()
                    self?.selectedCard = cardDTO
                    self?.updateCardDetails()
                    self?.showSuccess("Card registered successfully.")
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self?.showError("Unable to register the card: \(errorMessage)")
                        } else {
                            self?.showError("Unable to register the card: \(nsError)")
                        }
                    } else {
                        self?.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }


    func updateCardDetails() {
        if let card = selectedCard {

            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "GBP"
            balanceLabel.text = "Balance: \(formatter.string(from: NSNumber(value: card.balance)) ?? "0.00")"
          
            fetchTransactions(for: card)
            
            APIService.shared.selectCard(card)
        } else {
            balanceLabel.text = "No card selected"
            transactions = []
            transactionsTableView.reloadData()
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return cards.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let card = cards[row]
        return "Card: \(card.cardNumber) (Balance: \(card.balance))"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCard = cards[row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        let transaction = transactions[indexPath.row]

        let formattedDate = transaction.startAt.replacingOccurrences(of: "T", with: " ").prefix(16)
        let startStation = transaction.startStation.name
        let endStation = transaction.endStation?.name ?? "N/A"

        cell.textLabel?.text = "\(formattedDate) \(startStation) to \(endStation)"
        cell.detailTextLabel?.text = "Fare: \(transaction.fare ?? 0.0)"
        return cell
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
