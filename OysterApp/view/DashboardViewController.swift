import UIKit

class DashboardViewController: UIViewController {
    
    @IBOutlet weak var cardPicker: UIPickerView!
    @IBOutlet weak var stationPicker: UIPickerView!
    @IBOutlet weak var tapInButton: UIButton!
    @IBOutlet weak var tapOutButton: UIButton!
    @IBOutlet weak var manageButton: UIButton!
    @IBOutlet weak var cardInfoLabel: UILabel!
    
    var cards: [CardDTO] = []
    var stations: [Station] = []

    var selectedCard: CardDTO?
    var selectedStation: Station?
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
        cardPicker.delegate = self
        cardPicker.dataSource = self
        stationPicker.delegate = self
        stationPicker.dataSource = self

        fetchCards()
        fetchStations()
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchCards()
    }
    
    func fetchCards() {
        APIService.shared.getCards { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cards):
                    let previousSelectedCardId = self?.selectedCard?.id
                    self?.cards = cards.filter { $0.isActive ?? true }
                    self?.cardPicker.reloadAllComponents()
                 
                    if let previousSelectedCardId = previousSelectedCardId,
                       let activePreviousSelectedCard = self?.cards.first(where: { $0.id == previousSelectedCardId }) {
                        self?.selectedCard = activePreviousSelectedCard
                    } else {
                        self?.selectedCard = self?.cards.first
                    }

                    self?.updateCardInfoLabel()
                    
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self?.showError("Failed to load cards: \(errorMessage)")
                        } else {
                            self?.showError("Failed to load cards: \(nsError)")
                        }
                    } else {
                        self?.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }

    
    private func fetchStations() {
        APIService.shared.getStations { [weak self] result in
            switch result {
            case .success(let stations):
                DispatchQueue.main.async {
                    self?.stations = stations
                    self?.stationPicker.reloadAllComponents()
                    self?.selectedStation = stations.first
                }
            case .failure(let error):
                if let nsError = error as? NSError {
                    if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                        self?.showError("Unable to fetch stations: \(errorMessage)")
                    } else {
                        self?.showError("Unable to fetch stations: \(nsError)")
                    }
                } else {
                    self?.showError("Unknown error: \(error)")
                }
            }
        }
    }
    
    @IBAction func tapInButtonTapped() {
        guard let selectedCard = selectedCard, let selectedStation = selectedStation else {
            showError("No card selected.")
            return
        }
        
        APIService.shared.tapIn(cardNumber: selectedCard.cardNumber, station: selectedStation) {
            [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transaction):
                    print("Successfully tapped in: \(transaction)")
                    self!.showTapInSuccessAlert(station: selectedStation)
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self?.showError("Error tapping in: \(errorMessage)")
                        } else {
                            self?.showError("Error tapping in: \(nsError)")
                        }
                    } else {
                        self?.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }
    
    @IBAction func tapOutButtonTapped() {
        guard let selectedCard = selectedCard, let selectedStation = selectedStation else {
            showError("No card selected.")
            return
        }
        
        APIService.shared.tapOut(cardNumber: selectedCard.cardNumber, station: selectedStation) {
            [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let transaction):
                    print("Successfully tapped out: \(transaction)")
                    self!.showTapOutSuccessAlert(station: selectedStation, fare: transaction.fare!)
                    self!.fetchCards()
                
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self?.showError("Error tapping out: \(errorMessage)")
                        } else {
                            self?.showError("Error tapping out: \(nsError)")
                        }
                    } else {
                        self?.showError("Unknown error: \(error)")
                    }
                }
            }
        }
    }
    
    private func updateCardInfoLabel() {
        if let selectedCard = selectedCard {
            cardInfoLabel.text = "Card: \(selectedCard.cardNumber) - Balance: \(selectedCard.balance)"
        } else {
            cardInfoLabel.text = "No card selected"
        }
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    private func showTapInSuccessAlert(station: Station) {
            let alert = UIAlertController(title: "Tap In Successful", message: "You have successfully tapped in at \(station.name).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        
    private func showTapOutSuccessAlert(station: Station, fare: Double) {
            let alert = UIAlertController(title: "Tap Out Successful", message: "You have successfully tapped out at \(station.name). The fare is $\(fare).", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
    }
    
    @IBAction func logoutTapped(_ sender: UIButton) {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        
        if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
            loginVC.modalPresentationStyle = .fullScreen
            sceneDelegate.window?.rootViewController?.present(loginVC, animated: true, completion: nil)
        }
    }
}

extension DashboardViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == cardPicker {
            return cards.count
        } else if pickerView == stationPicker {
            return stations.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == cardPicker {
            guard row < cards.count else { return nil }
            return "\(cards[row].cardNumber)"
        } else if pickerView == stationPicker {
            guard row < stations.count else { return nil }
            return stations[row].name
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == cardPicker {
            guard row < cards.count else { return }
            selectedCard = cards[row]
            APIService.shared.selectCard(selectedCard!)
            updateCardInfoLabel()
            print("Selected card: \(selectedCard?.cardNumber ?? 0)")
        } else if pickerView == stationPicker {
            guard row < stations.count else { return }
            selectedStation = stations[row]
            print("Selected station: \(selectedStation?.name ?? "None")")
        }
    }
}
