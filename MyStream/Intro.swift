/*-----------------------------------
 
 - App -
 
 Created by cubycode ©2017
 All Rights reserved
 
 -----------------------------------*/

import UIKit
import Parse
import ParseFacebookUtilsV4
import AuthenticationServices


class Intro: UIViewController {
    
    /* Views */
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var appNameLabel: UILabel!
    
    
  
    
override func viewWillAppear(_ animated: Bool) {
    if PFUser.current() != nil {
        dismiss(animated: true, completion: nil)
    }
}
    
override func viewDidLoad() {
        super.viewDidLoad()

    // Initial Layout
    logoImage.layer.cornerRadius = 20
    appNameLabel.text = APP_NAME

}

    
    
   
    
// MARK: - GET STARTED BUTTON
@IBAction func getStartedButt(_ sender: Any) {
//    let aVC = storyboard?.instantiateViewController(withIdentifier: "SignUp") as! SignUp
//    present(aVC, animated: true, completion: nil)
    
    let viewController = self.storyboard?.instantiateViewController(withIdentifier: "SignUp") as! SignUp

    let navigationController: UINavigationController = UINavigationController(rootViewController: viewController)

    navigationController.modalPresentationStyle = .fullScreen

    self.present(navigationController, animated: true, completion: nil)
}
    
    

// MARK: - LOGIN BUTTON
@IBAction func loginButt(_ sender: Any) {
//    let aVC = storyboard?.instantiateViewController(withIdentifier: "Login") as! Login
//    present(aVC, animated: true, completion: nil)
    
     let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! Login

       let navigationController: UINavigationController = UINavigationController(rootViewController: viewController)

       navigationController.modalPresentationStyle = .fullScreen

       self.present(navigationController, animated: true, completion: nil)
}

    
    
    
   
// MARK: - FACEBOOK LOGIN BUTTON
@IBAction func facebookButt(_ sender: Any) {
        // Set permissions required from the facebook user account
        let permissions = ["public_profile", "email"];
        showHUD("Please wait...")
        
        // Login PFUser using Facebook
        PFFacebookUtils.logInInBackground(withReadPermissions: permissions) { (user, error) in
            if user == nil {
                self.simpleAlert("Facebook login cancelled")
                self.hideHUD()
                
            } else if (user!.isNew) {
                print("NEW USER signed up and logged in through Facebook!");
                self.getFBUserData()
                
            } else {
                print("User logged in through Facebook!");
                
                self.dismiss(animated: false, completion: nil)
                self.hideHUD()
        }}
}
    
    
          // MARK: - Apple SIGNIN BUTTON
           @IBAction func signinAppleButt(_ sender: Any) {
                       // Set permissions required from the facebook user account
                       
                       showHUD("Logging in...")
                       
                       if #available(iOS 13.0, *) {
               //            let appleIDProvider = ASAuthorizationAppleIDProvider()
               //            let request = appleIDProvider.createRequest()
               //
               //                          request.requestedScopes = [.fullName, .email]
               //
               //                          let authorizationController = ASAuthorizationController(authorizationRequests: [request])
               //
               //                          authorizationController.delegate = self
               //
               //            authorizationController.presentationContextProvider = self as! ASAuthorizationControllerPresentationContextProviding
               //
               //                          authorizationController.performRequests()
                           
                           let appleIDProvider = ASAuthorizationAppleIDProvider()
                           let request = appleIDProvider.createRequest()
                           request.requestedScopes = [.fullName, .email]
                           let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                           authorizationController.delegate = self
                           authorizationController.performRequests()
                       } else {
                           // Fallback on earlier versions
                       }

               //               let request = appleIDProvider.createRequest()
               //
               //               request.requestedScopes = [.fullName, .email]
               //
               //               let authorizationController = ASAuthorizationController(authorizationRequests: [request])
               //
               //               authorizationController.delegate = self
               //
               //               authorizationController.presentationContextProvider = self
               //
               //               authorizationController.performRequests()
                      
               
               }

    
    
func getFBUserData() {
    let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, email, picture.type(large)"])
        let connection = FBSDKGraphRequestConnection()
        connection.add(graphRequest) { (connection, result, error) in
            if error == nil {
                let userData:[String:AnyObject] = result as! [String : AnyObject]
                
                // Get data
                let facebookID = userData["id"] as! String
                let name = userData["name"] as! String
                let email = userData["email"] as! String
                
                let currUser = PFUser.current()!
                
                // Get avatar
                let pictureURL = URL(string: "https://graph.facebook.com/\(facebookID)/picture?type=large&return_ssl_resources=1")
                let urlRequest = URLRequest(url: pictureURL!)
                let session = URLSession.shared
                let dataTask = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                    if error == nil && data != nil {
                        let image = UIImage(data: data!)
                        let imageData = UIImageJPEGRepresentation(image!, 1.0)
                        let imageFile = PFFile(name:"avatar.jpg", data:imageData!)
                        currUser[USER_AVATAR] = imageFile
                        currUser.saveInBackground()
                    }})
                dataTask.resume()
             
                    
                // Update user data
                let nameArr = name.components(separatedBy: " ")
                var username = String()
                for word in nameArr {
                    username.append(word.lowercased())
                }
                currUser.username = username
                if email != "" { currUser.email = email
                } else { currUser.email = "noemail@facebook.com" }
                
                // Save Other Data
                currUser[USER_FULLNAME] = name
                currUser[USER_IS_REPORTED] = false
                let hasBlocked = [String]()
                currUser[USER_HAS_BLOCKED] = hasBlocked

                currUser.saveInBackground(block: { (succ, error) in
                    if error == nil {
                        mustRefresh = true
                        self.dismiss(animated: false, completion: nil)
                        self.hideHUD()
                }})
                
            // error on graph request
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
            }}
        connection.start()
}
    
    
    

    
    
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension Intro: ASAuthorizationControllerDelegate {

     // ASAuthorizationControllerDelegate function for authorization failed

    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        hideHUD()
        print(error.localizedDescription)

    }

       // ASAuthorizationControllerDelegate function for successful authorization

    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {

        if #available(iOS 13.0, *) {
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                
                var appleId: String!
                var appleUserFirstName: String!
                var appleUserLastName: String!
                var appleUserEmail: String!
                var fullName: String!
                
                if userSaved.bool(forKey:"isLoggedinApple") == true
                {
                    appleId = userSaved.string(forKey: "appIDStr") //String
                    appleUserEmail = userSaved.string(forKey: "emailAddress") //String
                    fullName = userSaved.string(forKey: "fullNamestr") //String
                }
                else
                {
                  // Create an account as per your requirement
                   appleId = appleIDCredential.user
                   //     let tokenstr = appleIDCredential.identityToken
                    appleUserFirstName = appleIDCredential.fullName?.givenName
                    appleUserLastName = appleIDCredential.fullName?.familyName
                    appleUserEmail = appleIDCredential.email
                    
                    fullName = (appleUserFirstName)! + " " + appleUserLastName!
                    LOGGED_IN_APPLE = true
                    userSaved.set(LOGGED_IN_APPLE, forKey: "isLoggedinApple") //Bool
                    userSaved.set(appleId, forKey: "appIDStr") //String
                    userSaved.set(appleUserEmail, forKey: "emailAddress") //String
                    userSaved.set(fullName, forKey: "fullNamestr") //String

                }
                
                
                let tokenStr = String(data: appleIDCredential.identityToken!, encoding: .utf8)!
                let userID = String(describing: appleId)
                let emailAddress = String(describing: appleUserEmail)
                let password = "1234567"
                
                print(tokenStr)
                print(userID)
                
       //         PFUser.register(AuthDelegate(), forAuthType: "apple")
                
                
                PFUser.logInWithUsername(inBackground: emailAddress, password: password){ (user, error) -> Void in
                    if error == nil {
                
                        self.dismiss(animated: true, completion: nil)
                        self.hideHUD()
                            
                    // Login failed. Try again or SignUp
                    } else {
                      //  self.simpleAlert("\(error!.localizedDescription)")
                        
                        let name = fullName
                        // Update user data

                        let nameArr = name!.components(separatedBy: " ")
                        var username = String()
                        for word in nameArr {
                            username.append(word.lowercased())
                        }
                        
                        let userForSignUp = PFUser()
                            userForSignUp.username = username
                            userForSignUp.password = "1234567"
                            userForSignUp.email = emailAddress
                            userForSignUp[USER_FULLNAME] = name
                            userForSignUp[USER_IS_REPORTED] = false
                            let hasBlocked = [String]()
                            userForSignUp[USER_HAS_BLOCKED] = hasBlocked

                           // userForSignUp[USER_EMAIL_VERIFIED] = true
                          //  userForSignUp.saveInBackground()
                          
                        // Save default image
                               let imageData = UIImageJPEGRepresentation(UIImage(named:"logo")!, 0.8)
                               let imageFile = PFFile(name:"avatar.jpg", data:imageData!)
                               userForSignUp[USER_AVATAR] = imageFile
                               
                               userForSignUp.signUpInBackground { (succeeded, error) -> Void in
                                   if error == nil {
                               PFUser.logInWithUsername(inBackground: emailAddress, password: password){ (user, error) -> Void in
                                 if error == nil {
                                                                    
                                    self.dismiss(animated: true, completion: nil)
                                    self.hideHUD()
                                                                        
                                                                // Login failed. Try again or SignUp
                                } else {
                                    self.simpleAlert("\(error!.localizedDescription)")
                                    self.hideHUD()
                                  }
                                }
                               
                                   // ERROR
                                   } else {
                                    self.simpleAlert("\(error!.localizedDescription)")
                                       self.hideHUD()
                               }}
                    }}
                }
                
            else if let passwordCredential = authorization.credential as? ASPasswordCredential {
                
                hideHUD()

                let appleUsername = passwordCredential.user
                
                let applePassword = passwordCredential.password
                
                //Write your code
                
            }
        } else {
            // Fallback on earlier versions
        }

    }

}

extension Intro: ASAuthorizationControllerPresentationContextProviding {

    //For present window

    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {

        return self.view.window!

    }

}


class AuthDelegate:NSObject, PFUserAuthenticationDelegate {
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        print(authData!)
        return true
    }
    
    func restoreAuthenticationWithAuthData(authData: [String : String]?) -> Bool {
         print(authData!)
        return true
    }
}
