//
//  ALAssetsLibrary category to handle a custom photo album
//
//  Created by Marin Todorov on 10/26/11.
//  Copyright (c) 2011 Marin Todorov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

typedef void(^SaveImageCompletion)(NSError* error);
typedef void(^SaveImageUrl)(NSURL* url);

@interface ALAssetsLibrary(CustomPhotoAlbum)

-(void)saveImage:(UIImage*)image toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock imageUrl:(SaveImageUrl)url;
-(void)saveVideo:(NSURL*)videoUrl toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock imageUrl:(SaveImageUrl)url;
-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName withCompletionBlock:(SaveImageCompletion)completionBlock imageUrl:(SaveImageUrl)url;

@end