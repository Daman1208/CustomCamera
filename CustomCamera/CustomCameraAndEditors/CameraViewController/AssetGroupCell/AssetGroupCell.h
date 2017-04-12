//
//  AssetGroupCell.h
//  Camera
//
//  Created by Daman on 11/04/17.
//  Copyright © 2017 Tarsem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
@interface AssetGroupCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imgThumb;
@property (weak, nonatomic) IBOutlet UILabel *lblGroupName;
@property (weak, nonatomic) IBOutlet UILabel *lblCount;
@property (strong, nonatomic) NSString *representedAssetIdentifier;
-(void)configureForGroup:(ALAssetsGroup *)group;
@end
