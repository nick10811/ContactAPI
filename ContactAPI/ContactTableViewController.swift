//
//  ContactTableViewController.swift
//  ContactAPI
//
//  Created by Nick Yang on 2021/2/5.
//

import UIKit
import Contacts

class ContactTableViewController: UITableViewController {
    let cellReuseIdentifier: String = "ContactCell"
    var modelArray: [ContactModel] = [ContactModel]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // make navigation title touchable
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20)
        button.setTitle("Import Contact", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.addTarget(self, action: #selector(clickNavigationTitle(_:)), for: .touchUpInside)
        self.navigationItem.titleView = button
        
        // clean button
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(clickRefreshButton(_:)))
        
        // register UITableViewCell
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    @objc func clickNavigationTitle(_ sender: UIButton) {
        fetchContactBook()
    }
    
    @objc func clickRefreshButton(_ sender: UIBarButtonItem) {
        self.modelArray.removeAll()
        self.tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modelArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        let contact = self.modelArray[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = "\(contact.firstName) \(contact.lastName)"
        let mobile: String = contact.mobile ?? "No phone number."
        let email: String = contact.email ?? "No email."
        content.secondaryText = "\(mobile) | \(email)"
        if let data = contact.thumbnail {
            content.image = UIImage(data: data)
        } else {
            content.image = UIImage(systemName: "photo")
        }
        cell.contentConfiguration = content
        
        return cell
    }
}

extension ContactTableViewController {
    private func fetchContactBook() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { [weak self] (granted, error) in
            // HINT: In the background thread
            guard let self = self else { return }
            if let error = error {
                print("failed to request access", error)
                DispatchQueue.main.async {
                    self.showAlert()
                }
                return
            }
            
            if granted {
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactThumbnailImageDataKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                
                var contactArray: [ContactModel] = [ContactModel]()
                do {
                    try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        let firstName: String = contact.givenName
                        let lastName: String = contact.familyName
                        let email: String? = contact.emailAddresses.first?.value as String?
                        let mobile: String? = contact.phoneNumbers.first?.value.stringValue
                        let image: Data? = contact.thumbnailImageData
                        
                        print("FN:\(firstName), LN:\(lastName), email:\(email), mobile:\(mobile), thumbnail size:\(image?.count)")
                        contactArray.append(ContactModel(firstName: firstName, lastName: lastName, email: email, mobile: mobile, thumbnail: image))
                        
                    })
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
                
                // store contacts to TableVC & reload TableVC
                DispatchQueue.main.async {
                    self.modelArray.append(contentsOf: contactArray)
                    self.tableView.reloadData()
                }
                
            } else {
                print("access denied")
                DispatchQueue.main.async {
                    self.showAlert()
                }
            }
        }
    }
    
    func showAlert() {
        let alertController = UIAlertController(title: "", message: "Please allow ContactAPI access to your phonebook to seamlessly import your contacts.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action) in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        let settingsAction = UIAlertAction(title: "Settings", style: .cancel) { (action) in
            // open iPhone's settings
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:]) { (success) in
                    print("Settings opened: \(success)") // prints true
                }
            }
        }
        
        alertController.addAction(okAction)
        alertController.addAction(settingsAction)
        self.present(alertController, animated: true, completion: nil)
    }

}
