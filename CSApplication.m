//
//  CSApplication.m
//
//  Created by Kyle Howells on 06/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//////////////////////////////////////////
// 2 best methods, the SBIcon one will likely be gone with iOS 5.0 so I'm noting down the UIImage method. 
// UIImage *icon = [UIImage _applicationIconImageForBundleIdentifier:[app bundleIdentifier] roleIdentifier:[app roleIdentifier] format:0];
// "format:" & "getIconImage:" need an int. I think that they both use a typedef something like this.
/// (Note: must check the icons that are same size at some point to see if they really are the same)
/*
 * |	typedef enum {
 * |	    SBIconTypeSmall = 1,    // Settings icon (29*29)
 * |	    SBIconTypeLarge = 2,    // SpringBoard icon (59*62)
 * |	    SBIconTypeMedium = 3,   // Don't know? (43*43.5)
 * |	    SBIconTypeBig = 4,	    // SpringBoard icon again? (59*62)
 * |	    SBIconTypeMiddle = 5,   // Slightly bigger settings icon? (31*37)
 * |	    SBIconTypeMid = 6,	    // Same size as 5, might not be same though? (31*37)
 * |	    SBIconTypeError = 7     // Calling this gives an error ("[NSCFString size]: unrecognized selector")
 * |				    // Anything above 7 returns nil.
 * |	} SBIconType;
 */


/// SpringBoard headers
#import <SpringBoard4.0/SBAppSwitcherController.h>
#import <SpringBoard4.0/SBApplicationIcon.h>
#import <SpringBoard4.0/SBUIController.h>
#import <SpringBoard4.0/SBDisplayStack.h>
#import <SpringBoard4.0/SBApplication.h>
#import <SpringBoard4.0/SBIconBadge.h>
#import <SpringBoard4.0/SBIconModel.h>
#import <SpringBoard4.0/SBIcon.h>
#import "CSApplicationController.h"
#import <QuartzCore/QuartzCore.h>
#import "CSApplication.h"
#import "CSScrollView.h"
#import <UIKit/UIKit.h>
#import <substrate.h>

@interface SBApplication ()
-(int)suspensionType;
@end

@interface SBProccess : NSObject {}
-(void)resume;
@end

@interface SBIcon (PSText)
-(NSString*)_PSBadgeText;
@end


//#error TODO: Change over UI from the controller to seperate CSApplication objects.

#define APP self.application


@implementation CSApplication
@synthesize label = _label;
@synthesize icon = _icon;
@synthesize badge = _badge;
@synthesize appImage = _appImage;
@synthesize closeBox = _closeBox;
@synthesize snapshot = _snapshot;
@synthesize application = _application;


-(id)init{
    if ((self = [super initWithFrame:CGRectMake(0, 0, (SCREEN_WIDTH*0.625), [UIScreen mainScreen].bounds.size.height)])) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        self.clipsToBounds = NO;
        // Autoresizing masks
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.application = nil;
        self.appImage = nil;

        self.snapshot = [[[UIImageView alloc] init] autorelease];
        self.snapshot.backgroundColor = [UIColor clearColor];
        self.snapshot.frame = CGRectMake(0, (50*Y_SCALE), (SCREEN_WIDTH*0.625), (SCREEN_HEIGHT*0.625));
        self.snapshot.userInteractionEnabled = YES;
        self.snapshot.layer.masksToBounds = YES;
        self.snapshot.layer.cornerRadius = [CSResources cornerRadius];
        self.snapshot.layer.borderWidth = 1;
        self.snapshot.layer.borderColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
        [self addSubview:self.snapshot];

        UISwipeGestureRecognizer *swipeUp = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeGesture:)] autorelease];
        swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
        [self.snapshot addGestureRecognizer:swipeUp];

        UITapGestureRecognizer *singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchGesture:)] autorelease];
        [singleTap requireGestureRecognizerToFail:swipeUp];
        singleTap.numberOfTapsRequired = [CSResources tapsToLaunch];
        [self addGestureRecognizer:singleTap];

        self.icon = [[[UIImageView alloc] init] autorelease];
        self.icon.frame = CGRectMake(17, self.snapshot.frame.size.height + self.snapshot.frame.origin.y + 14, self.icon.frame.size.width, self.icon.frame.size.height);
        [self addSubview:self.icon];

        self.closeBox = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeBox.frame = CGRectMake(0, 0, 45, 45);
        self.closeBox.center = self.snapshot.frame.origin;
        [self.closeBox setImage:[CSApplicationController sharedController].closeBox forState:UIControlStateNormal];
        [self.closeBox addTarget:self action:@selector(quitPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBox];
        self.closeBox.hidden = ![CSResources showsCloseBox];
        
        CGRect labelRect;
        labelRect.origin.x = (self.icon.frame.origin.x + self.icon.frame.size.width + 12);
        labelRect.origin.y = self.icon.frame.origin.y;
        labelRect.size.width = (self.snapshot.frame.origin.x + self.snapshot.frame.size.width)-(self.icon.frame.size.width + self.icon.frame.origin.x + 10);
        labelRect.size.height = self.icon.frame.size.height;

        self.label = [[[UILabel alloc] initWithFrame:labelRect] autorelease];
        self.label.font = [UIFont boldSystemFontOfSize:17];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.numberOfLines = 0;
        self.label.text = @"Application";
        [self addSubview:self.label];
        self.label.hidden = ![CSResources showsAppTitle];


        [[CSApplicationController sharedController].scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:@selector(updateAlpha:)];
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@selector(updateAlpha:)];

        [pool release];
    }

    return self;
}

-(void)loadImages{
    if (self.appImage != nil)
        return;

    self.appImage = [CSResources cachedScreenShot:APP];
    self.snapshot.image = self.appImage;
}
-(void)reset{
    self.appImage = nil;
    self.snapshot.image = nil;
}

-(id)initWithApplication:(SBApplication*)application
{
    if ((self = [super initWithFrame:CGRectMake(0, 0, (SCREEN_WIDTH*0.625), [UIScreen mainScreen].bounds.size.height)])) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        self.clipsToBounds = NO;
        // Autoresizing masks
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.application = application;
        self.appImage = nil;

        self.snapshot = [[[UIImageView alloc] initWithFrame:CGRectMake(0, (50*Y_SCALE), (SCREEN_WIDTH*0.625), (SCREEN_HEIGHT*0.625))] autorelease];
        self.snapshot.backgroundColor = [UIColor clearColor];
        self.snapshot.userInteractionEnabled = YES;
        self.snapshot.layer.masksToBounds = YES;
        self.snapshot.layer.cornerRadius = [CSResources cornerRadius];
        self.snapshot.layer.borderWidth = 1;
        self.snapshot.layer.borderColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1].CGColor;
        [self addSubview:self.snapshot];

        UISwipeGestureRecognizer *swipeUp = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeGesture:)] autorelease];
        swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
        [self.snapshot addGestureRecognizer:swipeUp];

        UITapGestureRecognizer *singleTap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(launchGesture:)] autorelease];
        [singleTap requireGestureRecognizerToFail:swipeUp];
        singleTap.numberOfTapsRequired = [CSResources tapsToLaunch];
        [self addGestureRecognizer:singleTap];

        SBApplicationIcon *appIcon = [[objc_getClass("SBIconModel") sharedInstance] applicationIconForDisplayIdentifier:[APP displayIdentifier]];
        UIImage *icon = [appIcon getIconImage:3];
        self.icon = [[[UIImageView alloc] initWithImage:icon] autorelease];
        self.icon.frame = CGRectMake(17, self.snapshot.frame.size.height + self.snapshot.frame.origin.y + 14, self.icon.frame.size.width, self.icon.frame.size.height);
        [self addSubview:self.icon];

        if ([appIcon hasBadge]) {
            self.badge = [objc_getClass("SBIconBadge") iconBadgeWithBadgeString:[appIcon _PSBadgeText]]; //[[appIcon badgeView] _PSBadgeText]];
            self.badge.center = CGPointMake((self.snapshot.frame.size.width - (self.badge.frame.size.width*0.2)), self.snapshot.frame.origin.y + (self.badge.frame.size.height*0.2));
            [self addSubview:self.badge];
        }

        self.closeBox = [UIButton buttonWithType:UIButtonTypeCustom];
        self.closeBox.frame = CGRectMake(0, 0, 45, 45);
        self.closeBox.center = self.snapshot.frame.origin;
        [self.closeBox setImage:[CSApplicationController sharedController].closeBox forState:UIControlStateNormal];
        [self.closeBox addTarget:self action:@selector(quitPressed) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.closeBox];
        self.closeBox.hidden = ![CSResources showsCloseBox];

        CGRect labelRect;
        labelRect.origin.x = (self.icon.frame.origin.x + self.icon.frame.size.width + 12);
        labelRect.origin.y = self.icon.frame.origin.y;
        labelRect.size.width = (self.snapshot.frame.origin.x + self.snapshot.frame.size.width)-(self.icon.frame.size.width + self.icon.frame.origin.x + 10);
        labelRect.size.height = self.icon.frame.size.height;

        self.label = [[[UILabel alloc] initWithFrame:labelRect] autorelease];
        self.label.font = [UIFont boldSystemFontOfSize:17];
        self.label.backgroundColor = [UIColor clearColor];
        self.label.textColor = [UIColor whiteColor];
        self.label.numberOfLines = 0;
        self.label.text = [APP displayName];
        [self addSubview:self.label];
        self.label.hidden = ![CSResources showsAppTitle];

        [self layoutIcon];

        [[CSApplicationController sharedController].scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:@selector(updateAlpha:)];
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:@selector(updateAlpha:)];

        [pool release];
    }

    return self;
}
-(void)layoutIcon{
    if (self.label.hidden) {
        self.icon.center = CGPointMake(self.center.x, self.icon.center.y);
        return;
    }


    int totalWidth = [self.label.text sizeWithFont:self.label.font forWidth:self.label.frame.size.width lineBreakMode:UILineBreakModeClip].width;
    totalWidth += (self.icon.frame.size.width + 12);
    int iconX = ((self.frame.size.width-totalWidth)*0.5)-10;
    int labelX = iconX + self.icon.frame.size.width + 8;

    self.icon.frame = CGRectMake(iconX, self.icon.frame.origin.y, self.icon.frame.size.width, self.icon.frame.size.height);
    self.label.frame = CGRectMake(labelX, self.label.frame.origin.y, self.label.frame.size.width, self.label.frame.size.height);
}


-(void)launch{
    [self.superview bringSubviewToFront:self];
    [self bringSubviewToFront:self.snapshot];
    [CSApplicationController sharedController].scrollView.userInteractionEnabled = NO;

    [UIView animateWithDuration:0.1 animations:^{
        self.badge.alpha = 0;
        self.closeBox.alpha = 0;
    }completion:^(BOOL finished){}];

    // But either way I want my custom animation.
    CGRect screenRect = self.frame;
    screenRect.size.width = SCREEN_WIDTH;
    screenRect.size.height = SCREEN_HEIGHT;
    screenRect.origin.x = -[CSApplicationController sharedController].scrollView.frame.origin.x - (([CSApplicationController sharedController].scrollView.frame.size.width-self.frame.size.width)*0.5);
    screenRect.origin.y = -[CSApplicationController sharedController].scrollView.frame.origin.y;

    if ([SBWActiveDisplayStack topApplication] != nil) {
        // An app is already open, so use the switcher animation, but first check if this is the same app.
        if (![[[SBWActiveDisplayStack topApplication] bundleIdentifier] isEqualToString:[APP bundleIdentifier]]) {
            [CSApplicationController sharedController].shouldAnimate = YES;
            [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] activateApplicationFromSwitcher:APP];
        }
    }
    else {
        //Else we are on SpringBoard
        [(SBUIController*)[objc_getClass("SBUIController") sharedInstance] activateApplicationAnimated:APP];
    }

    [UIView animateWithDuration:0.55 animations:^{
        self.snapshot.frame = screenRect;
        self.snapshot.layer.cornerRadius = 0;
    } completion:^(BOOL finished){
        [[CSApplicationController sharedController] setActive:NO animated:NO];
        [self sendSubviewToBack:self.snapshot];
    }];
}

-(void)exit{
    [self retain];

    //[[CSApplicationController sharedController].ignoreRelaunchID release], [CSApplicationController sharedController].ignoreRelaunchID = nil;
    //[CSApplicationController sharedController].ignoreRelaunchID = [APP.displayIdentifier retain];
    [[CSApplicationController sharedController] appQuit:APP];
    [self removeFromSuperview];


    //******************* Proper app quiting code thanks to 'jmeosbn' - start **************//
    int suspendType = [APP respondsToSelector:@selector(_suspensionType)] ? [APP _suspensionType] : [APP suspensionType];

    // Set app to terminate on suspend then call deactivate
    // Allows exiting root apps, even if already backgrounded,
    // but does not exit an app with active background tasks
    [APP setSuspendType:0];
    [APP deactivate];
    [[APP process] resume];

    // Restore previous suspend type
    [APP setSuspendType:suspendType];

    [APP performSelector:@selector(kill) withObject:nil afterDelay:2];
    //[[objc_getClass("SBAppSwitcherController") sharedInstance] _quitButtonHit:APP];

    //******************* Proper app quiting code thanks to 'jmeosbn' - end **************//

    [self release];


	//if ([self hasNativeBackgrounding]) {
	//	[APP kill];
	//}
    //else {
	//	UIApplication *sharedApp = [UIApplication sharedApplication];
	//	/*if ([sharedApp respondsToSelector:@selector(setBackgroundingEnabled:forDisplayIdentifier:)])
	//		[sharedApp setBackgroundingEnabled:NO forDisplayIdentifier:_displayIdentifier];*/
	//	if ([SBWActiveDisplayStack containsDisplay:APP]) {
	//		[APP setDeactivationSetting:0x2 flag:YES]; // animate
	//		[SBWActiveDisplayStack popDisplay:APP];
	//	} else {
	//		[APP setDeactivationSetting:0x2 flag:NO]; // don't animate
	//	}
	//	// Deactivate the application
	//	[APP setActivationSetting:0x2 flag:NO]; // don't animate
	//	[SBWSuspendingDisplayStack pushDisplay:APP];
	//}
}


-(void)quitPressed{
    [UIView animateWithDuration:0.2 animations:^{
        self.icon.alpha = 0;
        self.label.alpha = 0;
        self.badge.alpha = 0;
        self.closeBox.alpha = 0;
    } completion:^(BOOL finished){}];

    [UIView animateWithDuration:0.4 animations:^{
        self.snapshot.alpha = 0;
        self.snapshot.frame = CGRectMake(0, -self.snapshot.frame.size.height, self.snapshot.frame.size.width, self.snapshot.frame.size.height);
    } completion:^(BOOL finished){
        [self exit];
    }];
}


-(void)launchGesture:(UITapGestureRecognizer*)gesture{
    if (gesture.state != UIGestureRecognizerStateEnded)
        return;

    [self launch];
}

-(void)closeGesture:(UIGestureRecognizer*)gesture{
    if (gesture.state != UIGestureRecognizerStateEnded || ![CSResources swipeCloses])
        return;

    [UIView animateWithDuration:0.2 animations:^{
        self.icon.alpha = 0;
        self.label.alpha = 0;
        self.badge.alpha = 0;
        self.closeBox.alpha = 0;
    } completion:^(BOOL finished){}];

    [UIView animateWithDuration:0.4 animations:^{
        self.snapshot.alpha = 0;
        self.snapshot.frame = CGRectMake(0, -self.snapshot.frame.size.height, self.snapshot.frame.size.width, self.snapshot.frame.size.height);
    } completion:^(BOOL finished){
        [self exit];
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self performSelector:(SEL)context withObject:change];
}

- (void)updateAlpha:(NSDictionary *)change {
    /*CGFloat offset = [CSApplicationController sharedController].scrollView.contentOffset.x;
    CGFloat origin = self.frame.origin.x;
    CGFloat delta = fabs(origin - offset);

    if (delta < self.frame.size.width) {
        self.alpha = 1 - delta/self.frame.size.width*0.8;
    } else {
        self.alpha = 0.3;
    }*/

    if ([[CSApplicationController sharedController].scrollView viewIsVisible:self]) {
        [self loadImages];
    }
    else {
        [self reset];
    }
}


-(void)dealloc{
    [[CSApplicationController sharedController].scrollView removeObserver:self forKeyPath:@"contentOffset"];

    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }

    self.application = nil;
    self.snapshot = nil;
    self.appImage = nil;
    self.closeBox = nil;
    self.badge = nil;
    self.label = nil;
    self.icon = nil;

    [super dealloc];
}


@end
