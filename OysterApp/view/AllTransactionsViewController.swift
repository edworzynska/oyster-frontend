import UIKit

class AllTransactionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var transactionsTableView: UITableView!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    var transactions: [TransactionDTO] = []
    var selectedStartDate: Date? = nil
    var selectedEndDate: Date? = nil
    var allTransactions: [TransactionDTO] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        transactionsTableView.delegate = self
        transactionsTableView.dataSource = self
        transactionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TransactionCell")

        startDatePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(datePickerChanged), for: .valueChanged)

        fetchSelectedCardAndTransactions()
    }

    @objc func datePickerChanged() {
        selectedStartDate = startDatePicker.date
        selectedEndDate = endDatePicker.date
        fetchTransactions(for: getSelectedCard()!)
    }

    @objc func filterTransactions() {
        if let start = selectedStartDate, let end = selectedEndDate {
            transactions = allTransactions.filter { transaction in
                guard let transactionDate = transaction.startAtDate else { return false }
                return transactionDate >= start && transactionDate <= end
            }
        } else {
            transactions = allTransactions
        }
        transactionsTableView.reloadData()
    }

    func fetchSelectedCardAndTransactions() {
        guard let selectedCard = getSelectedCard() else {
            showError("No card selected. Please go back and select a card.")
            return
        }

        fetchTransactions(for: selectedCard)
    }

    func getSelectedCard() -> CardDTO? {
        return APIService.shared.getSelectedCard()
    }

    func fetchTransactions(for card: CardDTO) {
            print("Fetching transactions for card: \(card.cardNumber)")

            APIService.shared.getPaginatedTransactions(
                cardNumber: card.cardNumber,
                page: 0,
                size: 100,
                startDate: selectedStartDate,
                endDate: selectedEndDate
            ) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let paginatedResponse):
                        self?.transactions = paginatedResponse.content
                        print("Transactions fetched: \(paginatedResponse.content.count) transactions")
                        self?.transactionsTableView.reloadData()
                    case .failure(let error):
                        self?.handleError(error)
                    }
                }
            }
        }

    func setDefaultDatePickerValues() {
        guard let firstTransaction = allTransactions.first,
              let lastTransaction = allTransactions.last,
              let oldestDate = ISO8601DateFormatter().date(from: firstTransaction.startAt),
              let newestDate = ISO8601DateFormatter().date(from: lastTransaction.startAt) else { return }

        startDatePicker.date = oldestDate
        endDatePicker.date = newestDate
        selectedStartDate = oldestDate
        selectedEndDate = newestDate
    }

    func handleError(_ error: Error) {
        showError("Unable to load transactions: \(error.localizedDescription)")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.isEmpty ? 1 : transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)

        if transactions.isEmpty {
            cell.textLabel?.text = "No transactions found in selected dates."
            cell.detailTextLabel?.text = nil
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "GBP"
            
            let transaction = transactions[indexPath.row]
            let startAtString = transaction.startAt.replacingOccurrences(of: "T", with: " ").prefix(16)
            let amount: String

            if transaction.transactionType == "CHARGE" {
                amount = formatter.string(from: NSNumber(value: transaction.fare ?? 0.0)) ?? "0.00"
                cell.textLabel?.text = "\(startAtString) - \(transaction.startStation!.name) to \(transaction.endStation?.name ?? "N/A") - \(amount)"
            } else if transaction.transactionType == "TOP_UP" {
                amount = formatter.string(from: NSNumber(value: transaction.topUpAmount ?? 0.0)) ?? "0.00"
                cell.textLabel?.text = "\(startAtString) - Top up - \(amount)"
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !transactions.isEmpty else { return }
        let transaction = transactions[indexPath.row]
        presentTransactionDetails(transaction)
    }

    func presentTransactionDetails(_ transaction: TransactionDTO) {
        let startAtString = transaction.startAt.replacingOccurrences(of: "T", with: " ").prefix(16)
        let message: String
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        
        if transaction.transactionType == "CHARGE" {
            let startStationName = transaction.startStation?.name ?? "N/A"
            let endStationName = transaction.endStation?.name ?? "N/A"
            let amount = formatter.string(from: NSNumber(value: transaction.fare ?? 0.0)) ?? "0.00"
        
            message = """
            Date: \(startAtString)
            Start Station: \(startStationName)
            End Station: \(endStationName)
            Amount: \(amount)
            """
        } else if transaction.transactionType == "TOP_UP" {
            let amount = formatter.string(from: NSNumber(value: transaction.topUpAmount ?? 0.0)) ?? "0.00"
            
            message = """
            Date: \(startAtString)
            Top-Up Amount: \(amount)
            """
        } else {
            message = "Unknown transaction type."
        }

        let alert = UIAlertController(title: "Transaction Details", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        present(alert, animated: true)
    }

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
