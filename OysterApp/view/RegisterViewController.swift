import UIKit

class RegisterViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var formStackView: UIStackView!         // Holds form fields
    @IBOutlet weak var firstNameTextField: UITextField!    // Registration Field
    @IBOutlet weak var lastNameTextField: UITextField!     // Registration Field
    @IBOutlet weak var emailTextField: UITextField!       // Common Field
    @IBOutlet weak var passwordTextField: UITextField!    // Common Field
    @IBOutlet weak var submitButton: UIButton!            // Login/Register Button
    @IBOutlet weak var signInButton: UIButton!            // Button to show login form
    @IBOutlet weak var registerButton: UIButton!          // Button to show register form

    // MARK: - Variables
    enum FormMode {
        case login
        case register
    }
    
    var currentFormMode: FormMode = .login
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureForm() // Initial setup
    }
    
    // MARK: - UI Setup
    private func configureForm() {
        // Hide all form fields and the submit button initially
        firstNameTextField.isHidden = true
        lastNameTextField.isHidden = true
        emailTextField.isHidden = true
        passwordTextField.isHidden = true
        submitButton.isHidden = true
    }
    
    // MARK: - Actions
    @IBAction func signInTapped(_ sender: UIButton) {
        // Switch to Login Form
        currentFormMode = .login
        
        // Show only fields relevant to login
        firstNameTextField.isHidden = true
        lastNameTextField.isHidden = true
        emailTextField.isHidden = false
        passwordTextField.isHidden = false
        submitButton.isHidden = false
        submitButton.setTitle("Login", for: .normal)
    }
    
    @IBAction func registerTapped(_ sender: UIButton) {
        // Switch to Registration Form
        currentFormMode = .register
        
        // Show all fields required for registration
        firstNameTextField.isHidden = false
        lastNameTextField.isHidden = false
        emailTextField.isHidden = false
        passwordTextField.isHidden = false
        submitButton.isHidden = false
        submitButton.setTitle("Register", for: .normal)
    }
    
    @IBAction func submitTapped(_ sender: UIButton) {
        // Handle different forms based on the current mode
        switch currentFormMode {
        case .login:
            handleLogin()
        case .register:
            handleRegistration()
        }
    }
    
    // MARK: - Helper Methods
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
                    self?.navigateToAccountManager()
                case .failure(let error):
                    self?.showAlert(message: "Login failed: \(error.localizedDescription)")
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
                    self?.showAlert(message: "Registration failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func navigateToAccountManager() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let accountManagerVC = storyboard.instantiateViewController(withIdentifier: "AccountManagerViewController") as? AccountManagerViewController {
            accountManagerVC.modalPresentationStyle = .fullScreen
            self.present(accountManagerVC, animated: true, completion: nil)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
