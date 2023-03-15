/*-----------------------------------
 
 - MyStream -
 
 Created by cubycode ©2017
 All Rights reserved
 
-----------------------------------*/

import UIKit
import Parse


class EditProfile: UIViewController,
UITextFieldDelegate,
UINavigationControllerDelegate,
UIImagePickerControllerDelegate
{

    /* Views */
    @IBOutlet weak var containerScrollView: UIScrollView!
    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var coverImg: UIImageView!
    @IBOutlet weak var usernameTxt: UITextField!
    @IBOutlet weak var fullnameTxt: UITextField!
    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var aboutMeTxt: UITextField!
    
    
    /* Variables */
    var isAvatar = Bool()
    
    
    
    
override func viewDidLoad() {
        super.viewDidLoad()

    // Layouts
    containerScrollView.contentSize = CGSize(width: containerScrollView.frame.size.width, height: 800)
    avatarImg.layer.cornerRadius = avatarImg.bounds.size.width/2
    
    // Call query
    getUserDetails()
}

 
    
// MARK: - GET USER'S DETAILS
func getUserDetails() {
    let currUser = PFUser.current()!
    
    // Get images
    getParseImage(currUser, imgView: avatarImg, columnName: USER_AVATAR)
    getParseImage(currUser, imgView: coverImg, columnName: USER_COVER_IMAGE)
    
    // Get details
    usernameTxt.text = "\(currUser[USER_USERNAME]!)"
    fullnameTxt.text = "\(currUser[USER_FULLNAME]!)"
    if currUser[USER_EMAIL] != nil { emailTxt.text = "\(currUser[USER_EMAIL]!)" }
    if currUser[USER_ABOUT_ME] != nil { aboutMeTxt.text = "\(currUser[USER_ABOUT_ME]!)" }
    
}

    
    
    
// MARK: - CHANGE AVATAR BUTTON
@IBAction func changeAvatarButt(_ sender: Any) {
    isAvatar = true
    
    let alert = UIAlertController(title: APP_NAME,
        message: "Select source",
        preferredStyle: .alert)
    
    let camera = UIAlertAction(title: "Take a Picture", style: .default, handler: { (action) -> Void in
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    })
    
    let library = UIAlertAction(title: "Pick from Library", style: .default, handler: { (action) -> Void in
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    })
    
    // Cancel button
    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })

    alert.addAction(camera)
    alert.addAction(library)
    alert.addAction(cancel)
    present(alert, animated: true, completion: nil)
}
    
    
   
// MARK: - CHANGE COVER BUTTON
@IBAction func changeCoverButt(_ sender: Any) {
    isAvatar = false
    
    let alert = UIAlertController(title: APP_NAME,
        message: "Select source",
        preferredStyle: .alert)
    
    let camera = UIAlertAction(title: "Take a Picture", style: .default, handler: { (action) -> Void in
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    })
    
    let library = UIAlertAction(title: "Pick from Library", style: .default, handler: { (action) -> Void in
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    })
    
    // Cancel button
    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
    
    alert.addAction(camera)
    alert.addAction(library)
    alert.addAction(cancel)
    present(alert, animated: true, completion: nil)
}
    

// ImagePicker delegate
func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
        if isAvatar {
            avatarImg.image = scaleImageToMaxWidth(image: image, newWidth: 300)
        } else {
            coverImg.image = scaleImageToMaxWidth(image: image, newWidth: 600)
        }
    }
    dismiss(animated: true, completion: nil)
}
    
    

    
    
// MARK: - UPDATE PROFILE BUTTON
@IBAction func updateProfileButt(_ sender: Any) {
    let currUser = PFUser.current()!
    
    if usernameTxt.text == "" || emailTxt.text == "" ||
        fullnameTxt.text == "" {
        simpleAlert("You must type a Username, a Full Name and an email address (needed only for password recovery")
        
    } else {
        showHUD("Please wait...")
        
        // Save data
        currUser[USER_USERNAME] = usernameTxt.text
        currUser[USER_EMAIL] = emailTxt.text
        currUser[USER_FULLNAME] = fullnameTxt.text
        currUser[USER_ABOUT_ME] = aboutMeTxt.text
        
        // Save Avatar image
        if avatarImg.image != nil {
            let imageData = UIImageJPEGRepresentation(avatarImg.image!, 1.0)
            let imageFile = PFFile(name:"avatar.jpg", data:imageData!)
            currUser[USER_AVATAR] = imageFile
        }
        
        
        // Save Cover image
        if coverImg.image != nil {
            let imageData = UIImageJPEGRepresentation(coverImg.image!, 1.0)
            let imageFile = PFFile(name:"cover.jpg", data:imageData!)
            currUser[USER_COVER_IMAGE] = imageFile
        }
        
        
        // Saving block
        currUser.saveInBackground(block: { (succ, error) in
            if error == nil {
                self.hideHUD()
                self.simpleAlert("Your profile has been updated!")
            
            // error
            } else {
                self.hideHUD()
                self.simpleAlert("\(error!.localizedDescription)")
        }})
    }
}
    
   
    
 
// MARK: - DISMISS BUTTON
@IBAction func dismissButt(_ sender: Any) {
    dismiss(animated: true, completion: nil)
}
    
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
