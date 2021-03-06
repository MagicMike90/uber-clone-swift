//
//  LeftSidePanelVCViewController.swift
//  uber-clone
//
//  Created by Michael Luo on 25/4/19.
//  Copyright © 2019 Michael Luo. All rights reserved.
//

import UIKit
import Firebase

class SidePanelViewController: UIViewController {

    let appDelegate = AppDelegate.getAppDelegate()

    var currentUserId: String?

    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userAccountType: UILabel!
    @IBOutlet weak var userImageView: RoundImageView!
    @IBOutlet weak var authBtn: UIButton!
    @IBOutlet weak var pickupModeSwitch: UISwitch!
    @IBOutlet weak var pickupModeSection: UIView!
    @IBOutlet weak var pickupModeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        currentUserId = Auth.auth().currentUser?.uid
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        pickupModeSwitch.isOn = false
        pickupModeSection.isHidden = true

        self.observePassengersAndDrivers()

        if Auth.auth().currentUser == nil {
            reset()
        } else {
            userEmailLabel.text = Auth.auth().currentUser?.email
            userAccountType.text = ""
            authBtn.setTitle("Logout", for: .normal)
        }
    }

    func observePassengersAndDrivers() {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountType.text = "PASSENGER"
                    }
                }
            }
        }

        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid {
                        self.userAccountType.text = "DRIVER"
                        self.pickupModeSection.isHidden = false

                        guard let switchStatus = snap.childSnapshot(forPath: ACCOUNT_PICKUP_MODE_ENABLED).value as? Bool else {
                            // Display a UIAlertController telling the user to check for an updated app..
                            return
                        }
//                        let switchStatus = snap.childSnapshot(forPath: ACCOUNT_PICKUP_MODE_ENABLED).value as! Bool
                        self.pickupModeSwitch.isOn = switchStatus
                    }
                }
            }
        }
    }

    func reset() {
        userEmailLabel.text = ""
        userAccountType.text = ""
        authBtn.setTitle("Sign Up / Login", for: .normal)
        pickupModeSection.isHidden = true
    }

    @IBAction func togglePickupMode(_ sender: Any) {

        if pickupModeSwitch == nil {
            return
        }

        if pickupModeSwitch.isOn {
            pickupModeLabel.text = "Disable Pick-up Mode"

        } else {
            pickupModeLabel.text = "Enable Pick-up Mode"
        }

        appDelegate.MenuContainerVC.toggleLeftPanel()
        DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled": pickupModeSwitch.isOn])

    }

    @IBAction func SignUpBtnPressed(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC =  storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginViewController

            present(loginVC!, animated: true, completion: nil)
        } else {
            do {
                try Auth.auth().signOut()
                reset()
            } catch {
                print (error)
            }
        }

    }
}
