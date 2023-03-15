/*-----------------------------------
 
 - MyStream -
 
 Created by cubycode ©2017
 All Rights reserved
 
 -----------------------------------*/

import UIKit
import Parse
import GoogleMobileAds
import AudioToolbox



// MARK: - STREAM CELL
class StreamCell: UITableViewCell {
    /* Views */
    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var avatarButton: UIButton!
    @IBOutlet weak var fullnameLabel: UILabel!
    @IBOutlet weak var usernameTimeLabel: UILabel!
    @IBOutlet weak var thumbnailImg: UIImageView!
    @IBOutlet weak var postlabel: UILabel!
    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var commentsButton: UIButton!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var statsButton: UIButton!
    @IBOutlet weak var deleteStreamButton: UIButton!
    
}






// MARK: - HOME CONTROLLER
class Home: UIViewController,
GADInterstitialDelegate,
UITableViewDataSource,
UITableViewDelegate,
UITextFieldDelegate
{
    
    /* Views */
    @IBOutlet weak var streamsTableView: UITableView!
    @IBOutlet weak var currUserAvatarImg: UIImageView!
    let refreshControl = UIRefreshControl()
    var adMobInterstitial: GADInterstitial!

    
    
    /* Variables */
    var streamsArray = [PFObject]()

    
    
    
    
override func viewDidAppear(_ animated: Bool) {
    
    // USER IS NOT LOGGED IN
    if PFUser.current() == nil {
        let viewController = self.storyboard?.instantiateViewController(withIdentifier: "Intro") as! Intro

           let navigationController: UINavigationController = UINavigationController(rootViewController: viewController)

           navigationController.modalPresentationStyle = .fullScreen

           present(navigationController, animated: true, completion: nil)
    
    // USER IS LOGGED IN
    } else {
        let currUser = PFUser.current()!

        // Associate the device with a user for Push Notifications
        let installation = PFInstallation.current()
        installation?["username"] = currUser.username
        installation?["userID"] = currUser.objectId!
        installation?.saveInBackground(block: { (succ, error) in
            if error == nil {
                print("PUSH REGISTERED FOR: \(currUser.username!)")
        }})

        
        // Get user's avatar
        currUserAvatarImg.layer.cornerRadius = currUserAvatarImg.bounds.size.width/2
        getParseImage(currUser, imgView: currUserAvatarImg, columnName: USER_AVATAR)
        
        
        // Recall query in case something has been reported (either a User or a Stream)
        if mustRefresh {
            queryStreams()
            mustRefresh = false
        }
    }
    
}
    
    
    
    
override func viewDidLoad() {
        super.viewDidLoad()
    
    // Layouts
    currUserAvatarImg.layer.cornerRadius = currUserAvatarImg.bounds.size.width/2
    if UIDevice.current.userInterfaceIdiom == .pad {
        streamsTableView.frame.size.width = 500
        streamsTableView.center.x = view.center.x
    }

    
    // Init a Refresh Control
    refreshControl.tintColor = MAIN_COLOR
    refreshControl.addTarget(self, action: #selector(refreshTB), for: .valueChanged)
    streamsTableView.addSubview(refreshControl)
    
    
    // Call query
    if PFUser.current() != nil { queryStreams() }
    
    
    // Call AdMob Interstitial
    adMobInterstitial = GADInterstitial(adUnitID: ADMOB_INTERSTITIAL_UNIT_ID)
    adMobInterstitial.load(GADRequest())
    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
        self.showInterstitial()
    })
}

   
    
    
    
// MARK: - QUERY STREAMS
func queryStreams() {
    showHUD("Please wait...")
    let currUser = PFUser.current()!
    
    let query = PFQuery(className: STREAMS_CLASS_NAME)
    query.whereKey(STREAMS_REPORTED_BY, notContainedIn: [currUser.objectId!])
    query.limit = 50
    query.order(byDescending: "createdAt")
    
    query.findObjectsInBackground { (objects, error) in
            if error == nil {
                self.streamsArray = objects!
                self.hideHUD()
                self.streamsTableView.reloadData()
            // error
            } else {
                self.simpleAlert("\(error!.localizedDescription)")
                self.hideHUD()
    }}
}
    

    
// MARK: - TABLEVIEW DELEGATES
func numberOfSections(in tableView: UITableView) -> Int {
    return 1
}
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return streamsArray.count
}
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "StreamCell", for: indexPath) as! StreamCell
    
    // Get Parse Obj
    var sObj = PFObject(className: STREAMS_CLASS_NAME)
    sObj = streamsArray[indexPath.row]
    
    // Get User Pointer
    let userPointer = sObj[STREAMS_USER_POINTER] as! PFUser
    userPointer.fetchIfNeededInBackground(block: { (user, error) in
        if error == nil {
            
            // Get Stream image
            cell.thumbnailImg.layer.cornerRadius =  10
            if sObj[STREAMS_IMAGE] != nil {
                getParseImage(sObj, imgView: cell.thumbnailImg, columnName: STREAMS_IMAGE)
                cell.thumbnailImg.isHidden = false
                cell.postlabel.frame.origin.y = 195
                cell.postlabel.frame.size.height = 52
            // No Stream image
            } else {
                cell.thumbnailImg.isHidden = true
                cell.postlabel.frame.origin.y = 68
                cell.postlabel.frame.size.height = 174
            }
            
            // Get Stream text
            cell.postlabel.text = "\(sObj[STREAMS_TEXT]!)"
            
            // Get likes
            let likes = sObj[STREAMS_LIKES] as! Int
            cell.likesLabel.text = likes.abbreviated
            
            // Show liked icon
            let likedBy = sObj[STREAMS_LIKED_BY] as! [String]
            if likedBy.contains(PFUser.current()!.objectId!) {
                cell.likeButton.setBackgroundImage(UIImage(named: "liked_butt_small"), for: .normal)
            } else {
                cell.likeButton.setBackgroundImage(UIImage(named: "like_butt_small"), for: .normal)
            }
            
            // Get comments
            let comments = sObj[STREAMS_COMMENTS] as! Int
            cell.commentsLabel.text = comments.abbreviated
            
            
            
            // Get userPointer details
            cell.avatarImg.layer.cornerRadius = cell.avatarImg.bounds.size.width/2
            getParseImage(userPointer, imgView: cell.avatarImg, columnName: USER_AVATAR)
      
            cell.fullnameLabel.text = "\(userPointer[USER_FULLNAME]!)"
            
            let sDate = self.timeAgoSinceDate(sObj.createdAt!, currentDate: Date(), numericDates: true)
            cell.usernameTimeLabel.text = "@\(userPointer[USER_USERNAME]!) • \(sDate)"
            
            
            // Assign tags to the Buttons
            cell.avatarButton.tag = indexPath.row
            cell.likeButton.tag = indexPath.row
            cell.commentsButton.tag = indexPath.row
            cell.shareButton.tag = indexPath.row

            
        // error in userPointer
        } else {
            self.simpleAlert("\(error!.localizedDescription)")
    }})// end userPointer
   
return cell
}
   
func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 290
}


    
// MARK: - CELL TAPPED -> SHOW STREAM DETAILS
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    // Get Parse Obj
    var sObj = PFObject(className: STREAMS_CLASS_NAME)
    sObj = streamsArray[indexPath.row]
    
    let aVC = storyboard?.instantiateViewController(withIdentifier: "StreamDetails") as! StreamDetails
    aVC.sObj = sObj
    navigationController?.pushViewController(aVC, animated: true)
}
    

    
    
    
// MARK: - ADD STREAM BUTTON
@IBAction func addStreamButt(_ sender: Any) {
    let aVC = storyboard?.instantiateViewController(withIdentifier: "AddStream") as! AddStream
    present(aVC, animated: true, completion: nil)
}
    
// MARK: - ADD PHOTO BUTTON
@IBAction func addPhotoButt(_ sender: Any) {
    let aVC = storyboard?.instantiateViewController(withIdentifier: "AddStream") as! AddStream
    aVC.streamAttachment = "image"
    present(aVC, animated: true, completion: nil)
}

// MARK: - ADD VIDEO BUTTON
@IBAction func addVideoButt(_ sender: Any) {
    let aVC = storyboard?.instantiateViewController(withIdentifier: "AddStream") as! AddStream
    aVC.streamAttachment = "video"
    present(aVC, animated: true, completion: nil)
}
    
// MARK: - ADD AUDIO BUTTON
@IBAction func addAudioButt(_ sender: Any) {
    let aVC = storyboard?.instantiateViewController(withIdentifier: "AddStream") as! AddStream
    aVC.streamAttachment = "audio"
    present(aVC, animated: true, completion: nil)
}

    
    
    
    
    
// MARK: - LIKE BUTTON
@IBAction func likeButt(_ sender: UIButton) {
    // Get Parse Obj
    var sObj = PFObject(className: STREAMS_CLASS_NAME)
    sObj = streamsArray[sender.tag]
    let currUser = PFUser.current()!
    let indexP = IndexPath(row: sender.tag, section: 0)
    
    // Get likedBy
    var likedBy = sObj[STREAMS_LIKED_BY] as! [String]
    
    // UNLIKE THIS STREAM
    if likedBy.contains(currUser.objectId!) {
        likedBy = likedBy.filter{ $0 != currUser.objectId! }
        sObj[STREAMS_LIKED_BY] = likedBy
        sObj.incrementKey(STREAMS_LIKES, byAmount: -1)
        sObj.saveInBackground()
        
        sender.setBackgroundImage(UIImage(named:"like_butt_small"), for: .normal)
        let cell = streamsTableView.cellForRow(at: indexP) as! StreamCell
        let likes = sObj[STREAMS_LIKES] as! Int
        cell.likesLabel.text = likes.abbreviated
        
        
    // LIKE THIS STREAM
    } else {
        likedBy.append(currUser.objectId!)
        sObj[STREAMS_LIKED_BY] = likedBy
        sObj.incrementKey(STREAMS_LIKES, byAmount: 1)
        sObj.saveInBackground()
        
        sender.setBackgroundImage(UIImage(named:"liked_butt_small"), for: .normal)
        let cell = streamsTableView.cellForRow(at: indexP) as! StreamCell
        let likes = sObj[STREAMS_LIKES] as! Int
        cell.likesLabel.text = likes.abbreviated
        
        // Send push notification
        sendPushNotification(currentUser: currUser, pushMess: "liked your Stream: ", textColumn: STREAMS_TEXT, obj: sObj, userPointerColumn: STREAMS_USER_POINTER)

        // Save Activity
        saveActivity(currUser: currUser, streamObj: sObj, text: "liked your Stream: '\(sObj[STREAMS_TEXT]!)'")
    }
}
    
    
    
    
// MARK: - COMMENTS BUTTON
@IBAction func commentsButt(_ sender: UIButton) {
    // Get Parse Obj
    var sObj = PFObject(className: STREAMS_CLASS_NAME)
    sObj = streamsArray[sender.tag]
    
    let aVC = storyboard?.instantiateViewController(withIdentifier: "Comments") as! Comments
    aVC.sObj = sObj
    present(aVC, animated: true, completion: nil)
}

    
    
    
// MARK: - SHARE BUTTON
@IBAction func shareButt(_ sender: UIButton) {
    var sObj = PFObject(className: STREAMS_CLASS_NAME)
    sObj = streamsArray[sender.tag]
    
    let indexP = IndexPath(row: sender.tag, section: 0)
    let cell = streamsTableView.cellForRow(at: indexP) as! StreamCell
    let streamImg = cell.thumbnailImg.image
    let streamText = cell.postlabel.text!

    let messageStr  = "\(streamText) on #\(APP_NAME)"
    var img = UIImage()
    if sObj[STREAMS_IMAGE] != nil { img = streamImg!
    } else {  img = UIImage(named:"logo")! }
    
    let shareItems = [messageStr, img] as [Any]
    
    let actVC = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
    actVC.excludedActivityTypes = [.print, .postToWeibo, .copyToPasteboard, .addToReadingList, .postToVimeo]
    
    if UIDevice.current.userInterfaceIdiom == .pad {
        // iPad
        let popOver = UIPopoverController(contentViewController: actVC)
        popOver.present(from: CGRect(x: self.view.frame.size.width/2, y: self.view.frame.size.height/2, width: 0, height: 0), in: self.view, permittedArrowDirections: .down, animated: true)
    } else {
        // iPhone
        present(actVC, animated: true, completion: nil)
    }
    
    // Increment shares amount
    sObj.incrementKey(STREAMS_SHARES, byAmount: 1)
    sObj.saveInBackground()
}
    

   
  
// MARK: - AVATAR BUTTON
@IBAction func avatarButt(_ sender: UIButton) {
    // Get Parse Obj
    var sObj = PFObject(className: STREAMS_CLASS_NAME)
    sObj = streamsArray[sender.tag]
    
    // Get User Pointer
    let userPointer = sObj[STREAMS_USER_POINTER] as! PFUser
    userPointer.fetchIfNeededInBackground(block: { (user, error) in
        if error == nil {
            let aVC = self.storyboard?.instantiateViewController(withIdentifier: "OtherUserProfile") as! OtherUserProfile
            aVC.userObj = userPointer
            self.navigationController?.pushViewController(aVC, animated: true)
        } else {
            self.simpleAlert("\(error!.localizedDescription)")
    }})
}
    
    
    
    
    
    
// MARK: - REFRESH DATA
@objc func refreshTB () {
    // Recall query
    queryStreams()
    
    if refreshControl.isRefreshing {
        refreshControl.endRefreshing()
    }
}
    

    
    
    
// MARK: - ADMOB INTERSTITIAL
func showInterstitial() {
    if adMobInterstitial.isReady {
        adMobInterstitial.present(fromRootViewController: self)
        print("AdMob Interstitial!")
    }
}
 
    
override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
