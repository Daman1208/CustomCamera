//
//  PhotoLibraryViewController.m
//  solit
//
//  Created by Damandeep Kaur on 19/02/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#import "PhotoLibraryViewController.h"
//#import "ArrayDataSource.h"
#import "AssetGroupCell.h"
#import "SimpleCollectionCell.h"
#import "UICollectionView+Convenience.h"

static CGSize AssetGridThumbnailSize;

@interface PhotoLibraryViewController ()<UITableViewDataSource, UITableViewDelegate, PHPhotoLibraryChangeObserver>
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property CGRect previousPreheatRect;
@property (nonatomic, assign) BOOL playingHint;
@property NSIndexPath *selectedIndexPath;

@end

@implementation PhotoLibraryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.tableViewLibrary registerNib:[UINib nibWithNibName:NSStringFromClass([AssetGroupCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([AssetGroupCell class])];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([SimpleCollectionCell class]) bundle:nil] forCellWithReuseIdentifier:NSStringFromClass([SimpleCollectionCell class])];
   // [self.collectionView registerClass:[SimpleCollectionCell class] forCellWithReuseIdentifier:NSStringFromClass([SimpleCollectionCell class])];
    self.imageManager = [[PHCachingImageManager alloc] init];
    [self resetCachedAssets];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    [self setupView];
    [self.tableViewLibrary setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self updateCachedAssets];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self updateSelectedAsset];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

-(void)setupView{
    self.collectionFetchResults = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    self.tableViewLibrary.dataSource = self;
    self.tableViewLibrary.delegate = self;
    [self.tableViewLibrary reloadData];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cellSize = CGSizeMake((SCREEN_WIDTH/4.0)-1.0, (SCREEN_WIDTH/4.0)-1.0);
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
    [self.collectionView reloadData];
    if (self.collectionFetchResults.count > 0) {
        //It will call delegate in subclass first
        int i=0;
        int oldCount = 0;
        int index = 0;
        for (PHCollection *coll in self.collectionFetchResults) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)coll;
            PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
            NSUInteger count = [assetsFetchResult count];
            if ([coll.localizedTitle isEqualToString:@"Camera Roll"] && count>0) {
                [self tableView:self.tableViewLibrary didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                break;
            }
            else{
                
                if (count > oldCount) {
                    oldCount = (int)count;
                    index = i;
                }
            }
            i++;
        }
        
        //If camera roll not loaded
        if (i == self.collectionFetchResults.count) {
            [self tableView:self.tableViewLibrary didSelectRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        }
    }
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.collectionFetchResults.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AssetGroupCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AssetGroupCell class]) forIndexPath:indexPath];
    PHCollection *collection = self.collectionFetchResults[indexPath.row];
    cell.lblGroupName.text = collection.localizedTitle;
    [cell.contentView setBackgroundColor:kAppThemeColor];
    if ([collection isKindOfClass:[PHAssetCollection class]]) {
        PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
        PHFetchResult *assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:nil];
        cell.lblCount.text = [@([assetsFetchResult count]) stringValue];
        PHAsset *asset = [assetsFetchResult lastObject];
        if (asset) {
            cell.representedAssetIdentifier = asset.localIdentifier;
            // Request an image for the asset from the PHCachingImageManager.
            [self.imageManager requestImageForAsset:asset
                                         targetSize:AssetGridThumbnailSize
                                        contentMode:PHImageContentModeAspectFill
                                            options:nil
                                      resultHandler:^(UIImage *result, NSDictionary *info) {
                                          // Set the cell's thumbnail image if it's still showing the same asset.
                                          if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                              cell.imgThumb.image = result;
                                          }
                                      }];
        }
        else{
            cell.imgThumb.image = [UIImage imageNamed:@"cameraroll_default"];
        }
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    _selectedIndexPath = indexPath;
    if(self.collectionFetchResults.count == 0) return;
    PHCollection *collection = self.collectionFetchResults[indexPath.row];
    [self loadCollection:collection];
}

-(void)loadCollection:(PHCollection *)collection{
    if ([collection isKindOfClass:[PHAssetCollection class]]) {
        PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
        
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
//        options.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d",PHAssetMediaTypeImage];
        
        _assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
        _assetCollection = assetCollection;
    }
    [self.collectionView reloadData];
    if (self.assetsFetchResults.count > 0) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionTop];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
    else{
        [self.cropperView setOriginalImage:[UIImage new]];
    }

}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    /*
     Change notifications may be made on a background queue. Re-dispatch to the
     main queue before acting on the change as we'll be updating the UI.
     */
    dispatch_async(dispatch_get_main_queue(), ^{
        PHFetchResultChangeDetails *changeDetails = [changeInstance changeDetailsForFetchResult:self.collectionFetchResults];
        if (changeDetails != nil) {
            self.collectionFetchResults = [changeDetails fetchResultAfterChanges];
            [self.tableViewLibrary reloadData];
        }
        PHFetchResultChangeDetails *changeDetails1 = [changeInstance changeDetailsForFetchResult:_assetsFetchResults];
        if (changeDetails1 != nil) {
            self.collectionFetchResults = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            [self.tableViewLibrary reloadData];
            if(self.collectionFetchResults.count == 0) return;
            PHCollection *collection = self.collectionFetchResults[_selectedIndexPath.row];
            [self loadCollection:collection];
        }
    });
}

#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.assetsFetchResults.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    SimpleCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([SimpleCollectionCell class]) forIndexPath:indexPath];
    cell.showBorderOnSelection = YES;
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    cell.representedAssetIdentifier = asset.localIdentifier;
    
    // Add a badge to the cell if the PHAsset represents a Live Photo.
    if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
        // Add Badge Image to the cell to denote that the asset is a Live Photo.
        UIImage *badge = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
        cell.imgView.image = badge;
    }
    // Request an image for the asset from the PHCachingImageManager.
    [self.imageManager requestImageForAsset:asset
                                 targetSize:AssetGridThumbnailSize
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  // Set the cell's thumbnail image if it's still showing the same asset.
                                  if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                      cell.imgView.image = result;
                                  }
                              }];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake((SCREEN_WIDTH/4.0)-1.0, (SCREEN_WIDTH/4.0)-1.0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    PHAsset *asset = self.assetsFetchResults[indexPath.item];
    self.assetEditing = asset;
    [self updateSelectedAsset];
}

-(void)updateSelectedAsset{
    if (self.player) {
        [self.player stop];
    }
    
    // Check the asset's `mediaSubtypes` to determine if this is a live photo or not.
    BOOL assetHasLivePhotoSubType = (self.assetEditing.mediaSubtypes & PHAssetMediaSubtypePhotoLive);
    if (assetHasLivePhotoSubType) {
        //[self updateLiveImage];
        [self updateStaticImage];
    }
    else {
        //For video and image
        [self updateStaticImage];
    }

    // Set the appropriate toolbarItems based on the mediaType of the asset.
    if (self.assetEditing.mediaType == PHAssetMediaTypeVideo) {
        [self.btnPreviewVideo setHidden:NO];
        [self.btnMuteVideo setHidden:NO];
        [self.btnMusicPicker setHidden:NO];
        [self.btnMuteVideo setSelected:NO];
    } else {
        [self.btnPreviewVideo setHidden:YES];
        [self.btnMuteVideo setHidden:YES];
        [self.btnMusicPicker setHidden:YES];
    }
}

- (void)updateStaticImage{
    if (!self.assetEditing) {
        return;
    }
    
    [self.viewVideo setHidden:YES];
    [self.livePhotoView setHidden:YES];
    
    // Prepare the options to pass when fetching the live photo.
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        /*
         Progress callbacks may not be on the main thread. Since we're updating
         the UI, dispatch to the main queue.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
           // self.progressView.progress = progress;
        });
    };
    
    [[PHImageManager defaultManager] requestImageForAsset:self.assetEditing targetSize:[self targetSize] contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        // Hide the progress view now the request has completed.
        //self.progressView.hidden = YES;
        
        // Check if the request was successful.
        if (!result) {
            return;
        }
        
        // Show the UIImageView and use it to display the requested image.
        //[self showStaticPhotoView];
        self.originalSelectedImage = result;
        [self.cropperView setOriginalImage:result];
        
//        
//       // CGImageSourceRef source = CGImageSourceCreateWithURL( (CFURLRef) aUrl, NULL);
//        CGImageSourceRef source = CGImageSourceCreateWithData( (CFDataRef) UIImagePNGRepresentation(result), NULL);
//        CFDictionaryRef dictRef = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
//        NSDictionary* metadata = (__bridge NSDictionary *)dictRef;
//        
//        CFRelease(source); CFRelease(dictRef);
    }];
}

- (void)updateLiveImage{
    if (!self.assetEditing) {
        return;
    }
    
    [self.viewVideo setHidden:YES];
    // Prepare the options to pass when fetching the live photo.
    PHLivePhotoRequestOptions *livePhotoOptions = [[PHLivePhotoRequestOptions alloc] init];
    livePhotoOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    livePhotoOptions.networkAccessAllowed = YES;
    livePhotoOptions.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        /*
         Progress callbacks may not be on the main thread. Since we're updating
         the UI, dispatch to the main queue.
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            //self.progressView.progress = progress;
        });
    };
    
    // Request the live photo for the asset from the default PHImageManager.
    [[PHImageManager defaultManager] requestLivePhotoForAsset:self.assetEditing targetSize:[self targetSize] contentMode:PHImageContentModeAspectFit options:livePhotoOptions resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        // Hide the progress view now the request has completed.
        //self.progressView.hidden = YES;
        
        // Check if the request was successful.
        if (!livePhoto) {
            return;
        }
        
        
        NSLog (@"Got a live photo");
        
        // Show the PHLivePhotoView and use it to display the requested image.
        [self.livePhotoView setHidden:NO];

        self.livePhotoView.livePhoto = livePhoto;
        
        if (![info[PHImageResultIsDegradedKey] boolValue] && !self.playingHint) {
            // Playback a short section of the live photo; similar to the Photos share sheet.
            NSLog (@"playing hint...");
            self.playingHint = YES;
            [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleHint];
        }
        
        // Update the toolbar to show the correct items for a live photo.
        [self.btnPreviewVideo setHidden:NO];
    }];
}


#pragma mark - PHLivePhotoViewDelegate Protocol Methods.

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView willBeginPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    NSLog(@"Will Beginning Playback of Live Photo...");
}

- (void)livePhotoView:(PHLivePhotoView *)livePhotoView didEndPlaybackWithStyle:(PHLivePhotoViewPlaybackStyle)playbackStyle {
    NSLog(@"Did End Playback of Live Photo...");
    self.playingHint = NO;
}

- (IBAction)prewVideo:(id)sender{
    if (!self.assetEditing) {
        return;
    }
    [self.btnPreviewVideo setHidden:YES];
    if (self.livePhotoView.livePhoto != nil) {
        // We're displaying a live photo, begin playing it.
        [self.livePhotoView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
    }
    else {
        // Request an AVAsset for the PHAsset we're displaying.
        [[PHImageManager defaultManager] requestAVAssetForVideo:self.assetEditing options:nil resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.viewVideo setHidden:NO];
                [self.livePhotoView setHidden:YES];
                [self createVideoPlayer:((AVURLAsset *)avAsset).URL];                
            });
        }];
    }

}

- (void)createVideoPlayer:(NSURL *)url
{
    if (self.player) {
        [self.player stop];
        [self.player.view removeFromSuperview];
    }
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    self.player = [[MPMoviePlayerController alloc] initWithContentURL:url];
    self.player.view.frame = self.viewCropperContainer.bounds;
    [self.player setControlStyle:MPMovieControlStyleNone];
    self.player.shouldAutoplay = NO;
    self.player.repeatMode = MPMovieRepeatModeOne;
    self.player.scalingMode = MPMovieScalingModeAspectFill;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:self.player];
    [self.viewVideo addSubview:self.player.view];
    [self.viewVideo layoutIfNeeded];
    [self.player play];
}

#pragma mark - movie player delegates

- (void)moviePlayBackDidFinish:(NSNotification *)notification{

}


-(CGSize)targetSize{
    return CGSizeMake(2*SCREEN_WIDTH, 2*SCREEN_WIDTH);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Update cached assets for the new visible area.
    [self updateCachedAssets];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = self.assetsFetchResults[indexPath.item];
        [assets addObject:asset];
    }
    
    return assets;
}


@end
