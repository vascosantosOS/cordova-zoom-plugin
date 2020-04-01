# Zoom Outsystems Software Development Kit (SDK)

<div align="center">
<img src="https://s3.amazonaws.com/user-content.stoplight.io/8987/1541013063688" width="400px" max-height="400px" style="margin:auto;"/>
</div>

### Prerequisites

Before you try out our SDK, you would need the following to get started:

* **A Zoom Account**: If you do not have one, you can sign up at [https://zoom.us/signup](https://zoom.us/signup).
  * Once you have your Zoom Account, sign up for a 60-days free trial at [https://marketplace.zoom.us/](https://marketplace.zoom.us/)
* **A mobile device**
  * Android
    * Android 4.0 (API Level 14) or later.
  * iOS
    * iPhone or iPad
    * **npm@6.7.0+**
    * **cordova-cli@7.1.0+**
    

  
 If you are developing on Android, you will need to install the 8.0.0 version of cordova-android
 ```
 cordova platform add android@8.0.0
 ```
  If you are developing on iOS, you will need to install the 5.1.0 version of cordova-ios
 ```
 cordova platform add ios@5.1.0
 ```

### Installing
Local:
  Clone or download a copy of our SDK files from GitHub. After you unzipped the file, you should have the following folders:

  ```
  .
  ├── README.md
  ├── libs
  ├── package.json
  ├── plugin.xml
  ├── src
  └── www
  ```
  In your cordova application directory, run the following to install the plugin:
  ```
  cordova plugin add cordova.plugin.zoom --variable IOS_CAMERA_USAGE_DESCRIPTION="Usage description" --variable IOS_MICROPHONE_USAGE_DESCRIPTION="Usage description"
  ```
Outsystems:
  In the extensibility configurations of the plugin wrapper put:
  {
    ,
    variables:[{"key":"IOS_CAMERA_USAGE_DESCRIPTION","value":"Usage description"},{"key":"IOS_MICROPHONE_USAGE_DESCRIPTION","value":"Usage description"}]
  }

### Usage

1. Initialize Zoom SDK
Initialize Zoom SDK, need to be called when app fired up.
```
this.zoomService.initialize(SDK_KEY,SDK_SECRET,API_KEY, API_SECRET)
  .then((success: any) => console.log(success))
  .catch((error: any) => console.log(error));
```

2. Login
Log user in with Zoom username and password.
```
this.zoomService.login(userName, password)
  .then((success: any) => console.log(success))
  .catch((error: any) => console.log(error));
```
3. Logout
Log user out.
```
this.zoomService.logout()
  .then((success: boolean) => console.log(success))
  .catch((error: any) => console.log(error));
```

4. isLoggedIn
Check whether a user is logged in. Return true if the user is logged in. False if the user is not logged in.
```
this.zoomService.isLoggedIn()
  .then((success: boolean) => console.log(success))
  .catch((error: any) => console.log(error));
```

5. MeetingOptions
Meeting options (Only available on Android). Configure the default meeting room.
```
let options = {
  "no_driving_mode":true,
  "no_invite":true,
  "no_meeting_end_message":true,
  "no_titlebar":false,
  "no_bottom_toolbar":false,
  "no_dial_in_via_phone":true,
  "no_dial_out_to_phone":true,
  "no_disconnect_audio":true,
  "no_share":true,
  "no_audio":true,
  "no_video":true,
  "no_meeting_error_message":true
 };
 ```

6. Join Meeting
Join meeting 
```
this.zoomService.joinMeeting(meetingNumber, meetingPassword, displayName, options)
  .then((success: any) => console.log(success))
  .catch((error: any) => console.log(error));
```
7. Get Users Id
Get Users Id
```
this.zoomService.getUsersId()
  .then((success: [UserId]) => console.log(success))
  .catch((error: any) => console.log(error));
```

8. Start an existing meeting for non-login user
Start an existing meeting for non-login user.
```
this.zoomService.startMeetingWithZAK(meetingNumber, displayName, userId, options)
  .then((success: any) => console.log(success))
  .catch((error: any) => console.log(error));
```

9. Start an existing meeting for logged in user
Start an existing meeting for logged in user.
```
this.zoomService.startMeeting(meetingNumber, options)
  .then((success: any) => console.log(success))
  .catch((error: any) => console.log(error));
```

10. Start an instant meeting for logged in user
Start an instant meeting for logged in user.
```
this.zoomService.startInstantMeeting()
  .then((success: any) => console.log(success))
  .catch((error: any) => console.log(error));
```

## License

Please refer to [LICENSE.md](LICENSE.md) file for details

---
Copyright ©2019 Zoom Video Communications, Inc. All rights reserved.
