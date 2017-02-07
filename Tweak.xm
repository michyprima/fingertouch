#include "Tweak.h"

static int touches = 0;
static int downStillValid;
static bool onGestureWasLocked = NO;

%hook SBDashBoardViewController

- (void)handleBiometricEvent:(unsigned long long)arg1 {
	%orig;
	
	FTSettings *fts = [FTSettings sharedInstance];
	
	if(fts.enabled) {
		if (arg1 == TouchIDFingerDown) {
			
			if(downStillValid==0)
				onGestureWasLocked = [[UIApplication sharedApplication] isLocked];
				
			[fts hapticFeedbackIfNeeded:NO];
			
			downStillValid++;
			BOOL touchAndHold = downStillValid == 2;
				
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, fts.dispatchTime), dispatch_get_main_queue(), ^{
				if(downStillValid) {
					if(touches == 0) {
						[FTSettings executeActionForCode:(fts.onhold)];
					} else if (touches == 1 && touchAndHold) {
						[FTSettings executeActionForCode:(fts.ontouchandhold)];
						touches = -1;
					}
					downStillValid--;
				}
			});
		} else if (arg1 == TouchIDFingerUp) {
		
			[fts hapticFeedbackIfNeeded:YES];
						
			if(downStillValid) {
				touches++;
			}
			
			int dt;
			
			if(fts.maxUPs == touches) {
				downStillValid--;
				dt = 0;
			} else {
				dt = fts.dispatchTime;
			}

			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, dt), dispatch_get_main_queue(), ^{
		    	if(!downStillValid) {
		    		switch(touches) {
		    			case 1:
		    				[FTSettings executeActionForCode:(fts.ontouch)];
		    				break;
		    			case 2:
		    				[FTSettings executeActionForCode:(fts.ondoubletouch)];
		    				break;
		    			case 3:
		    				[FTSettings executeActionForCode:(fts.ontripletouch)];
		    				break;
		    		}
		    		touches = 0;
		    	}
			});
		}
	}
}

%end

static BOOL reachabilityFromMe;
%hook SBReachabilityManager

+ (_Bool)reachabilitySupported {
	return YES;
}

- (void)_handleReachabilityActivated {
	if(reachabilityFromMe) {
		%orig;
		reachabilityFromMe = NO;
	}
}

-(void)setReachabilityEnabled:(BOOL)arg1 {
	%orig(YES);
}

-(void)setReachabilityTemporarilyDisabled:(BOOL)arg1 forReason:(id)arg2 {
	
}

%end

static FTSettings *_sharedInstance = nil;
static AVFlashlight *flashlight;
@implementation FTSettings

+(id) sharedInstance {
    @synchronized(self) {
        if (!_sharedInstance) {
            _sharedInstance = [[self alloc] init];
        }
        return _sharedInstance;
    }
}

-(id) init {
    if (self=[super init]) {
        [self loadPlist];
    }
    return self;
}

-(void) loadPlist {
	NSDictionary* prefs = nil;
	CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("it.dreamcode.ftp"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if(keyList) {
        prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, CFSTR("it.dreamcode.ftp"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFRelease(keyList);
    }

    if(prefs == nil) {
        self.enabled = YES;
        self.vibrate = YES;
        self.vibrateUp = NO;
        self.dispatchTime = 3 * 100000000;
        self.vibintensity = 0.3;
        self.ontouch = 1;
        self.onhold = 0;
        self.ondoubletouch = 2;
        self.ontripletouch = 3;
        self.ontouchandhold = 6;
        self.maxUPs = 3;
        return;
    }
    
    self.enabled = ([prefs objectForKey:@"enabled"] ? [[prefs objectForKey:@"enabled"] boolValue] : YES);
    self.vibrate = ([prefs objectForKey:@"vibenabled"] ? [[prefs objectForKey:@"vibenabled"] boolValue] : YES);
    self.vibrateUp = ([prefs objectForKey:@"vibenabledup"] ? [[prefs objectForKey:@"vibenabledup"] boolValue] : NO);
    self.vibintensity = ([prefs objectForKey:@"vibintensity"] ? [[prefs objectForKey:@"vibintensity"] doubleValue] : 3.0f)/10;
    self.dispatchTime = ([prefs objectForKey:@"gesturespeed"] ? [[prefs objectForKey:@"gesturespeed"] intValue] : 3)*100000000;
    self.ontouch = ([prefs objectForKey:@"ontouch"] ? [[prefs objectForKey:@"ontouch"] intValue] : 1);
    self.onhold = ([prefs objectForKey:@"onhold"] ? [[prefs objectForKey:@"onhold"] intValue] : 0);
    self.ondoubletouch = ([prefs objectForKey:@"ondoubletouch"] ? [[prefs objectForKey:@"ondoubletouch"] intValue] : 2);
    self.ontripletouch = ([prefs objectForKey:@"ontripletouch"] ? [[prefs objectForKey:@"ontripletouch"] intValue] : 3);
    self.ontouchandhold = ([prefs objectForKey:@"ontouchandhold"] ? [[prefs objectForKey:@"ontouchandhold"] intValue] : 6);
    
    if(self.ontripletouch != -1)
    	self.maxUPs = 3;
    else if(self.ondoubletouch != -1 || self.ontouchandhold != -1)
    	self.maxUPs = 2;
    else
    	self.maxUPs = 1;
}

-(void)hapticFeedbackIfNeeded:(BOOL)isUP {
	if(isUP ? self.vibrateUp : self.vibrate)
		AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, @{ @"Intensity": @(self.vibintensity), @"VibePattern": @[ @YES, @10 ]});
}

+(void)executeActionForCode:(int)code {
	@try {
		switch(code) {
			case 0:
				[FTSettings simulateLockButton:NO];
				break;
			case 1:
				[FTSettings simulateHomeButton];
				break;
			case 2:
				[FTSettings toggleSwitcher];
				break;
			case 3:
				[FTSettings toggleFlashLight];
				break;
			case 4:
				[FTSettings makeScreenshot];
				break;
			case 5:
				[FTSettings toggleReachability];
				break;
			case 6:
				[FTSettings switchToLastApp];
				break;
			case 7:
				[FTSettings toggleVirtualAssistant];
				break;
			case 8:
				[FTSettings toggleRotationLock];
				break;
			case 9:
				[FTSettings bringUpControlCenter];
				break;
			case 10:
				[FTSettings simulateLockButton:YES];
				break;
			case 11:
				[FTSettings toggleNotificationCenter];
				break;
		}
	} @catch (NSException *exception) {
#ifdef DEBUG
		NSLog(@"executeActionForCode error: %@", exception.reason);
#endif
    }
}

+(void)toggleReachability {
	reachabilityFromMe = YES;
	[[%c(SBReachabilityManager) sharedInstance] toggleReachability];
}

+(void)makeScreenshot {
	[[UIApplication sharedApplication].screenshotManager saveScreenshotsWithCompletion:nil];
}

+(void)toggleSwitcher {
	[[%c(SBMainSwitcherViewController) sharedInstance] toggleSwitcherNoninteractively];
}

+(void)simulateHomeButton {
	[[UIApplication sharedApplication] _simulateHomeButtonPress];
}

+(void)simulateLockButton:(BOOL)onlyIfNotLocked {
	UIApplication *app = [UIApplication sharedApplication];
	if(!onlyIfNotLocked || !onGestureWasLocked)
		[app _simulateLockButtonPress];
}

+(void)switchToLastApp {
	int dest = [[UIApplication sharedApplication] _accessibilityFrontMostApplication] ? 1 : 0;
	NSArray *displayItems = [[NSClassFromString(@"SBAppSwitcherModel") sharedInstance] valueForKey:@"_recentDisplayItems"];
	if([displayItems count]>dest) {
		SBDisplayItem *displayItem = displayItems[dest];
		id appToLaunch = [[%c(SBApplicationController) sharedInstanceIfExists] applicationWithBundleIdentifier:displayItem.displayIdentifier];
		[[%c(SBUIController) sharedInstanceIfExists] activateApplication:appToLaunch];
	}
}

+(void)toggleFlashLight {
	if (flashlight == nil && [AVFlashlight hasFlashlight]) {
		flashlight = [AVFlashlight new];
		[flashlight setFlashlightLevel:1.0f withError:nil];
	} else {
		[flashlight turnPowerOff];
		[flashlight dealloc];
		flashlight = nil;
	}
}

+(void)toggleVirtualAssistant {
   AXSpringBoardServer *server = [%c(AXSpringBoardServer) server];
   if([server isSiriVisible]) {
   	[server dismissSiri];
   } else {
	[server openSiri];
   }
}

+(void)toggleRotationLock {
	SBOrientationLockManager *sblock = [%c(SBOrientationLockManager) sharedInstance];
	if([sblock isUserLocked]) {
		[sblock unlock];
	} else {
		[sblock lock];
	}
}

+(void)bringUpControlCenter {
	[[UIApplication sharedApplication] _bringUpControlCenter];
}

+(void)toggleNotificationCenter {
	SBNotificationCenterController *sbnc = [%c(SBNotificationCenterController) sharedInstanceIfExists];
	if([sbnc isVisible]) {
		[sbnc dismissAnimated:YES];
	} else {
		[sbnc presentAnimated:YES];
	}
}
@end

static void loadPreferences() {
#ifdef DEBUG
    NSLog(@"loadPreferences");
#endif
    [[FTSettings sharedInstance] loadPlist];
}

%ctor {
    %init;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPreferences, CFSTR("it.dreamcode.ftp.changes"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}