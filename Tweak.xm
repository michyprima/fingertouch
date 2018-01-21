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
						[FTSettings executeActionForCode:(onGestureWasLocked ? fts.onholdlocked : fts.onhold)];
					} else if (touches == 1 && touchAndHold) {
						[FTSettings executeActionForCode:(onGestureWasLocked ? fts.ontouchandholdlocked : fts.ontouchandhold)];
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
		    				[FTSettings executeActionForCode:(onGestureWasLocked ? fts.ontouchlocked : fts.ontouch)];
		    				break;
		    			case 2:
		    				[FTSettings executeActionForCode:(onGestureWasLocked ? fts.ondoubletouchlocked : fts.ondoubletouch)];
		    				break;
		    			case 3:
		    				[FTSettings executeActionForCode:(onGestureWasLocked ? fts.ontripletouchlocked : fts.ontripletouch)];
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

-(BOOL)reachabilityEnabled {
	return YES;
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
	CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("it.dreamcode.ftp2"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if(keyList) {
        prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, CFSTR("it.dreamcode.ftp2"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
        CFRelease(keyList);
    }

    if(prefs == nil) {
        self.enabled = YES;
        self.vibrate = YES;
        self.vibrateUp = YES;
        self.dispatchTime = 3 * 100000000;
        self.vibintensity = 0.3;
        self.ontouch = 1;
        self.onhold = 0;
        self.ondoubletouch = 2;
        self.ontripletouch = 4;
        self.ontouchandhold = 6;
        self.ontouchlocked = 1;
        self.onholdlocked = -1;
        self.ondoubletouchlocked = -1;
        self.ontripletouchlocked = -1;
        self.ontouchandholdlocked = -1;
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
    self.ontripletouch = ([prefs objectForKey:@"ontripletouch"] ? [[prefs objectForKey:@"ontripletouch"] intValue] : 4);
    self.ontouchandhold = ([prefs objectForKey:@"ontouchandhold"] ? [[prefs objectForKey:@"ontouchandhold"] intValue] : 6);
    self.ontouchlocked = ([prefs objectForKey:@"ontouchlocked"] ? [[prefs objectForKey:@"ontouchlocked"] intValue] : 1);
    self.onholdlocked = ([prefs objectForKey:@"onholdlocked"] ? [[prefs objectForKey:@"onholdlocked"] intValue] : -1);
    self.ondoubletouchlocked = ([prefs objectForKey:@"ondoubletouchlocked"] ? [[prefs objectForKey:@"ondoubletouchlocked"] intValue] : -1);
    self.ontripletouchlocked = ([prefs objectForKey:@"ontripletouchlocked"] ? [[prefs objectForKey:@"ontripletouchlocked"] intValue] : -1);
    self.ontouchandholdlocked = ([prefs objectForKey:@"ontouchandholdlocked"] ? [[prefs objectForKey:@"ontouchandholdlocked"] intValue] : -1);
    
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
				[FTSettings simulateLockButton];
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
				[FTSettings toggleNotificationCenter];
				break;
			case 11:
				[FTSettings terminateCurrentApplication];
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
	if (kCFCoreFoundationVersionNumber < 1349.56)
		[[%c(SBMainSwitcherViewController) sharedInstance] toggleSwitcherNoninteractively];
	else
		[[%c(SBMainSwitcherViewController) sharedInstance] toggleSwitcherNoninteractivelyWithSource:0];
}

+(void)simulateHomeButton {
	[[UIApplication sharedApplication] _simulateHomeButtonPress];
}

+(void)simulateLockButton {
	UIApplication *app = [UIApplication sharedApplication];
	[app _simulateLockButtonPress];
}

+(void)switchToLastApp {
	int dest = [[UIApplication sharedApplication] _accessibilityFrontMostApplication] ? 1 : 0;
	
	if(kCFCoreFoundationVersionNumber < 1443.00) {
		NSArray *displayItems = [[NSClassFromString(@"SBAppSwitcherModel") sharedInstance] valueForKey:@"_recentDisplayItems"];
		if([displayItems count]>dest) {
			SBDisplayItem *displayItem = displayItems[dest];
			id appToLaunch = [[%c(SBApplicationController) sharedInstanceIfExists] applicationWithBundleIdentifier:displayItem.displayIdentifier];
			[[%c(SBUIController) sharedInstanceIfExists] activateApplication:appToLaunch];
		}
	} else {
		NSArray *displayItems = [[%c(SBRecentAppLayouts) sharedInstance] recents];
		if([displayItems count]>dest) {
			SBDisplayItem *displayItem = [displayItems[dest] allItems][0];
			id appToLaunch = [[%c(SBApplicationController) sharedInstanceIfExists] applicationWithBundleIdentifier:displayItem.displayIdentifier];
			[[%c(SBUIController) sharedInstanceIfExists] _activateApplicationFromAccessibility:appToLaunch];
		}
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

+(void)terminateCurrentApplication {
	SBApplication *app = [[UIApplication sharedApplication] _accessibilityFrontMostApplication];
	if(app && BKSTerminateApplicationForReasonAndReportWithDescription)
		BKSTerminateApplicationForReasonAndReportWithDescription([app bundleIdentifier], 1, 0, 0);
}
@end

static void loadPreferences() {
#ifdef DEBUG
    NSLog(@"loadPreferences");
#endif
    [[FTSettings sharedInstance] loadPlist];
}

%ctor {
	void *bk = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_LAZY);
	if (bk)
		BKSTerminateApplicationForReasonAndReportWithDescription = (int (*)(NSString*, int, int, int))dlsym(bk, "BKSTerminateApplicationForReasonAndReportWithDescription");
		
    %init;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPreferences, CFSTR("it.dreamcode.ftp.changes"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}