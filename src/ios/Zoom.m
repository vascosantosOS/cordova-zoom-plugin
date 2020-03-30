/**
 *  Zoom.m
 *
 *  @author Carson Chen (carson.chen@zoom.us)
 *  @version v4.4.55130.0712
 */

#import "Zoom.h"

#define kSDKDomain  @"zoom.us"
#define DEBUG   YES

@implementation Zoom

- (void)initialize:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variables.
    NSString* appKey = [command.arguments objectAtIndex:0];
    NSString* appSecret = [command.arguments objectAtIndex:1];
    
    apiKey = [command.arguments objectAtIndex:2];
    apiSecret = [command.arguments objectAtIndex:3];

    // Run authentication and initialize SDK on main thread.
    dispatch_async(dispatch_get_main_queue(), ^(void){
        // if input parameters are not valid.
        if (appKey == nil || ![appKey isKindOfClass:[NSString class]] || [appKey length] == 0 || appSecret == nil || ![appSecret isKindOfClass:[NSString class]]|| [appSecret length] == 0) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Please pass valid SDK key and secret."];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }

        [MobileRTC initializeWithDomain:kSDKDomain enableLog:YES];
        // Get auth service.
        MobileRTCAuthService *authService = [[MobileRTC sharedRTC] getAuthService];
        if (authService)
        {
            // Assign delegate.
            authService.delegate = self;
            // Assign key and secret.
            authService.clientKey = appKey;
            authService.clientSecret = appSecret;
            // Perform SDK auth.
            [authService sdkAuth];
        }
    });
}

- (void)login:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variables.
    NSString* username = [command.arguments objectAtIndex:0];
    NSString* password = [command.arguments objectAtIndex:1];
    // Run login method on main thread.
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (username != nil && [username isKindOfClass:[NSString class]] && [username length] > 0 && password != nil && [password isKindOfClass:[NSString class]]  && [password length]) {
            // Try to log user in
            [[[MobileRTC sharedRTC] getAuthService] loginWithEmail:username password:password remeberMe:YES];
        } else {
            NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
            res[@"result"] = @NO;
            res[@"message"] = @"Please enter valid username and password";
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:res];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    });
}

- (void)logout:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Run logout method on main thread.
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        // Try to log user out
        if (![[[MobileRTC sharedRTC] getAuthService] isLoggedIn]) {
            NSMutableDictionary *res = [[NSMutableDictionary alloc] init];
            res[@"result"] = @NO;
            res[@"message"] = @"You are not logged in.";
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:res];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
        [[[MobileRTC sharedRTC] getAuthService] logoutRTC];
    });
}

- (void)isLoggedIn:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Check whether user is logged in.
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        MobileRTCAuthService* authService = [[MobileRTC sharedRTC] getAuthService];
        if (authService != nil) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[authService isLoggedIn]];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        }
    });
}

- (void)joinMeeting:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variables.
    NSString* meetingNo = [command.arguments objectAtIndex:0];
    NSString* meetingPassword = [command.arguments objectAtIndex:1];
    NSString* displayName = [command.arguments objectAtIndex:2];

    if (DEBUG) {
        NSLog(@"========meeting number======= %@", meetingNo);
        NSLog(@"========display name======= %@", displayName);
    }
    // Meeting number regular expression.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{8,11}" options:0 error:nil];

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (meetingNo == nil || ![meetingNo isKindOfClass:[NSString class]] || [meetingNo length] == 0 || [regex numberOfMatchesInString:meetingNo options:0 range:NSMakeRange(0, [meetingNo length])] == 0|| displayName == nil || ![displayName isKindOfClass:[NSString class]] || [displayName length] == 0) {
            NSLog(@"Please enter valid meeting number and display name");
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Please enter valid meeting number and display name"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }
        // Get meeting service
        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
        if (ms != nil)
        {
            // Assign delegate.
            ms.delegate = self;
            // Prepare meeting parameters.
            NSDictionary *paramDict = @{
                                        kMeetingParam_Username:displayName,
                                        kMeetingParam_MeetingNumber:meetingNo,
                                        kMeetingParam_MeetingPassword:meetingPassword
                                        };
            // Join meeting.
            MobileRTCMeetError response = [ms joinMeetingWithDictionary:paramDict];
            if (DEBUG) {
                NSLog(@"Join a Meeting res:%d", response);
            }
        }
    });
}

- (void)startMeeting:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variables.
    NSString* meetingNo = [command.arguments objectAtIndex:0];
    NSString* displayName = [command.arguments objectAtIndex:1];
    NSString* userId = [command.arguments objectAtIndex:2];

    dispatch_async(dispatch_get_main_queue(), ^(void) {

        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{8,11}" options:0 error:nil];

        if (meetingNo == nil || ![meetingNo isKindOfClass:[NSString class]] || [meetingNo length] == 0 || [regex numberOfMatchesInString:meetingNo options:0 range:NSMakeRange(0, [meetingNo length])] == 0) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Please enter valid meeting number"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }

        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];
        if (ms)
        {
            // Assign delegate.
            ms.delegate = self;
            // Prepare start meeting param.
            MobileRTCMeetingStartParam * param = nil;

            if ([[[MobileRTC sharedRTC] getAuthService] isLoggedIn])
            {
                // Is user is logged in.
                NSLog(@"start meeting with logged in.");
                MobileRTCMeetingStartParam4LoginlUser * user = [[MobileRTCMeetingStartParam4LoginlUser alloc]init];
                user.isAppShare = NO;
                param = user;
                param.meetingNumber = meetingNo;
            }
            else
            {

                NSString* zoomToken;
                NSString* zoomAccessToken;
                if (userId != nil && [userId isKindOfClass:[NSString class]] && [userId length] != 0) {
                    zoomToken = [self requestTokenOrZAKForUser:userId withType:@"token"];
                    zoomAccessToken = [self requestTokenOrZAKForUser:userId withType:@"zak"];
                    if (zoomToken == nil) {
                        zoomToken = zoomAccessToken;
                    }
                    // Is user is not logged in.
                    NSLog(@"Start meeting without logged in.");
                    NSLog(@"zoom token: %@",zoomToken);
                    NSLog(@"zak: %@",zoomAccessToken);
                    if (zoomToken == nil || ![zoomToken isKindOfClass:[NSString class]] || [zoomToken length] == 0 ||
                        zoomAccessToken == nil || ![zoomAccessToken isKindOfClass:[NSString class]] || [zoomAccessToken length] == 0) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Could not retrieve zoomToken and zoomAccessToken from zoom api - Possible causes 'ApiKey' 'ApiSecret' or 'userId'."];
                        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                        return;
                    }

                    MobileRTCMeetingStartParam4WithoutLoginUser * user = [[MobileRTCMeetingStartParam4WithoutLoginUser alloc]init];
                    user.userType = MobileRTCUserType_APIUser;
                    user.meetingNumber = meetingNo;
                    user.userName = displayName;
                    user.userToken = zoomToken;
                    user.userID = userId;
                    user.isAppShare = NO;
                    user.zak = zoomAccessToken;
                    param = user;
                }else{
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"UserId required when not logged in!"];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
                    return;
                }
                

            }
            // Start meeting.
            MobileRTCMeetError response = [ms startMeetingWithStartParam:param];
            if (DEBUG) {
                NSLog(@"start a meeting res:%d", response);
            }
        }
    });
}

- (void)startInstantMeeting:(CDVInvokedUrlCommand*)command
{
    pluginResult = nil;
    callbackId = command.callbackId;

    dispatch_async(dispatch_get_main_queue(), ^(void) {

        if (![[[MobileRTC sharedRTC] getAuthService] isLoggedIn]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"You are not logged in"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }
        // Get meeting service.
        MobileRTCMeetingService *ms = [[MobileRTC sharedRTC] getMeetingService];

        if (ms)
        {
            // Assign delegate.
            ms.delegate = self;
            // Prepare start meeting parameters.
            NSDictionary* paramDict = nil;
            paramDict = @{};
            // Start instant meeting.
            MobileRTCMeetError response = [ms startMeetingWithDictionary:paramDict];
            if (DEBUG) {
                NSLog(@"start an instant meeting res:%d", response);
            }
        }
    });
}
-(NSString *)dictionaryToJson:(NSDictionary*)dictionary{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                  options:(NSJSONWritingOptions) (0)
                                                    error:&error];

    if (! jsonData) {
       NSLog(@"%s: error: %@", __func__, error.localizedDescription);
       return @"{}";
    } else {
       return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}


-(NSString *)arrayToJson:(NSArray*)array{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array
                                                  options:(NSJSONWritingOptions) (0)
                                                    error:&error];

    if (! jsonData) {
       NSLog(@"%s: error: %@", __func__, error.localizedDescription);
       return @"{}";
    } else {
       return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}
-(NSString *)base64urlEncode:(NSString*)string{
    NSData *nsdata = [string
      dataUsingEncoding:NSUTF8StringEncoding];

    // Get NSString from NSData object in Base64
    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
    base64Encoded = [base64Encoded stringByReplacingOccurrencesOfString:@"=" withString:@""];
    base64Encoded = [base64Encoded stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    base64Encoded = [base64Encoded stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return base64Encoded;
}

-(NSString*) hmac:(NSString*)data withKey:(NSString*)key{

    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];

    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);

    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];

    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    hash = [hash stringByReplacingOccurrencesOfString:@"=" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    hash = [hash stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return hash;
}

- (NSString*)createJWTAccessToken
{
  NSMutableDictionary * dictHeader = [NSMutableDictionary dictionary];
  [dictHeader setValue:@"HS256" forKey:@"alg"];
  [dictHeader setValue:@"JWT" forKey:@"typ"];
  NSString * base64Header = [self base64urlEncode:[self dictionaryToJson:dictHeader]];

  //    {
  //        "iss": "API_KEY",
  //        "exp": 1496091964000
  //    }
  NSInteger timeInSeconds = [[NSDate date] timeIntervalSince1970];
  NSInteger time = timeInSeconds + 1000;//1h
  NSMutableDictionary * dictPayload = [NSMutableDictionary dictionary];
  [dictPayload setValue:apiKey forKey:@"iss"];
    [dictPayload setValue:[NSNumber numberWithLong:time] forKey:@"exp"];
  NSString * base64Payload = [self base64urlEncode:[self dictionaryToJson:dictPayload]];

  NSString * composer = [NSString stringWithFormat:@"%@.%@",base64Header,base64Payload];
  NSString * hashmac = [self hmac:composer withKey:apiSecret];

  NSString * accesstoken = [NSString stringWithFormat:@"%@.%@.%@",base64Header,base64Payload,hashmac];
  return accesstoken;
}

- (NSString*)requestTokenOrZAKForUser:(NSString *)userId withType:(NSString*)type
{
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    NSString * bodyString = [NSString stringWithFormat:@"token?type=%@",type];
    NSString * urlString = [NSString stringWithFormat:@"%@/%@/%@",@"https://api.zoom.us/v2/users",userId,bodyString];
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"urlString = %@",urlString);
    NSMutableURLRequest* mRequest = [self requestUrl:urlString];
    NSURLSession * session = [NSURLSession sharedSession];
    __block NSString* token;
    [[session dataTaskWithRequest:mRequest
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
        
      if (error != nil) {
          dispatch_semaphore_signal(sem);
          return;
      }
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        
        token = [dictionary objectForKey:@"token"];
        dispatch_semaphore_signal(sem);
        
    }]resume];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    NSLog(@"try");
    return token;
}

- (NSMutableURLRequest*)requestUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *mRequest = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
    [mRequest setHTTPMethod:@"GET"];
    [mRequest setValue:[NSString stringWithFormat:@"Bearer %@",[self createJWTAccessToken]] forHTTPHeaderField:@"Authorization"];
    return mRequest;
}

-(void)getUsersId:(CDVInvokedUrlCommand *)command
{
        NSMutableURLRequest* mRequest = [self requestUrl:@"https://api.zoom.us/v2/users"];
    NSURLSession * session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:mRequest
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
      if (error != nil) {
          return;
      }
      NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if ([[dictionary objectForKey:@"message"]  isEqual: @"Invalid access token."]) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"There was an error creating the access token!"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
            return;
        }
        NSMutableArray* users = [[NSMutableArray alloc] init];
        for (NSDictionary* user in [dictionary objectForKey:@"users"]) {
            NSMutableDictionary* myuser = [[NSMutableDictionary alloc] init];;
            [myuser setValue:[user objectForKey:@"id"] forKey:@"id"];
            [myuser setValue:[user objectForKey:@"email"] forKey:@"email"];
            [users addObject:myuser];
        }
      
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:users];
      [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];

    }] resume];
        
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];

    pluginResult.keepCallback = [NSNumber numberWithBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    
}

- (void)setLocale:(CDVInvokedUrlCommand *)command
{
    pluginResult = nil;
    callbackId = command.callbackId;
    // Get variable
    NSString* languageTag = [command.arguments objectAtIndex:0];

    NSString* language = @"en";

    // Ugly way to unify language codes.
    if ([languageTag isEqualToString:@"en-US"]) {
        language = @"en";
    } else if ([languageTag isEqualToString:@"zh-CN"]) {
        language = @"zh-Hans";
    } else if ([languageTag isEqualToString:@"ja-JP"]) {
        language = @"ja";
    } else if ([languageTag isEqualToString:@"de-DE"]) {
        language = @"de";
    } else if ([languageTag isEqualToString:@"fr-FR"]) {
        language = @"fr";
    } else if ([languageTag isEqualToString:@"zh-TW"]) {
        language = @"zh-Hant";
    } else if ([languageTag isEqualToString:@"es-419"]) {
        language = @"es";
    } else if ([languageTag isEqualToString:@"ru-RU"]) {
        language = @"ru";
    } else if ([languageTag isEqualToString:@"pt-PT"]) {
        language = @"pt-PT";
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Language not supported"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if (DEBUG) {
            NSLog(@"set language ===== %@", language);
            NSLog(@"Supported languages: %@", [[MobileRTC sharedRTC] supportedLanguages]);
        }
        // Set language
        [[MobileRTC sharedRTC] setLanguage:language];

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Set language Successfully"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    });
}

- (void)onMobileRTCAuthReturn:(MobileRTCAuthError)returnValue
{
    if (DEBUG) {
        NSLog(@"onMobileRTCAuthReturn: %@", [self getAuthErrorMessage:returnValue]);
    }

    if (returnValue != MobileRTCAuthError_Success)
    {
        // Authentication error, please check error code.
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"SDK authentication failed, error: %@", @""), [self getAuthErrorMessage:returnValue]];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:message];
    } else {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Initialize successfully, return value: %@", @""), [self getAuthErrorMessage:returnValue]];
        NSLog(@"%@", message);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    }
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)onMobileRTCLoginReturn:(NSInteger)returnValue
{
    // 0 is success, otherwise is failed.
    if (DEBUG) {
        NSLog(@"onMobileRTCLoginReturn result=%zd", returnValue);
    }

    NSMutableDictionary *res = [[NSMutableDictionary alloc] init];

    if (returnValue == 0) {
        res[@"result"] = @YES;
        res[@"message"] = @"Successfully logged in";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:res];
    } else {
        res[@"result"] = @NO;
        res[@"message"] = @"ERROR! Failed to log in";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:res];
    }

    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)onMobileRTCLogoutReturn:(NSInteger)returnValue
{
    // 0 is success, otherwise is failed.
    if (DEBUG) {
       NSLog(@"onMobileRTCLogoutReturn result=%zd", returnValue);
    }

    NSMutableDictionary *res = [[NSMutableDictionary alloc] init];

    if (returnValue == 0) {
        res[@"result"] = @YES;
        res[@"message"] = @"Successfully logged out";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:res];
    } else {
        res[@"result"] = @NO;
        res[@"message"] = @"ERROR! Failed to log out";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:res];
    }

    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (void)onMeetingError:(MobileRTCMeetError)error message:(NSString*)message
{
    if (DEBUG) {
     NSLog(@"onMeetingError:%zd, message:%@", error, message);
    }
    if (error != MobileRTCMeetError_Success) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[self getMeetErrorMessage:error]];
    } else {
     pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[self getMeetErrorMessage:error]];
    }
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

- (NSString *)getAuthErrorMessage:(MobileRTCAuthError)errorCode
{
    NSString* message = @"";
    switch (errorCode) {
        case MobileRTCAuthError_Success:
            message = @"Authentication success.";
            break;
        case MobileRTCAuthError_KeyOrSecretEmpty:
            message = @"SDK key or secret is empty.";
            break;
        case MobileRTCAuthError_KeyOrSecretWrong:
            message = @"SDK key or secret is wrong.";
            break;
        case MobileRTCAuthError_AccountNotSupport:
            message = @"Your account does not support SDK.";
            break;
        case MobileRTCAuthError_AccountNotEnableSDK:
            message = @"Your account does not support SDK.";
            break;
        case MobileRTCAuthError_Unknown:
            message = @"Unknown error.Please try again.";
            break;
        default:
            message = @"Unknown error.Please try again.";
            break;
    }
    return message;
}

- (NSString *)getMeetErrorMessage:(MobileRTCMeetError)errorCode
{
    NSString * message = @"";
    switch (errorCode) {
        case MobileRTCMeetError_Success:
            message = @"Successfully start/join meeting.";
            break;
        case MobileRTCMeetError_NetworkError:
            message = @"Network issue, please check your network connection.";
            break;
        case MobileRTCMeetError_ReconnectError:
            message = @"Failed to reconnect to meeting.";
            break;
        case MobileRTCMeetError_MMRError:
            message = @"MMR issue, please check mmr configruation.";
            break;
        case MobileRTCMeetError_PasswordError:
            message = @"Meeting password incorrect.";
            break;
        case MobileRTCMeetError_SessionError:
            message = @"Failed to create a session with our sever.";
            break;
        case MobileRTCMeetError_MeetingOver:
            message = @"The meeting is over.";
            break;
        case MobileRTCMeetError_MeetingNotStart:
            message = @"The meeting does not start.";
            break;
        case MobileRTCMeetError_MeetingNotExist:
            message = @"The meeting does not exist.";
            break;
        case MobileRTCMeetError_MeetingUserFull:
            message = @"The meeting has reached a maximum of participants.";
            break;
        case MobileRTCMeetError_MeetingClientIncompatible:
            message = @"The Zoom SDK version is incompatible.";
            break;
        case MobileRTCMeetError_NoMMR:
            message = @"No mmr is available at this point.";
            break;
        case MobileRTCMeetError_MeetingLocked:
            message = @"The meeting is locked by the host.";
            break;
        case MobileRTCMeetError_MeetingRestricted:
            message = @"The meeting is restricted.";
            break;
        case MobileRTCMeetError_MeetingRestrictedJBH:
            message = @"The meeting does not allow join before host. Please try again later.";
            break;
        case MobileRTCMeetError_CannotEmitWebRequest:
            message = @"Failed to send create meeting request to server.";
            break;
        case MobileRTCMeetError_CannotStartTokenExpire:
            message = @"Failed to start meeting due to token exipred.";
            break;
        case MobileRTCMeetError_VideoError:
            message = @"The user's video cannot work.";
            break;
        case MobileRTCMeetError_AudioAutoStartError:
            message = @"The user's audio cannot auto start.";
            break;
        case MobileRTCMeetError_RegisterWebinarFull:
            message = @"The webinar has reached its maximum allowed participants.";
            break;
        case MobileRTCMeetError_RegisterWebinarHostRegister:
            message = @"Sign in to start the webinar.";
            break;
        case MobileRTCMeetError_RegisterWebinarPanelistRegister:
            message = @"Join the webinar from the link";
            break;
        case MobileRTCMeetError_RegisterWebinarDeniedEmail:
            message = @"The host has denied your webinar registration.";
            break;
        case MobileRTCMeetError_RegisterWebinarEnforceLogin:
            message = @"The webinar requires sign-in with specific account to join.";
            break;
        case MobileRTCMeetError_ZCCertificateChanged:
            message = @"The certificate of ZC has been changed. Please contact Zoom for further support.";
            break;
        case MobileRTCMeetError_VanityNotExist:
            message = @"The vanity does not exist";
            break;
        case MobileRTCMeetError_JoinWebinarWithSameEmail:
            message = @"The email address has already been register in this webinar.";
            break;
        case MobileRTCMeetError_WriteConfigFile:
            message = @"Failed to write config file.";
            break;
        case MobileRTCMeetError_RemovedByHost:
            message = @"You have been removed by the host.";
            break;
        case MobileRTCMeetError_InvalidArguments:
            message = @"Invalid arguments.";
            break;
        case MobileRTCMeetError_InvalidUserType:
            message = @"Invalid user type.";
            break;
        case MobileRTCMeetError_InAnotherMeeting:
            message = @"Already in another ongoing meeting.";
            break;
        case MobileRTCMeetError_Unknown:
            message = @"Unknown error.";
            break;
        default:
            message = @"Unknown error.";
            break;
    }
    return message;
}

@end
