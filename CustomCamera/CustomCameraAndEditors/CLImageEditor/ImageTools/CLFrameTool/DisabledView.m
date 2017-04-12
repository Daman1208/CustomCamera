//
//  DisabledView.m
//  SOLit
//
//  Created by Daman on 28/09/16.
//  Copyright © 2016 Bison. All rights reserved.
//

#import "DisabledView.h"

@implementation DisabledView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* view= [super hitTest:point withEvent:event];
    if(view==self || [self.subviews containsObject:view]){
        return nil;
    }
    return view;
}

@end
