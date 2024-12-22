//
//  TransactionsViewController.swift
//  OysterApp
//
//  Created by Ewa on 22/12/2024.
//

import UIKit

class AllTransactionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var transactionsTableView: UITableView!
    var transactions: [TransactionDTO] = []
    var card: CardDTO?

    override func viewDidLoad() {
        super.viewDidLoad()
        transactionsTableView.delegate = self
        transactionsTableView.dataSource = self

        if let card = card {
            fetchTransactions(for: card)
        }
    }

    // MARK: - Fetch All Transactions
    func fetchTransactions(for card: CardDTO) {
        APIService.shared.getPaginatedTransactions(cardNumber: card.cardNumber, page: 0, size: 100) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let paginatedResponse):
                    self?.transactions = paginatedResponse.content
                    self?.transactionsTableView.reloadData()
                case .failure(let error):
                    self?.showError("Failed to load transactions: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - UITableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionCell2", for: indexPath)
        let transaction = transactions[indexPath.row]

        let startAtString = transaction.startAt
        let formattedStartAt = startAtString.replacingOccurrences(of: "T", with: " ").prefix(16)
        let startStationName = transaction.startStation.name
        let endStationName = transaction.endStation?.name ?? "N/A"

        cell.textLabel?.text = "\(formattedStartAt) \(startStationName) to \(endStationName)"
        cell.detailTextLabel?.text = "Amount: \(transaction.fare ?? 0.0)"
        return cell
    }

    // MARK: - UITableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transaction = transactions[indexPath.row]
        let transactionDetailsVC = TransactionDetailsViewController()
        transactionDetailsVC.transactionId = transaction.id
        navigationController?.pushViewController(transactionDetailsVC, animated: true)
    }

    // MARK: - Show Error
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
