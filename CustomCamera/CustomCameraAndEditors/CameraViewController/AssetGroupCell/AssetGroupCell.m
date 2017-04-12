//
//  AssetGroupCell.m
//  Camera
//
//  Created by Daman on 11/04/17.
//  Copyright © 2017 Tarsem. All rights reserved.
//

#import "AssetGroupCell.h"

@implementation AssetGroupCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configureForGroup:(ALAssetsGroup *)group{
    CGImageRef posterImageRef = [group posterImage];
    UIImage *posterImage = [UIImage imageWithCGImage:posterImageRef];
    self.imgThumb.image = posterImage;
    self.lblGroupName.text = [group valueForProperty:ALAssetsGroupPropertyName];
    self.lblCount.text = [@(group.numberOfAssets) stringValue];
    
}


@end
