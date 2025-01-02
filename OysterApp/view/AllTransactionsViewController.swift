import UIKit

class AllTransactionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var transactionsTableView: UITableView!
    var transactions: [TransactionDTO] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        transactionsTableView.delegate = self
        transactionsTableView.dataSource = self

        transactionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "TransactionCell")

        fetchSelectedCardAndTransactions()
    }

    func fetchSelectedCardAndTransactions() {
        guard let selectedCard = APIService.shared.getSelectedCard() else {
            print("No selected card found.")
            showError("No card selected. Please go back and select a card.")
            return
        }

        print("Selected card retrieved: \(selectedCard.cardNumber)")
        fetchTransactions(for: selectedCard)
    }

    func fetchTransactions(for card: CardDTO) {
        print("Fetching transactions for card: \(card.cardNumber)")

        APIService.shared.getPaginatedTransactions(cardNumber: card.cardNumber, page: 0, size: 100) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let paginatedResponse):
                    self?.transactions = paginatedResponse.content
                    print("Transactions fetched: \(paginatedResponse.content.count) transactions")
                    self?.transactionsTableView.reloadData()
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self?.showError("Unable to load transactions: \(errorMessage)")
                        } else {
                            self?.showError("Unable to load transactions: \(nsError)")
                        }
                    } else {
                        self?.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell", for: indexPath)
        let transaction = transactions[indexPath.row]

        let startAtString = transaction.startAt.replacingOccurrences(of: "T", with: " ").prefix(16)
        let startStationName = transaction.startStation.name
        let endStationName = transaction.endStation?.name ?? "N/A"
        let fare = transaction.fare ?? 0.0

        cell.textLabel?.text = "\(startAtString) \(startStationName) to \(endStationName)"
        cell.detailTextLabel?.text = "Fare: $\(fare)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transaction = transactions[indexPath.row]

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

    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
