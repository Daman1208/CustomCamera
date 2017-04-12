//
//  Assets.m
//  solit
//
//  Created by Damandeep Kaur on 18/02/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#import "Assets.h"

@implementation Assets

+(instancetype)sharedInstance{
    static Assets *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Get Images from Gallery method

- (void)getAssetGroupsFromLibrary:(void(^)(NSArray * groups))groups{
    
    if (self.assetsGroup) {
        if(groups)
        groups(self.assetsGroup);
        return;
    }
    self.assetsGroup = [[NSMutableArray alloc] init];
    void (^assetsGroupEnumeration)(ALAssetsGroup *,BOOL *) = ^(ALAssetsGroup *group,BOOL *status){
        
        if(group!=nil)
        {
            [self.assetsGroup addObject:group];
        }
        else{
            if(groups)
                groups(self.assetsGroup);
        }
    };
    
    // allocate the library
    library = [[ALAssetsLibrary alloc]init];
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:assetsGroupEnumeration failureBlock:^(NSError *error) {
        NSLog(@"Error :%@", [error localizedDescription]);
    }];
    
//    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];

}

-(void)getAssetsForGroup:(ALAssetsGroup *)group assets:(void(^)(NSArray *assets))assets{
    if (!group) {
        return;
    }
    if (group == self.groupSelected) {
        if(assets)
            assets(self.assets);
        return;
    }
    self.groupSelected = group;
    self.assets = [[NSMutableArray alloc] init];
    ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            [self.assets addObject:result];
        }
        else{
            if(assets)
                assets(self.assets);
        }
    };
    //ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allPhotos];
    // [group setAssetsFilter:onlyPhotosFilter];
    [group enumerateAssetsUsingBlock:assetsEnumerationBlock];
    
}

@end
