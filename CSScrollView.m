//
//  CSScrollView.m
//
//
//  Created by Kyle Howells on 29/08/2011.
//  Copyright 2011 Howells Apps. All rights reserved.
//

#import "CSScrollView.h"

@implementation CSScrollView

-(BOOL)viewIsVisible:(UIView*)view{
    CGRect visibleRect;
    visibleRect.origin = self.contentOffset;
    visibleRect.size = self.bounds.size;
    visibleRect.origin.x -= 50;
    visibleRect.size.width += 100;

    return CGRectIntersectsRect(visibleRect, view.frame);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGPoint parentLocation = [self convertPoint:point toView:self.superview];
    /*CGRect responseRect = self.frame;
    responseRect.origin.x -= responseInsets.left;
    responseRect.origin.y -= responseInsets.top;
    responseRect.size.width += (responseInsets.left + responseInsets.right);
    responseRect.size.height += (responseInsets.top + responseInsets.bottom);
    return CGRectContainsPoint(responseRect, parentLocation);*/

    return [self.superview pointInside:parentLocation withEvent:event];
}

@end
