import UIKit

class RegisterViewController: UIViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func registerTapped(_ sender: UIButton) {
        guard let name = nameTextField.text, !name.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            print("All fields are required")
            return
        }

        APIService.shared.registerUser(name: name, email: email, password: password) { user in
            DispatchQueue.main.async {
                if let user = user {
                    print("Registration successful: \(user)")
                    // Navigate to next screen or show success message
                } else {
                    print("Registration failed")
                }
            }
        }
    }
}
