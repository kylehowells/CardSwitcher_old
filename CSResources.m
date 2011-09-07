//
//  CSResources.m
//  
//
//  Created by Kyle Howells on 22/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import <SpringBoard4.0/SBUIController.h>
#import <SpringBoard4.0/SBDisplayStack.h>
#import <SpringBoard4.0/SBApplication.h>
#import "CSApplicationController.h"
#import "CSResources.h"

CGImageRef UIGetScreenImage(void);

static NSMutableDictionary *cache = nil;
static NSDictionary *settings = nil;
static UIImage *currentImage = nil;

@implementation CSResources


+(UIImage*)currentAppImage{
    return currentImage;
}
+(void)setCurrentAppImage:(UIImage*)image{
    [currentImage release];
    currentImage = nil;
    currentImage = [image retain];
}


+(void)reset{
    [cache removeAllObjects];
    [currentImage release];
    currentImage = nil;
}

+(void)didReceiveMemoryWarning{
    [cache removeAllObjects];
    [cache release];
    cache = nil;
}


+(BOOL)cachScreenShot:(UIImage*)screenshot forApp:(SBApplication*)app{
    if (!cache)
        cache = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Caches/CardSwitcher/cache.plist"];
    if (!cache)
        cache = [[NSMutableDictionary alloc] init];

    [screenshot retain];

    [[NSFileManager defaultManager] createDirectoryAtPath:@"/User/Library/Caches/CardSwitcher" withIntermediateDirectories:YES attributes:nil error:nil];
    //NSString *pngPath = [NSString stringWithFormat:@"/User/Library/Caches/CardSwitcher/%@", [app displayIdentifier]];
    //BOOL success = [UIImagePNGRepresentation(screenshot) writeToFile:pngPath atomically:YES];

    //if (success)
        [cache setObject:screenshot forKey:[app displayIdentifier]];
        [cache writeToFile:@"/User/Library/Caches/CardSwitcher/cache.plist" atomically:YES];

    [screenshot release];

    return YES;
}

+(UIImage*)cachedScreenShot:(SBApplication*)app{
    if (currentImage && [[[SBWActiveDisplayStack topApplication] displayIdentifier] isEqualToString:[app displayIdentifier]]) {
        return currentImage;
    }

    if (!cache)
        cache = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/User/Library/Caches/CardSwitcher/cache.plist"];
    if (!cache)
        cache = [[NSMutableDictionary alloc] init];
    if (cache) {
        if ([cache objectForKey:[app displayIdentifier]])
            return [cache objectForKey:[app displayIdentifier]];
    }

    /*NSString *pngPath = [NSString stringWithFormat:@"/User/Library/Caches/CardSwitcher/%@", [app displayIdentifier]];
    UIImage *img = [UIImage imageWithContentsOfFile:pngPath];
    if (img) return img;*/

    return [self appScreenShot:app];
}

+(UIImage*)appScreenShot:(SBApplication*)app{
    if (!app)
        return nil;

    // If the app doesn't display the status bar (or a see through one) just return it's snapshot.
    if ([app defaultStatusBarHidden] || [app statusBarStyle] == UIStatusBarStyleBlackTranslucent) {
        UIImage *img = [app defaultImage:NULL];
        [self cachScreenShot:img forApp:app];
        return img;
    }

    // Else to avoid weirdness we need to render a fake status bar above the snapshot
    UIGraphicsBeginImageContext([UIScreen mainScreen].bounds.size);

    if ([app statusBarStyle] == UIStatusBarStyleBlackOpaque) {
        [[UIColor blackColor] set];
        UIRectFill([UIScreen mainScreen].bounds);
    }
    else {
        [[CSApplicationController sharedController].statusBarDefault drawInRect:CGRectMake(0, 0, SCREEN_WIDTH, 20)];
    }

    [[app defaultImage:NULL] drawInRect:CGRectMake(0, 20, SCREEN_WIDTH, SCREEN_HEIGHT-20)];

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self cachScreenShot:img forApp:app];
    return img;
}



#pragma mark Settings

+(BOOL)swipeCloses{
    id temp = [settings objectForKey:@"CSSwipeClose"];
	return (temp ? [temp boolValue] : YES);
}
+(BOOL)showsCloseBox{
    id temp = [settings objectForKey:@"CSShowCloseButtons"];
	return (temp ? [temp boolValue] : YES);
}
+(BOOL)showsAppTitle{
    id temp = [settings objectForKey:@"CSShowAppTitle"];
	return (temp ? [temp boolValue] : YES);
}
+(BOOL)showsPageControl{
    id temp = [settings objectForKey:@"CSShowPageDots"];
    return (temp ? [temp boolValue] : YES);
}
+(BOOL)autoBackgroundApps{
    id temp = [settings objectForKey:@"CSAutoBackground"];
    return (temp ? [temp boolValue] : NO);
}
+(int)cornerRadius{
    id temp = [settings objectForKey:@"CSCornerRadius"];
	return (temp ? [temp intValue] : 10);
}
+(int)tapsToLaunch{
    id temp = [settings objectForKey:@"CSTapsActivate"];
	return (temp ? [temp intValue] : 1);
}
+(int)backgroundStyle{
    id temp = [settings objectForKey:@"CSBackground"];
	return (temp ? [temp intValue] : 1);
}

+(void)reloadSettings{
    [settings release];
    settings = nil;
    settings = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.iky1e.cardswitcher.plist"];
}


@end
