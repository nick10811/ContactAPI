//
//  ViewController.swift
//  ContactAPI
//
//  Created by Nick Yang on 2021/2/5.
//

import UIKit
import Contacts

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func clickImportContacts(_ sender: Any) {
        fetchContactBook()
        // TODO: present next page with fetched contacts
    }
    
    private func fetchContactBook() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print("failed to request access", error)
                return
            }
            
            if granted {
                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                
                var contactArray: [ContactModel] = [ContactModel]()
                do {
                    try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        let firstName: String = contact.givenName
                        let lastName: String = contact.familyName
                        let email: String? = contact.emailAddresses.first?.value as String?
                        let mobile: String? = contact.phoneNumbers.first?.value.stringValue
                        
                        print("FN:\(firstName), LN:\(lastName), email:\(email), mobile:\(mobile)")
                        contactArray.append(ContactModel(firstName: firstName, lastName: lastName, email: email, mobile: mobile))
                        
                    })
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
                
            } else {
                print("access denied")
            }
        }
    }
}

