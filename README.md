The UI uses only public API's so shouldn't break with iOS5.

The potential breakpoints are.

## Methods used

    CGImageRef UIGetScreenImage(void);
    [[SBIconModel +sharedInstance] -applicationIconForDisplayIdentifier:ID];
    [SBIcon -getIconImage:3];
    [SBIconBadge +iconBadgeWithBadgeString:STRING];
    [SBApplication -defaultImage:NULL];
    [SBApplication -kill];
    GSSystemHasCapability(kGSMultitaskingCapability)     /// GraphicsServices.framework
    [[SBAwayController +sharedAwayController] -isLocked];

## Methods hooked

    [SBAppSwitcherController -applicationLaunched:APP]
    [SBAppSwitcherController -applicationDied:APP]
    [SBApplication -launch];
    [SBApplication -exitedCommon];
    [SBIcon -_PSBadgeText];    //Created new method to get the label's string (4.0-4.1 is different to 3.x and 4.2+)
    [SBAwayController -lock];

## And of cause the SBDisplayStack order

    #define SBWPreActivateDisplayStack        [displayStacks objectAtIndex:0]
    #define SBWActiveDisplayStack             [displayStacks objectAtIndex:1]
    #define SBWSuspendingDisplayStack         [displayStacks objectAtIndex:2]
    #define SBWSuspendedEventOnlyDisplayStack [displayStacks objectAtIndex:3]
    
    #define SBActive          ([SBWActiveDisplayStack topApplication] == nil)
