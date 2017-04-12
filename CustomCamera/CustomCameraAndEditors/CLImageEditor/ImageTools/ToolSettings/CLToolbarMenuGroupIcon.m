//
//  CLToolbarMenuGroupIcon.m
//  SOLit
//
//  Created by Daman on 07/05/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#import "CLToolbarMenuGroupIcon.h"
#import "CLImageEditorTheme+Private.h"

@implementation CLToolbarMenuGroupIcon

- (id)initWithFrame:(CGRect)frame title:(NSString *)title;
{
    self = [super initWithFrame:frame];
    if (self) {
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.height, frame.size.width)];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [CLImageEditorTheme toolbarGroupTextFont];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = title;
        _titleLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
        _titleLabel.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [self addSubview:_titleLabel];
        [self setBackgroundColor:[UIColor darkGrayColor]];
    }
    return self;
}

@end
