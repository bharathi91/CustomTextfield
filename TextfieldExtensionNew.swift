//
//  TextfieldExtensionNew.swift
//  SampleTestProject
//
//  Created by Bharathi's Macbook Air on 22/12/24.
//

import Foundation
import UIKit

extension UITextField: UITableViewDelegate, UITableViewDataSource {
    
    private static var tableViewKey: Void?
    private static var suggestionsKey: Void?
    
    private var suggestionsTableView: UITableView? {
        get {
            return objc_getAssociatedObject(self, &UITextField.tableViewKey) as? UITableView
        }
        set {
            objc_setAssociatedObject(self, &UITextField.tableViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var suggestions: [String]? {
        get {
            return objc_getAssociatedObject(self, &UITextField.suggestionsKey) as? [String]
        }
        set {
            objc_setAssociatedObject(self, &UITextField.suggestionsKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // Method to show email suggestions for domains and usernames
    func showEmailSuggestions(withDomains domains: [String], usernameSuggestions usernames: [String]) {
        if let text = self.text, let atIndex = text.firstIndex(of: "@") {
            let prefix = String(text[..<atIndex]) // Username prefix
            let domainText = String(text[atIndex...]) // Domain input after '@'

            let filteredDomains = domains.filter { $0.lowercased().hasPrefix(domainText.lowercased()) }
            let filteredUsernames = usernames.filter { $0.lowercased().hasPrefix(prefix.lowercased()) }

            // Combine both username and domain suggestions
            let combinedSuggestions = filteredUsernames.map { $0 + "@" } + filteredDomains.map { prefix + "@" + $0 }
            
            self.suggestions = combinedSuggestions
            self.showSuggestionsTableView()
        } else {
            self.hideSuggestionsTableView()
        }
    }
    
    // Method to show suggestions table view on top of the view controller
    private func showSuggestionsTableView() {
        guard suggestions != nil else { return }
        
        if suggestionsTableView == nil {
            let tableView = UITableView()
            tableView.delegate = self
            tableView.dataSource = self
            tableView.isHidden = false
            tableView.layer.borderColor = UIColor.gray.cgColor
            tableView.layer.borderWidth = 1
            tableView.layer.cornerRadius = 5
            tableView.backgroundColor = .white
            tableView.reloadData()
            
            // Get the active key window to add the table view on top
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                window.addSubview(tableView) // Add the table view to the key window
                suggestionsTableView = tableView
                
                // Calculate the position of the table view
                if let textFieldFrame = self.superview?.convert(self.frame, to: window) {
                    let tableHeight: CGFloat = 150
                    tableView.frame = CGRect(x: textFieldFrame.origin.x, y: textFieldFrame.maxY, width: textFieldFrame.width, height: tableHeight)
                }
            }
        } else {
            suggestionsTableView?.isHidden = false
            suggestionsTableView?.reloadData()
        }
    }
    
    // Method to hide suggestions table view
    private func hideSuggestionsTableView() {
        suggestionsTableView?.isHidden = true
    }
    
    // UITableView DataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestionCell") ?? UITableViewCell(style: .default, reuseIdentifier: "suggestionCell")
        cell.textLabel?.text = suggestions?[indexPath.row]
        return cell
    }
    
    // UITableView Delegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.text = suggestions?[indexPath.row] // Fill the selected suggestion
        hideSuggestionsTableView() // Hide the table after selection
    }
}

extension UITextField: UITextFieldDelegate {
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.delegate = self
    }
    
    // Trigger suggestions update when text is changed
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let updatedText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        
        if let updatedText = updatedText {
            // Provide domain and username suggestions based on user input
            showEmailSuggestions(withDomains: ["gmail.com", "yahoo.com", "outlook.com", "icloud.com"], usernameSuggestions: ["john.doe", "jane.smith", "alice.wonder", "bob.brown"])
        }
        
        return true
    }
}

extension UITextField: UIScrollViewDelegate {
    
    // When the scroll view is scrolled, update the table view position
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTableViewPosition()
    }
}
