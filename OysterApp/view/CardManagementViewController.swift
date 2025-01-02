import UIKit

class CardManagementViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var cardPicker: UIPickerView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var transactionsTableView: UITableView!
    @IBOutlet weak var allTransactionsButton: UIButton!
    @IBOutlet weak var topUpButton: UIButton!

    var cards: [CardDTO] = []
    var selectedCard: CardDTO? {
        didSet {
            updateCardDetails()
        }
    }

    var transactions: [TransactionDTO] = []
    var currentPage = 0
    let pageSize = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardPicker.delegate = self
        cardPicker.dataSource = self
        transactionsTableView.delegate = self
        transactionsTableView.dataSource = self

        // Add double-tap gesture recognizer to the table view
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        transactionsTableView.addGestureRecognizer(doubleTapGesture)

        fetchCards()
    }
    
    // MARK: - Handle Double-Tap on TableView Row
    @objc func handleDoubleTap(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: transactionsTableView)
        if let indexPath = transactionsTableView.indexPathForRow(at: point) {
            let transaction = transactions[indexPath.row]
            showTransactionDetails(transaction)
        }
    }
    
    func showTransactionDetails(_ transaction: TransactionDTO) {
        let startAtString = transaction.startAt.replacingOccurrences(of: "T", with: " ").prefix(16)
        let startStationName = transaction.startStation.name
        let endStationName = transaction.endStation?.name ?? "N/A"
        let fare = transaction.fare ?? 0.0

        let message = """
        Date: \(startAtString)
        Start Station: \(startStationName)
        End Station: \(endStationName)
        Fare: \(fare)
        """

        let alert = UIAlertController(title: "Transaction Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Fetch Cards
    func fetchCards() {
        APIService.shared.getCards { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cards):
                    self?.cards = cards  // Assign the fetched cards to the cards property
                    self?.cardPicker.reloadAllComponents()  // Reload the picker to display the cards
                    self?.selectedCard = cards.first  // Optionally, set the first card as selected
                case .failure(let error):
                    self?.showError("Failed to load cards: \(error)")  // Show error if fetching fails
                }
            }
        }
    }

    // MARK: - Fetch Transactions for Selected Card
    func fetchTransactions(for card: CardDTO, reset: Bool = false) {
        if reset {
            currentPage = 0
            transactions = []
        }

        APIService.shared.getPaginatedTransactions(cardNumber: card.cardNumber, page: currentPage, size: pageSize) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let paginatedResponse):
                    self?.transactions.append(contentsOf: paginatedResponse.content)
                    self?.transactionsTableView.reloadData()
                case .failure(let error):
                    self?.showError("Failed to load transactions: \(error)")
                }
            }
        }
    }

    // MARK: - Update UI for Selected Card
    func updateCardDetails() {
        if let card = selectedCard {
            balanceLabel.text = "Balance: \(card.balance)"
            fetchTransactions(for: card, reset: true)
            APIService.shared.selectCard(selectedCard!)
        } else {
            balanceLabel.text = "No card selected"
            transactions = []
            transactionsTableView.reloadData()
        }
    }

    // MARK: - UIPickerView DataSource and Delegate
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
        APIService.shared.selectCard(selectedCard!)
        updateCardDetails()
    }

    // MARK: - UITableView DataSource and Delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        let transaction = transactions[indexPath.row]
        
        // Modify the startAt string to remove the 'T' and keep only the necessary parts
        let startAtString = transaction.startAt
        let formattedStartAt = startAtString.replacingOccurrences(of: "T", with: " ").prefix(16)
        
        // Format the station details
        let startStationName = transaction.startStation.name
        let endStationName = transaction.endStation?.name ?? "N/A"
        
        // Set the formatted date and transaction details in the cell
        cell.textLabel?.text = "\(formattedStartAt) \(startStationName) to \(endStationName)"
        cell.detailTextLabel?.text = "Amount: \(transaction.fare ?? 0.0)"
        
        return cell
    }


    // MARK: - Actions
    @IBAction func topUpButtonTapped(_ sender: UIButton) {
        let topUpVC = TopUpViewController()  // Pass cards to TopUpViewController
        navigationController?.pushViewController(topUpVC, animated: true)
    }

    @IBAction func loadAllTransactionsTapped(_ sender: UIButton) {
        guard let card = selectedCard else {
            showError("No card selected.")
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let allTransactionsVC = storyboard.instantiateViewController(identifier: "AllTransactionsViewController") as? AllTransactionsViewController else {
            return
        }

        navigationController?.pushViewController(allTransactionsVC, animated: true)
    }

    // MARK: - Show Error Alert
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
