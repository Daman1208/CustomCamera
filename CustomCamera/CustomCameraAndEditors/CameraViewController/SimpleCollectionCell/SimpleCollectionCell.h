//
//  SimpleCollectionCell.h
//  Camera
//
//  Created by Daman on 11/04/17.
//  Copyright © 2017 Tarsem. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SimpleCollectionCell : UICollectionViewCell
@property (nonatomic) BOOL showBorderOnSelection;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (nonatomic, copy) NSString *representedAssetIdentifier;
-(void)configureForPost:(NSString *)imageUrl;
@end
