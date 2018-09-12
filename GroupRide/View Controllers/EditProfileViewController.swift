//
//  EditProfileViewController.swift
//  GroupRide
//
//  Created by Krysta Deluca on 6/11/18.
//  Copyright © 2018 Krysta Deluca. All rights reserved.
//

import Photos
import PhotosUI
import UIKit
import Firebase

class EditProfileViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var editTableView: UITableView!
    @IBOutlet weak var profilePictureView: UIImageView!
    
    var imagePickedBlock: ((UIImage) -> Void)?
    var activeTextView: UITextView?
    let uid = UserDefaults.standard.string(forKey: "uid")
    let notificationName = Notification.Name("myNotificationName")
    
    let titles = ["\(NSLocalizedString("name", comment: ""))", "\(NSLocalizedString("username", comment: ""))", "\(NSLocalizedString("ride", comment: ""))", "\(NSLocalizedString("bike", comment: ""))", "\(NSLocalizedString("description", comment: ""))"]
    var descriptions: [String]!
    var textLimitLength = 20
    
    enum AttachmentType: String{
        case camera, photoLibrary
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkProfile()
        
        editTableView.tableFooterView = UIView()
        editTableView.delegate = self
        editTableView.dataSource = self
        editTableView.alwaysBounceVertical = false
        
        //Looks for single or multiple taps
         let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        //Trim profile picture
        profilePictureView.layer.cornerRadius = profilePictureView.frame.height / 2.0
        profilePictureView.clipsToBounds = true
        setProfilePicture()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        //Move view up when keyboard will show
        let userInfo = notification.userInfo ?? [:]
        let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let height = keyboardFrame.height + 20
        editTableView.keyboardRaised(height: height)

    }
    
    @objc func keyboardHidden(notification: NSNotification) {
        editTableView.keyboardClosed()
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Picture Upload", message: "Where would you like to upload your photo from?", preferredStyle: .actionSheet)
        
        let cameraButton = UIAlertAction(title: "Camera", style: .default, handler: { (action) -> Void in
            self.authorisationStatus(attachmentTypeEnum: .camera, sender: sender)
        })
        
        let cameraRollButton = UIAlertAction(title: "Camera Roll", style: .default, handler: { (action) -> Void in
            self.authorisationStatus(attachmentTypeEnum: .photoLibrary, sender: sender)
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
        })
        
        
        alertController.addAction(cameraRollButton)
        alertController.addAction(cameraButton)
        alertController.addAction(cancelButton)
        
        self.navigationController!.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(_ sender: UIBarButtonItem) {
        //If there are any empty fields, don't exit view
        view.endEditing(true)
        
        if !checkEmptyField() {
            saveProfile()
        } else {
            return
        }
        
        let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email")]
        Analytics.logEvent("userSavedProfile", parameters: parameters)
            
        performSegue(withIdentifier: "returnToProfile", sender: self)
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email")]
        Analytics.logEvent("userCancelledEdit", parameters: parameters)
        
        performSegue(withIdentifier: "returnToProfile", sender: self)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func setProfilePicture() {
        if let user = Auth.auth().currentUser {
            let storageRef = Storage.storage().reference()
            let filePath = user.uid
            let reference = storageRef.child(filePath)
            profilePictureView.sd_setImage(with: reference, placeholderImage: #imageLiteral(resourceName: "defaultProfilePicture"))
        }
    }
    
    //Check status to access camera
    func authorisationStatus(attachmentTypeEnum: AttachmentType, sender: UIButton){
        
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            if attachmentTypeEnum == AttachmentType.camera{
                openCamera()
            }
            if attachmentTypeEnum == AttachmentType.photoLibrary{
                photoLibrary()
            }
        case .denied:
            print("permission denied")
            self.addAlertForSettings(sender: sender)
        case .notDetermined:
            print("Permission Not Determined")
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == PHAuthorizationStatus.authorized{
                    // photo library access given
                    print("access given")
                    if attachmentTypeEnum == AttachmentType.camera{
                        self.openCamera()
                    }
                    if attachmentTypeEnum == AttachmentType.photoLibrary{
                        self.photoLibrary()
                    }
                }else{
                    print("restriced manually")
                    self.addAlertForSettings(sender: sender)
                }
            })
        case .restricted:
            print("permission restricted")
            self.addAlertForSettings(sender: sender)
        default:
            break
        }
    }
    
    func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .camera
            self.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    func photoLibrary(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            self.present(myPickerController, animated: true, completion: nil)
        }
    }
    
    //Upload image to Firebase Storage
    func uploadImage(image: UIImage) {
        var data = NSData()
        data = UIImageJPEGRepresentation(image, 0.8)! as NSData
        
        //Set upload path
        let filePath = "\(uid!)"
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        let storageRef = Storage.storage().reference()
        storageRef.child(filePath).putData(data as Data, metadata: metaData){(metaData,error) in
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                //Get downloadURL
                storageRef.downloadURL { (url, error) in
                    guard let downloadURL = url else { return }
                    print(downloadURL)
                }
            }
        }
    }
    
    //Alert user to change camera permissions
    func addAlertForSettings(sender: UIButton) {
        let alertController = UIAlertController(title: "\(NSLocalizedString("access", comment: ""))", message: "\(NSLocalizedString("enableCameraAccess", comment: ""))", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "\(NSLocalizedString("cancel", comment: ""))", style: .cancel) { (alert) in
            print("User tapped Cancel")
        }
        
        let settingsAction = UIAlertAction(title: "\(NSLocalizedString("settings", comment: ""))", style: .default, handler: { (alert) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings)
            }
        })
        
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        
        alertController.popoverPresentationController?.sourceRect = sender.frame
        alertController.popoverPresentationController?.sourceView = view
        
        present(alertController, animated: true, completion: nil)
    }
    
    //Check if there is a saved profile
    func checkProfile() {
        descriptions = []
        
        if let name = UserDefaults.standard.object(forKey: "Name") as? String {
            descriptions.append(name)
        } else {
            descriptions.append("\(NSLocalizedString("noNameSaved", comment: ""))")
        }
        
        if let username = UserDefaults.standard.string(forKey: "Username") {
            descriptions.append(username)
        } else {
            descriptions.append("\(NSLocalizedString("noUsernameSaved", comment: ""))")
        }
        
        if let bike = UserDefaults.standard.object(forKey: "Ride") as? String {
            descriptions.append(bike)
        } else {
            descriptions.append("\(NSLocalizedString("noRideSaved", comment: ""))")
        }
        
        if let ride = UserDefaults.standard.object(forKey: "Bike") as? String {
            descriptions.append(ride)
        } else {
            descriptions.append("\(NSLocalizedString("noBikeSaved", comment: ""))")
        }
        
        if let description = UserDefaults.standard.object(forKey: "Description") as? String {
            descriptions.append(description)
        } else {
            descriptions.append("\(NSLocalizedString("noDescriptionSaved", comment: ""))")
        }
    }
    
    //Check if necessary fields are empty
    func checkEmptyField() -> Bool {
        var emptyFields = 0
        var indexPath = IndexPath(row: 0, section: 0)
        let nameCell = editTableView.cellForRow(at: indexPath) as! EditProfileTableViewCell
        nameCell.errorLabel.alpha = 0
        
        if descriptions[0] == "\(NSLocalizedString("noNameSaved", comment: ""))" || descriptions[0] == "" {
            nameCell.errorLabel.text = "\(NSLocalizedString("emptyName", comment: ""))"
            UIView.animate(withDuration: 1) {
                nameCell.errorLabel.alpha = 1
            }
            emptyFields += 1
        }
        
        indexPath = IndexPath(row: 1, section: 0)
        let usernameCell = editTableView.cellForRow(at: indexPath) as! EditProfileTableViewCell
        usernameCell.errorLabel.alpha = 0
        
        if descriptions[1] == "\(NSLocalizedString("noUsernameSaved", comment: ""))" || descriptions[1] == "" {
            usernameCell.errorLabel.text = "\(NSLocalizedString("emptyUsername", comment: ""))"
            UIView.animate(withDuration: 1) {
                usernameCell.errorLabel.alpha = 1
            }
            emptyFields += 1
        }
        
        return emptyFields > 0
    }
    
    //Save Profile
    func saveProfile() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(descriptions[0], forKey: "Name")
        saveUsername()
        userDefaults.set(descriptions[2], forKey: "Ride")
        userDefaults.set(descriptions[3], forKey: "Bike")
        userDefaults.set(descriptions[4], forKey: "Description")
        userDefaults.synchronize()
    }
    
    //Save username to profile
    func saveUsername() {
        if UserDefaults.standard.string(forKey: "Username") != descriptions[1] {
            if let user = Auth.auth().currentUser {
                //Create request to change username in firebase profile
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = descriptions[1]
                
                changeRequest.commitChanges(){ (error) in
                    if let error = error {
                        print(error.localizedDescription)
                        return
                    }
                }
                let parameters = ["Email" : UserDefaults.standard.object(forKey: "Email"), "New Username" : descriptions[1]]
                Analytics.logEvent("userUpdatedUsername", parameters: parameters)
            }
        }
        UserDefaults.standard.set(descriptions[1], forKey: "Username")
    }
    
    //Set up table view
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EditProfileCell", for: indexPath) as! EditProfileTableViewCell
        let title = titles[indexPath.row]
        let description = descriptions[indexPath.row]
        
        cell.titleLabel.text = title
        cell.descriptionTextView.text = description
        
        cell.descriptionTextView.tag = indexPath.row
        cell.descriptionTextView.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension;
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0;
    }
}

extension UITableView {
    func keyboardRaised(height: CGFloat){
        self.contentInset.bottom = height
        self.scrollIndicatorInsets.bottom = height
    }
    
    func keyboardClosed(){
        self.contentInset.bottom = 0
        self.scrollIndicatorInsets.bottom = 0
        self.scrollRectToVisible(CGRect.zero, animated: true)
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        // To handle image
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.profilePictureView.image = pickedImage
            uploadImage(image: pickedImage)
            NotificationCenter.default.post(name: self.notificationName, object: nil, userInfo: ["image": pickedImage])
        } else{
            print("Something went wrong in  image")
        }
        
        // To handle video
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL{
            //Pop alert
            let alertController = UIAlertController(title: "\(NSLocalizedString("videoChosen", comment: ""))", message: "\(NSLocalizedString("cannotChooseVideo", comment: ""))", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
        else{
            print("Something went wrong in  video")
        }
        self.dismiss(animated: true, completion: nil)
    }
}

extension EditProfileViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if var value = textView.text {
            value = value.trimmingCharacters(in: .whitespacesAndNewlines)
            descriptions[textView.tag] = value
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        activeTextView = textView
        
        DispatchQueue.main.async {
            textView.selectAll(nil)
        }
    }
    
    //Resize text view
    func textViewDidChange(_ textView: UITextView) {
        let size = textView.bounds.size
        let newSize = textView.sizeThatFits(CGSize(width: size.width,
                                                   height: CGFloat.greatestFiniteMagnitude))
        
        // Resize the cell only when cell's size is changed
        if size.height != newSize.height {
            UIView.setAnimationsEnabled(false)
            editTableView.beginUpdates()
            editTableView.endUpdates()
            UIView.setAnimationsEnabled(true)
            
            let thisIndexPath = IndexPath(row: textView.tag, section: 0)
            editTableView.scrollToRow(at: thisIndexPath,
                                      at: .bottom,
                                              animated: false)
        }
    }
}
