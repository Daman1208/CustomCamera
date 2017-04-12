//
//  CLToolbarMenuGroupIcon.h
//  SOLit
//
//  Created by Daman on 07/05/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLToolbarMenuGroupIcon : UIView
{
    UILabel *_titleLabel;
}

@property (nonatomic, assign) NSString *title;

- (id)initWithFrame:(CGRect)frame title:(NSString *)title;
@end
