import UIKit

class RegisterViewController: UIViewController {
    @IBOutlet weak var formStackView: UIStackView!
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!

    enum FormMode {
        case login
        case register
    }
    
    var currentFormMode: FormMode = .login

    override func viewDidLoad() {
        super.viewDidLoad()
        configureForm()
    }

    private func configureForm() {
        firstNameTextField.isHidden = true
        lastNameTextField.isHidden = true
        emailTextField.isHidden = true
        passwordTextField.isHidden = true
        submitButton.isHidden = true
    }

    @IBAction func signInTapped(_ sender: UIButton) {
        currentFormMode = .login
        
        firstNameTextField.isHidden = true
        lastNameTextField.isHidden = true
        emailTextField.isHidden = false
        passwordTextField.isHidden = false
        submitButton.isHidden = false
        submitButton.setTitle("Login", for: .normal)
    }
    
    @IBAction func registerTapped(_ sender: UIButton) {
        currentFormMode = .register
        
        firstNameTextField.isHidden = false
        lastNameTextField.isHidden = false
        emailTextField.isHidden = false
        passwordTextField.isHidden = false
        submitButton.isHidden = false
        submitButton.setTitle("Register", for: .normal)
    }
    
    @IBAction func submitTapped(_ sender: UIButton) {
        switch currentFormMode {
        case .login:
            handleLogin()
        case .register:
            handleRegistration()
        }
    }
    
    private func handleLogin() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Email and password are required")
            return
        }

        APIService.shared.loginUser(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.navigateToDashboard()
                case .failure(let error):
                    self?.showAlert(message: "Invalid credentials")
                }
            }
        }
    }
    
    private func handleRegistration() {
        guard let firstName = firstNameTextField.text, !firstName.isEmpty,
              let lastName = lastNameTextField.text, !lastName.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "All fields are required")
            return
        }

        APIService.shared.registerUser(firstName: firstName, lastName: lastName, email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showAlert(message: "Registration successful!")
                case .failure(let error):
                    if let nsError = error as? NSError {
                        if let errorMessage = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                            self?.showAlert(message: "Registration failed: \(errorMessage)")
                        } else {
                            self?.showAlert(message: "Registartion failed: \(nsError)")
                        }
                    } else {
                        self?.showAlert(message: "Unknown error: \(error)")
                    }
                }
            }
        }
    }
    
    private func navigateToDashboard() {
        
        let sceneDelegate = UIApplication.shared.connectedScenes
                    .first?.delegate as? SceneDelegate
                sceneDelegate?.showDashboard()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
