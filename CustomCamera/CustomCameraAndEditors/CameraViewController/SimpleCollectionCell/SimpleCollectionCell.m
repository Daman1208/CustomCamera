//
//  SimpleCollectionCell.m
//  Camera
//
//  Created by Daman on 11/04/17.
//  Copyright © 2017 Tarsem. All rights reserved.
//

#import "SimpleCollectionCell.h"
#import "UIImageView+WebCache.h"


#define kColorBlueTint [UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:225.0/255.0 alpha:1]

@implementation SimpleCollectionCell

-(void)awakeFromNib{
    [super awakeFromNib];
    if (self.showBorderOnSelection) {
        self.imgView.layer.borderColor = kColorBlueTint.CGColor;
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (self.showBorderOnSelection) {
        self.imgView.layer.borderWidth = selected ? 2 : 0;
    }
    
}

-(void)configureForPost:(NSString *)imageUrl{
    [self.imgView sd_setImageWithURL:[NSURL URLWithString:imageUrl]];
}

@end
