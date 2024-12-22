import UIKit

class CardManagerViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var cardsTableView: UITableView! // Table view to display cards
    @IBOutlet weak var selectedCardLabel: UILabel!  // Label to show the selected card
    @IBOutlet weak var tapInButton: UIButton!       // Button to tap in at a station
    @IBOutlet weak var tapOutButton: UIButton!      // Button to tap out at a station

    // MARK: - Variables
    var cards: [CardDTO] = []  // List of cards the user owns
    var selectedCard: CardDTO?  // The currently selected card

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup table view
        cardsTableView.delegate = self
        cardsTableView.dataSource = self
        
        // Load the list of cards and update the UI
        loadCards()
        
        // Load the selected card if it exists
        selectedCard = APIService.shared.getSelectedCard()
        updateUI()
    }

    // MARK: - Load Cards
    func loadCards() {
        APIService.shared.getCards { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cards):
                    self?.cards = cards
                    self?.cardsTableView.reloadData()
                case .failure(let error):
                    self?.showAlert(message: "Error loading cards: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Select Card
    func selectCard(card: CardDTO) {
        selectedCard = card
        APIService.shared.selectCard(card)  // Store the selected card in UserDefaults
        updateUI()
    }

    // MARK: - Update UI
    func updateUI() {
        if let selectedCard = selectedCard {
            selectedCardLabel.text = "Selected Card: \(selectedCard.cardNumber)"
        } else {
            selectedCardLabel.text = "No Card Selected"
        }
        
        // Enable/disable tap buttons based on selected card
        tapInButton.isEnabled = selectedCard != nil
        tapOutButton.isEnabled = selectedCard != nil
    }

    // MARK: - Handle Tap In
    @IBAction func tapInTapped(_ sender: UIButton) {
        guard let selectedCard = selectedCard else {
            showAlert(message: "Please select a card first.")
            return
        }
        
        let station = Station(id: "id", name: "Start Station", zone: "Station Location") // Example station data
        APIService.shared.tapIn(cardNumber: selectedCard.cardNumber, station: station) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transaction):
                    self?.showAlert(message: "Tap In Successful! Transaction ID: \(transaction.id)")
                case .failure(let error):
                    self?.showAlert(message: "Tap In Failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Handle Tap Out
    @IBAction func tapOutTapped(_ sender: UIButton) {
        guard let selectedCard = selectedCard else {
            showAlert(message: "Please select a card first.")
            return
        }
        
        let station = Station(name: "End Station", location: "Station Location") // Example station data
        APIService.shared.tapOut(cardNumber: selectedCard.cardNumber, station: station) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transaction):
                    self?.showAlert(message: "Tap Out Successful! Transaction ID: \(transaction.id)")
                case .failure(let error):
                    self?.showAlert(message: "Tap Out Failed: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Show Alert
    func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension CardManagerViewController: UITableViewDelegate, UITableViewDataSource {
    
    // Return the number of rows in the table view (i.e., the number of cards)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }
    
    // Return the cell for each card
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell", for: indexPath)
        let card = cards[indexPath.row]
        
        cell.textLabel?.text = "Card Number: \(card.cardNumber)"
        if card == selectedCard {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    // Handle card selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCard = cards[indexPath.row]
        selectCard(card: selectedCard)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
