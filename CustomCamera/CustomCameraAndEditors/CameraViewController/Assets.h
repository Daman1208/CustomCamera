//
//  Assets.h
//  solit
//
//  Created by Damandeep Kaur on 18/02/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@interface Assets : NSObject{
    ALAssetsLibrary *library;
}
@property (nonatomic, strong) ALAssetsGroup *groupSelected;
@property (nonatomic, strong) NSMutableArray *assetsGroup;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, strong) PHCachingImageManager *imageManager;
+(instancetype)sharedInstance;
-(void)getAssetGroupsFromLibrary:(void(^)(NSArray * groups))groups;
-(void)getAssetsForGroup:(ALAssetsGroup *)group assets:(void(^)(NSArray *assets))assets;
@end
