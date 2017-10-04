#define TouchIDFingerUp    0
#define TouchIDFingerDown  1
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDUnlocked    4
#define TouchIDNotMatched  10

#import <AudioToolbox/AudioServices.h>
FOUNDATION_EXTERN void AudioServicesStopSystemSound(SystemSoundID inSystemSoundID);
FOUNDATION_EXTERN void AudioServicesPlaySystemSoundWithVibration(unsigned long, objc_object*, NSDictionary*);

@interface SBScreenshotManager
-(void)saveScreenshotsWithCompletion:(/*^block*/id)arg1 ;
@end

@interface UIApplication (Z)
-(void)_bringUpControlCenter;
-(void)_simulateHomeButtonPress;
-(void)_simulateLockButtonPress;
-(void)_simulateHomeButtonPressWithCompletion:(/*^block*/id)arg1 ;
-(id)_accessibilityFrontMostApplication;
-(BOOL)isLocked;
@property (nonatomic,readonly) SBScreenshotManager * screenshotManager;
@end
@interface SBMainSwitcherViewController
+ (SBMainSwitcherViewController *)sharedInstance;
- (_Bool)toggleSwitcherNoninteractively;
@end

@interface SBReachabilityManager
+(id)sharedInstance;
-(void)toggleReachability;
@end

@interface SBUISound : NSObject
@property (assign,nonatomic) unsigned systemSoundID;
@property (nonatomic,retain) NSDictionary * vibrationPattern;
@property (assign,getter=isRepeating,nonatomic) BOOL repeats;
@end

@interface SBSoundController
+(id)sharedInstance;
-(BOOL)_playSystemSound:(id)arg1 ;
-(BOOL)stopAllSounds;
@end

@interface AVFlashlight : NSObject
@property (getter=isAvailable,nonatomic,readonly) BOOL available; 
@property (getter=isOverheated,nonatomic,readonly) BOOL overheated; 
@property (nonatomic,readonly) float flashlightLevel; 
+(void)initialize;
+(BOOL)hasFlashlight;
-(id)init;
-(void)dealloc;
-(void)_handleNotification:(id)arg1 payload:(id)arg2 ;
-(float)flashlightLevel;
-(void)_setupFlashlight;
-(void)_teardownFlashlight;
-(BOOL)isOverheated;
-(BOOL)turnPowerOnWithError:(id*)arg1 ;
-(void)turnPowerOff;
-(BOOL)setFlashlightLevel:(float)arg1 withError:(id*)arg2 ;
-(BOOL)isAvailable;
@end

@interface SBApplicationController
+(id)sharedInstanceIfExists;
-(id)runningApplications;
-(id)applicationWithBundleIdentifier:(id)arg1 ;
@end

@interface SBUIController
+(id)sharedInstanceIfExists;
-(void)activateApplication:(id)arg1 ;
@end

@interface SBApplication
-(id)bundleIdentifier;
@end

@interface SBDisplayItem : NSObject
@property (nonatomic,copy,readonly) NSString * displayIdentifier;
@end

@interface SBAssistantController
+(BOOL)supportedAndEnabled;
+(BOOL)shouldEnterAssistant;
-(void)dismissAssistantViewIfNecessary:(long long)arg1 ;
+(id)sharedInstance;
+(BOOL)isAssistantVisible;
+(void)activateVirtualAssistant;
@end

@interface AXSpringBoardServer
-(BOOL)openSiri;
-(BOOL)dismissSiri;
-(BOOL)isSiriVisible;
+(id)server;
@end

@interface SBOrientationLockManager
+(id)sharedInstance;
-(void)lock;
-(BOOL)isUserLocked;
-(void)unlock;
@end

@interface SBNotificationCenterController
+(id)sharedInstanceIfExists;
-(void)presentAnimated:(BOOL)arg1 ;
-(BOOL)isVisible;
-(void)dismissAnimated:(BOOL)arg1 ;
@end

@interface FTSettings : NSObject
@property BOOL vibrate;
@property BOOL vibrateUp;
@property BOOL enabled;
@property int dispatchTime;
@property double vibintensity;
@property int ontouch;
@property int onhold;
@property int ondoubletouch;
@property int ontripletouch;
@property int ontouchandhold;
@property int ontouchlocked;
@property int onholdlocked;
@property int ondoubletouchlocked;
@property int ontripletouchlocked;
@property int ontouchandholdlocked;
@property int maxUPs;
-(void) loadPlist;
+(id) sharedInstance;
-(void)hapticFeedbackIfNeeded:(BOOL)isUP;
+(void)executeActionForCode:(int)code;
+(void)toggleReachability;
+(void)makeScreenshot;
+(void)toggleSwitcher;
+(void)simulateHomeButton;
+(void)simulateLockButton;
+(void)switchToLastApp;
+(void)toggleFlashLight;
+(void)toggleRotationLock;
+(void)bringUpControlCenter;
+(void)toggleNotificationCenter;
@end

static int (*BKSTerminateApplicationForReasonAndReportWithDescription)(NSString *displayIdentifier, int reason, int something, int something2);

static void loadPreferences();