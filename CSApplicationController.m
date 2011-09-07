//
//  CSApplicationController.m
//  
//
//  Created by Kyle Howells on 21/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <SpringBoard4.0/SBUIController.h>
#import <SpringBoard4.0/SBDisplayStack.h>
#import <SpringBoard4.0/SBApplication.h>
#import "CSApplicationController.h"
#import "CSApplication.h"
#import "CSResources.h"


CGImageRef UIGetScreenImage(void);


@interface SBAwayController : NSObject {}
+(id)sharedAwayController;
-(BOOL)isLocked;
@end

@interface SBWallpaperView : UIImageView {}
-(UIImage*)uncomposedImage;
@end

@interface SpringBoard (Backgrounder)
- (void)setBackgroundingEnabled:(BOOL)backgroundingEnabled forDisplayIdentifier:(NSString *)displayIdentifier;
@end



static CSApplicationController *_instance;

@implementation CSApplicationController
@synthesize springBoardImage = _springBoardImage;
@synthesize ignoreRelaunchID = _ignoreRelaunchID;
@synthesize statusBarDefault = _statusBarDefault;
@synthesize displayStacks = _displayStacks;
@synthesize shouldAnimate = _shouldAnimate;
@synthesize isAnimating = _isAnimating;
@synthesize springBoard = _springBoard;
@synthesize runningApps = _runningApps;
@synthesize ignoredApps = _ignoredApps;
@synthesize ignoredIDs = _ignoredIDs;
@synthesize scrollView = _scrollView;
@synthesize closeBox = _closeBox;
@synthesize isActive = _isActive;

+(CSApplicationController*)sharedController{
    if (!_instance) {
        _instance = [[CSApplicationController alloc] init];
    }

    return _instance;
}

- (id)init {
    if ((self = [super initWithFrame:[UIScreen mainScreen].bounds])) {
        // Initialization code here.
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        self.closeBox = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CardSwitcher/closebox.png"];
        self.statusBarDefault = [UIImage imageWithContentsOfFile:@"/Library/Application Support/CardSwitcher/UIStatusBarStyleDefault.png"];
        self.backgroundColor = [UIColor blackColor];
        self.windowLevel = UIWindowLevelStatusBar*42;
        self.shouldAnimate = NO;
        self.isAnimating = NO;
        self.isActive = NO;
        self.hidden = YES;
        self.displayStacks = [[[NSMutableArray alloc] init] autorelease];
        self.runningApps = [[[NSMutableArray alloc] init] autorelease];
        self.ignoredApps = [[[NSMutableArray alloc] init] autorelease];
        self.ignoredIDs = nil;
        //[NSMutableArray arrayWithObjects:@"com.apple.mobileipod-MediaPlayer", @"com.apple.mobilephone", @"com.apple.mobilemail", @"com.apple.mobilesafari", nil];

        pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0.0f, self.frame.size.height - 28.0f, self.frame.size.width, 20.0f)];
        pageControl.userInteractionEnabled = NO;
        pageControl.numberOfPages = 1;
        pageControl.currentPage = 1;
        [self addSubview:pageControl];

        int edgeInset = 40;
        CGRect scrollViewFrame = self.bounds;
        scrollViewFrame.size.width = (self.bounds.size.width-(edgeInset*2));
        scrollViewFrame.origin.x = edgeInset;
        self.scrollView = [[[CSScrollView alloc] initWithFrame:scrollViewFrame] autorelease];
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.alwaysBounceHorizontal = YES;
        self.scrollView.pagingEnabled = YES;
        self.scrollView.clipsToBounds = NO;
        self.scrollView.scrollsToTop = NO;
        self.scrollView.delegate = self;
        [self addSubview:self.scrollView];

        noAppsLabel = nil;
        backgroundView = nil;
        [CSResources reloadSettings];

        UISwipeGestureRecognizer *downSwipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(deactivateGesture:)] autorelease];
        downSwipe.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:downSwipe];

        //UIPinchGestureRecognizer *pinch = [[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomOut:)] autorelease];
        //[self addGestureRecognizer:pinch];

        /*CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor], (id)[[UIColor colorWithRed:0.171 green:0.171 blue:0.171 alpha:1.000] CGColor], nil];
        [self.layer insertSublayer:gradient atIndex:0];*/

        currentOrientation = UIInterfaceOrientationPortrait;

        [pool release];
    }

    return self;
}

-(void)setHidden:(BOOL)_hidden{
    self.userInteractionEnabled = !_hidden;
    [super setHidden:_hidden];
}


-(void)setRotation:(UIInterfaceOrientation)orientation{
/*    if (currentOrientation == orientation) return;

    if (orientation == UIInterfaceOrientationPortrait) {
        self.transform = CGAffineTransformRotate(self.transform,0.0);
    }
    else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
        self.transform = CGAffineTransformRotate(self.transform, 3.1415927);
    }*/
}

-(void)relayoutSubviews{
    //Defaults
    pageControl.hidden = ![CSResources showsPageControl];

    self.backgroundColor = [UIColor blackColor];

    [backgroundView removeFromSuperview];
    backgroundView = nil;
    if ([CSResources backgroundStyle] == 2) {
        backgroundView = [[[UIImageView alloc] initWithFrame:self.frame] autorelease];
        backgroundView.image = [[(SBUIController*)[objc_getClass("SBUIController") sharedInstance] wallpaperView] image];
        [self insertSubview:backgroundView atIndex:0];
    }

    [noAppsLabel removeFromSuperview];
    noAppsLabel = nil;

    if ([self.runningApps count] == 0) {
        noAppsLabel = [[[UILabel alloc] initWithFrame:self.frame] autorelease];
        noAppsLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3];
        noAppsLabel.font = [UIFont boldSystemFontOfSize:17];
        noAppsLabel.textAlignment = UITextAlignmentCenter;
        noAppsLabel.textColor = [UIColor whiteColor];
        noAppsLabel.text = @"No Apps Running";
        [self addSubview:noAppsLabel];
        self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    }


    CGSize screenSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(screenSize.width * [self.runningApps count], screenSize.height);

    static int i; // Work around for using "for (* in *)" rather then "for (int i = 0; i < array.count; i++)"
    i = 0;
    for (SBApplication *app in self.runningApps) {
        CSApplication *csApp = [[[CSApplication alloc] initWithApplication:app] autorelease];
        CGRect appRect = csApp.frame;
        appRect.origin.x = (i * screenSize.width) + ((screenSize.width-appRect.size.width)*0.5);
        csApp.frame = appRect;
        csApp.tag = (i + 1000);
        [csApp reset];
        [self.scrollView addSubview:csApp];

        i++;
    }
}


-(CSApplication*)csAppforApplication:(SBApplication*)app{
    for (CSApplication *csApplication in self.scrollView.subviews) {
        if ([app.displayIdentifier isEqualToString:csApplication.application.displayIdentifier]) {
            return csApplication;
        }
    }

    return nil;
}


-(void)appLaunched:(SBApplication*)app{
    for (NSString *string in self.ignoredIDs) {
        if ([[app displayIdentifier] isEqualToString:string]){
            if (![self.ignoredApps containsObject:app]) {
                [self.ignoredApps addObject:app];
            }
            return;
        }
    }

    if (![self.runningApps containsObject:app]) {
        [self.runningApps addObject:app];
    }
}

-(void)appQuit:(SBApplication*)app{
    if ([self.ignoredApps containsObject:app]) {
        [self.ignoredApps removeObject:app];
        return;
    }
    if (![self.runningApps containsObject:app]) { return; }


    if (self.isActive) {
        // Remove from the screen
        CSApplication *appView = [self csAppforApplication:app];
        [appView removeFromSuperview];

        // And remove it from the array
        [self.runningApps removeObject:app];

        // Animate the ScrollView smaller
        [UIView animateWithDuration:0.2 animations:^{
            self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * self.runningApps.count, 0);
        } completion:^(BOOL finished){}];
        [self checkPages];

        // Animate the apps closer together
        CGSize screenSize = self.scrollView.frame.size;
        
        static int i; // Work around for using "for (* in *)" rather then "for (int i = 0; i < array.count; i++)"
        i = 0;
        for (CSApplication *psApp in self.scrollView.subviews) {
            psApp.tag = (1000+i);

            CGRect appRect = psApp.frame;
            appRect.origin.x = (i * screenSize.width) + ((screenSize.width-appRect.size.width)*0.5);
            [UIView animateWithDuration:0.2 animations:^{
                psApp.frame = appRect;
            } completion:^(BOOL finished){}];

            i++;
        }

        if (self.runningApps.count == 0) {
            [self setActive:NO];
        }

        return;
    }

    [self.runningApps removeObject:app];
}


-(void)deactivateGesture:(UIGestureRecognizer*)gesture{
    if (gesture.state != UIGestureRecognizerStateEnded)
        return;

    [self setActive:NO];
}


#pragma mark Active & deactive

- (void)setActive:(BOOL)active{
	[self setActive:active animated:YES];
}

- (void)setActive:(BOOL)active animated:(BOOL)animated{
    if (active == self.isActive || self.isAnimating) { return; } //We are already active/inactive 

	if (active)
        [self activateAnimated:animated];
	else
        [self deactivateAnimated:animated];
}

-(void)activateAnimated:(BOOL)animate{
    self.isActive = YES;

    self.layer.transform = CATransform3DIdentity;

    self.frame = [UIScreen mainScreen].bounds;

    [self checkPages];
    [self relayoutSubviews];
    [self checkPages];

    // Setup first then animation
    self.hidden = NO;
    self.alpha = 0.0f;
    self.isAnimating = YES;
    self.userInteractionEnabled = YES;
    self.scrollView.userInteractionEnabled = YES;
    self.layer.transform = CATransform3DMakeScale(3.5f, 3.5f, 1.0f);

    [UIView animateWithDuration:(animate ? 0.4 : 0.0) animations:^{
        self.alpha = 1;
        self.layer.transform = CATransform3DIdentity;
    } completion:^(BOOL finished){
        self.isAnimating = NO;
        [self checkPages];
        //if (spoke) { spoke = NO, [speaker startSpeakingString:@"Welcome to CardSwitcher"]; }
    }];
}

-(void)deactivateAnimated:(BOOL)animate{
    if (animate && !SBActive) {
        SBApplication *app = [SBWActiveDisplayStack topApplication];

        if ([SPRINGBOARD respondsToSelector:@selector(setBackgroundingEnabled:forDisplayIdentifier:)] && [CSResources autoBackgroundApps]){
			[SPRINGBOARD setBackgroundingEnabled:YES forDisplayIdentifier:app.displayIdentifier];
            
        }

        [app setDeactivationSetting:0x2 flag:NO];
        [SBWActiveDisplayStack popDisplay:app];
        [SBWSuspendingDisplayStack pushDisplay:app];
        app = nil;
    }

    self.isActive = NO;
    self.userInteractionEnabled = NO;
    self.scrollView.userInteractionEnabled = NO;
    self.layer.transform = CATransform3DIdentity;

    [self setRotation:[[UIDevice currentDevice] orientation]];

    [UIView animateWithDuration:(animate ? 0.4 : 0.0) animations:^{
        self.isAnimating = YES;
        self.layer.transform = CATransform3DMakeScale(2.5f, 2.5f, 1.0f);
        self.alpha = 0.0f;
    } completion:^(BOOL finished){
        self.hidden = YES;
        self.isAnimating = NO;

        [CSResources reset];

        for (UIView *view in self.scrollView.subviews) {
            [view removeFromSuperview];
        }


        [backgroundView removeFromSuperview];
        backgroundView = nil;

        [noAppsLabel removeFromSuperview];
        noAppsLabel = nil;
    }];
}



#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    [self checkPages];
    //#error SCRAPING 3 visibleApps and adding LAZY image loading.
}

-(void)checkPages{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = (floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth)) + 1;

    pageControl.numberOfPages = [self.runningApps count];
    pageControl.currentPage = page;

    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * pageControl.numberOfPages, 0);
}


#pragma mark libactivator delegate

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	if ([(SBAwayController*)[objc_getClass("SBAwayController") sharedAwayController] isLocked] || self.isAnimating)
		return;

    // Set the event handled
    [event setHandled:YES];
    BOOL newActive = ![self isActive];
    //[self setActive:newActive];

    // SpringBoard is active, just activate
    if (SBActive) {
        [self setActive:newActive];
        [self scrollViewDidScroll:self.scrollView];
        return;
    }

    CGImageRef screen = UIGetScreenImage();
    [CSResources setCurrentAppImage:[UIImage imageWithCGImage:screen]];
    CGImageRelease(screen);


    if (newActive && [[[SBWActiveDisplayStack topApplication] displayIdentifier] length]) {
        [self setActive:YES animated:NO];

        SBApplication *application = [SBWActiveDisplayStack topApplication];
        int index = [self.runningApps indexOfObject:application];
        [self.scrollView setContentOffset:CGPointMake((index*self.scrollView.frame.size.width), 0) animated:NO];
        [self scrollViewDidScroll:self.scrollView];

        self.scrollView.userInteractionEnabled = NO;

        CSApplication *psApp = [self csAppforApplication:application];
        UIImageView *snapshot = psApp.snapshot;

        float oldRadius = snapshot.layer.cornerRadius;
        snapshot.layer.cornerRadius = 0;

        CGRect targetRect = snapshot.frame;

        CGRect screenRect = psApp.frame;
        screenRect.size.width = SCREEN_WIDTH;
        screenRect.size.height = SCREEN_HEIGHT;
        screenRect.origin.x = -self.scrollView.frame.origin.x - ((self.scrollView.frame.size.width-psApp.frame.size.width)*0.5);
        screenRect.origin.y = -self.scrollView.frame.origin.y;
        snapshot.frame = screenRect;

        [self.scrollView bringSubviewToFront:psApp];
        [psApp bringSubviewToFront:psApp.snapshot];

        [UIView animateWithDuration:0.38 animations:^{
            snapshot.frame = targetRect;
            snapshot.layer.cornerRadius = oldRadius;
        } completion:^(BOOL finished){
            [psApp sendSubviewToBack:psApp.snapshot];
            self.scrollView.userInteractionEnabled = YES;
        }];
	}
    else {
        // Fancy animation
        [self setActive:NO];
    }
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event{
    if (self.isActive == NO || self.isAnimating) { return; }

    [self setActive:NO animated:NO];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event{
    if (self.isActive == NO || self.isAnimating) { return; }

    [event setHandled:YES];
    [self setActive:NO];
}


-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    for (UIView *view in self.scrollView.subviews) {
        [view removeFromSuperview];
    }
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    [noAppsLabel release], noAppsLabel = nil;
    [pageControl release], pageControl = nil;
    
    [super dealloc];
}

@end
