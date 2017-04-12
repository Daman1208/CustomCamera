//
//  ProgressView.m
//  solit
//
//  Created by Damandeep Kaur on 20/02/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#import "ProgressView.h"

@implementation ProgressView
//@synthesize bezierPath;

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
//- (void)drawRect:(CGRect)rect {
//    // Drawing code
//    CGContextRef currentContext = UIGraphicsGetCurrentContext();
//    CGContextSetLineWidth(currentContext, 3.0);
//    CGContextSetStrokeColorWithColor(currentContext, [UIColor whiteColor].CGColor);
//    CGContextSetLineCap(currentContext, kCGLineCapRound);
//    CGContextSetLineJoin(currentContext, kCGLineJoinRound);
//    CGContextBeginPath(currentContext);
//    CGContextAddPath(currentContext, bezierPath.CGPath);
//    CGContextDrawPath(currentContext, kCGPathStroke);
//}
//
//- (void)addPathInRect:(CGRect)rectToRedraw{
//    self.bezierPath = [UIBezierPath bezierPathWithRect:rectToRedraw];
//    [self setNeedsDisplayInRect:rectToRedraw];
//}

- (void)setProgress:(NSNumber*)value{
    float to_value = [value floatValue];
    CGRect frame = self.frame;
    frame.size.width = to_value;
    self.frame = frame;
}

-(void)prepareToDelete{
    _canDelete = YES;
    [self setBackgroundColor:[UIColor redColor]];
}


@end
