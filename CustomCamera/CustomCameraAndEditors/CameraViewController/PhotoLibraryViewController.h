//
//  PhotoLibraryViewController.h
//  solit
//
//  Created by Damandeep Kaur on 19/02/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define kAppThemeColor [UIColor colorWithRed:38.0/255.0 green:39.0/255.0 blue:43.0/255.0 alpha:1]

//Post
#define kPostCaption @"caption"
#define kPostLatitude @"latitude"
#define kPostLongitude @"longitude"
#define kPostPrivate @"private"
#define kPostUser @"user"
#define kPostUsers @"users"
#define kPostVideo @"video"
#define kPostImage @"image"
#define kPostType @"type"
#define kPostSubType @"subType"
#define kMediaSource @"source"
#define vMediaSourceCamera @"camera"
#define vPostTypeImage @"image"
#define vPostTypeVideo @"video"
#define vPostTypeAudio @"audio"
#define kPostSubTypePanorama @"panorama"
#define kPostMyRate @"myRate"
#define kAverageRating @"averageRating"
#define kTotalRating @"totalRating"
#define kVideoData @"videoData"
#define kPostMyRateCount @"myRateCount"
#define kPostLocationTitle @"locationTitle"
#define kPostLocationAddress @"locationAddress"

// File
#define kFileName @"name"
#define kFileURL @"url"

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
#import "HIPImageCropperView.h"
#import <PhotosUI/PhotosUI.h>
//#import "ApiConstants.h"
#import <MediaPlayer/MediaPlayer.h>

@interface PhotoLibraryViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) PHAsset *assetEditing;
@property (weak, nonatomic) IBOutlet UIView *viewCrop;
@property (weak, nonatomic) IBOutlet UIView *viewCropperContainer;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UITableView *tableViewLibrary;
@property (nonatomic, strong) PHFetchResult *collectionFetchResults;
@property (weak, nonatomic) IBOutlet PHLivePhotoView *livePhotoView;
@property (weak, nonatomic) IBOutlet UIView *viewVideo;
@property (nonatomic, strong) PHFetchResult *assetsFetchResults;
@property (nonatomic, strong) PHCollection *assetCollection;
@property (nonatomic, strong) HIPImageCropperView *cropperView;
@property (weak, nonatomic) IBOutlet UIButton *btnPreviewVideo;
@property (nonatomic, strong) UIImage *originalSelectedImage;
@property (strong, nonatomic) IBOutlet UIButton *btnMuteVideo;
@property (strong, nonatomic) IBOutlet UIButton *btnMusicPicker;
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (IBAction)prewVideo:(id)sender;
@property (nonatomic, strong) MPMoviePlayerController *player;
@end
