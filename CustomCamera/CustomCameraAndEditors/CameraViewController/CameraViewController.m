//
//  CamreaViewController.m
//  solit
//
//  Created by Damandeep Kaur on 15/02/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//



#import "CameraViewController.h"
//#import "CustomMacros.h"
#import "Assets.h"
//#import "ArrayDataSource.h"
#import "AssetGroupCell.h"
//#import <PBJVision/PBJVision.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ProgressView.h"
//#import "PostViewController.h"
//#import "Utilities.h"
#import "CLImageEditor.h"
//#import "ColourConstants.h"
//#import <Localytics/Localytics.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "CurrentLocation.h"

#import <SCRecorder.h>
#import "SCTouchDetector.h"

#define kVideoPreset AVCaptureSessionPresetHigh

static float maxCaptureDuration = 30.0;

@interface CameraViewController ()<UIGestureRecognizerDelegate, UIVideoEditorControllerDelegate, UINavigationControllerDelegate,CLImageEditorDelegate,SCRecorderDelegate, SCAssetExportSessionDelegate,MPMediaPickerControllerDelegate>{
    ALAssetsLibrary *library;
    CGFloat beginOriginY;
    float current_value;
    float new_to_value;
    BOOL recording;
    CAShapeLayer *line;
    ProgressView *progressView;
    AVAssetExportSession *exporter;
    NSString* outputPath;
    
    SCRecorder *_recorder;
    SCRecordSession *_recordSession;
    UIImageView *_ghostImageView;
    BOOL closePressed;
    SCFlashMode photoFlashMode;
    SCFlashMode videoFlashMode;
}
@property (strong, nonatomic) SCRecorderToolsView *focusView;
@property (strong, nonatomic) SCAssetExportSession *exportSession;
@property (strong, nonatomic) NSDictionary *selectedMedia;
@property (nonatomic, strong) NSArray *assetsGroup;
@property (nonatomic, strong) NSArray *assets;
@property (nonatomic, strong) MPMoviePlayerController *player;
@property (strong, nonatomic) NSTimer *blinkTimer;
@end

@implementation CameraViewController
@synthesize player;

+(void)presentOnViewController:(UIViewController *)vc{
    CameraViewController *cameraVC = [[CameraViewController alloc] init];
    [cameraVC.view setFrame:[[UIScreen mainScreen] bounds]];
    UINavigationController *navCtrlr = [[UINavigationController alloc] initWithRootViewController:cameraVC];
    [navCtrlr setNavigationBarHidden:YES];
    [vc presentViewController:navCtrlr animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupUI];
    [self.scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:false];
    [self.scrollViewCamera setContentOffset:CGPointZero animated:self.scrollView.contentOffset.x > 0];
    [self resetCameraType:self.scrollView];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_viewTopBarGlobal setHidden:NO];
    [_viewTopBar setHidden:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    closePressed = NO;
    [self startPreview];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [_recorder previewViewFrameChanged];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [_recorder startRunning];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_recorder stopRunning];
    if(closePressed)
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)dealloc
{
    _recorder.previewView = nil;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(void)setupUI{
    
    //Initialization
    self.assetsGroup = [[NSMutableArray alloc] init];
    self.assets = [[NSMutableArray alloc] init];
    library = [[ALAssetsLibrary alloc] init];
   // [self.btnPreviewVideo setHidden:YES];

    //Configure crop view
    self.cropperView = [[HIPImageCropperView alloc]
                    initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)
                    cropAreaSize:CGSizeMake(SCREEN_WIDTH, SCREEN_WIDTH)
                    position:HIPImageCropperViewPositionCenter];
    __weak CameraViewController *weakSelf= self;
    [self.cropperView setScrollBeginDraggingBlock:^{
        weakSelf.scrollView.scrollEnabled = NO;
    }];
    [self.cropperView setScrollEndDraggingBlock:^{
        weakSelf.scrollView.scrollEnabled = YES;
    }];
    
    [self.cropperView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin |
                                          UIViewAutoresizingFlexibleRightMargin |
                                          UIViewAutoresizingFlexibleTopMargin |
                                          UIViewAutoresizingFlexibleBottomMargin)];
    [self.viewCropperContainer addSubview:self.cropperView];

    //Add gestures on library view
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    panGesture.delegate = self;
    [self.cropperView.scrollView addGestureRecognizer:panGesture];
    [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:panGesture];
    
    UIPanGestureRecognizer *panGesture2 = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureAction:)];
    [_dragView addGestureRecognizer:panGesture2];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [_dragView addGestureRecognizer:tapGesture];
    tapGesture.cancelsTouchesInView = NO;
    
    [tapGesture requireGestureRecognizerToFail:panGesture];
    
    //Select library
    [self library:nil];
    [self.btnLibrary setSelected:YES];
    
    //Camera
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    ([device hasTorch]) ? (self.btnFlash.hidden=NO) : (self.btnFlash.hidden=YES);
    [self initializeCamera];

}


-(void)panned:(UIGestureRecognizer *)ges{
}

- (void)panGestureAction:(UIPanGestureRecognizer *)panGesture {
    float maxOffset = [self maxOffset];
    switch (panGesture.state)
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            CGFloat endOriginY = self.dragView.frame.origin.y;
            if (endOriginY > beginOriginY)
                self.constraintTopBarTop.constant = (endOriginY - beginOriginY) >= 40 ? 0 : -maxOffset;
            else if (endOriginY < beginOriginY)
                self.constraintTopBarTop.constant = (beginOriginY - endOriginY) >= 40 ? -maxOffset : 0;
            else
                self.constraintTopBarTop.constant = self.constraintTopBarTop.constant == 0?-maxOffset:0;
            [self.viewTopBarGlobal setHidden:YES];
            [UIView animateWithDuration:0.3 animations:^{
                [self.viewCrop layoutIfNeeded];
            }completion:^(BOOL finished) {
                 [self.viewTopBarGlobal setHidden:self.constraintTopBarTop.constant < 0];
             }];
            break;
        }
        case UIGestureRecognizerStateBegan:
        {
            beginOriginY = self.dragView.frame.origin.y;
            [self.viewTopBarGlobal setHidden:YES];
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            if (_dragView.frame.origin.y <=44 || _dragView.frame.origin.y >maxOffset) {
                return;
            }
            CGPoint translation = [panGesture translationInView:self.view];
            self.constraintTopBarTop.constant = translation.y;
            [self.viewCrop layoutIfNeeded];
            break;
        }
        default:
            break;
    }
}

- (void)tapGestureAction:(UITapGestureRecognizer *)tapGesture {
    [self dragViewDown:NO up:NO];
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    [self dragViewDown:true up:false];
}

-(void)dragViewDown:(BOOL)down up:(BOOL)up{
    float offset;
    if (down) {
        offset = 0;
    }
    else if (up){
        offset = -[self maxOffset]-44;
    }
    else{
        offset = self.constraintTopBarTop.constant == 0?-[self maxOffset]:0;
    }
    if(self.constraintTopBarTop.constant == offset)
        return;
    self.constraintTopBarTop.constant = offset;
    [self.viewTopBarGlobal setHidden:YES];
    [UIView animateWithDuration:0.5 animations:^{
        [self.viewCrop layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self.viewTopBarGlobal setHidden:self.constraintTopBarTop.constant < 0];
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    if (otherGestureRecognizer.view == self.scrollView) {
        return NO;
    }
    return YES;
}

-(float)maxOffset{
    float maxOffset = 0;
    if (self.collectionView.contentSize.height > (SCREEN_HEIGHT - 88 - SCREEN_WIDTH))
        maxOffset = MIN(SCREEN_WIDTH, (self.collectionView.contentSize.height - (SCREEN_HEIGHT - 88 - SCREEN_WIDTH)));
    return maxOffset;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    [self.btnAssetGroup setTitle:[[self.assetCollection localizedTitle] uppercaseString] forState:UIControlStateNormal];
    [self.btnTitleTopBarGlobal setTitle:[[self.assetCollection localizedTitle] uppercaseString] forState:UIControlStateNormal];
    [self selectAssetGroup:self.btnAssetGroup];
}

#pragma mark - button actions

- (IBAction)selectAssetGroup:(UIButton *)sender {
    //Select album type
    sender = self.btnAssetGroup;
    self.btnAssetGroup.selected = !self.btnAssetGroup.selected;
    [self.tableViewLibrary setHidden:NO];
    [self.btnCross setHidden:NO];
    [self.btnNext setHidden:NO];
    [self.btnCrossGlobal setHidden:NO];
    [self.btnNextGlobal setHidden:NO];
    self.constraintTopTableViewLibrary.constant = sender.selected?SCREEN_HEIGHT:44;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.view layoutIfNeeded];
        [self.btnCross setAlpha:sender.selected];
        [self.btnNext setAlpha:sender.selected];
        [self.btnCrossGlobal setAlpha:sender.selected];
        [self.btnNextGlobal setAlpha:sender.selected];
        self.imgArrowTopBarGlobal.transform = sender.selected? CGAffineTransformIdentity: CGAffineTransformMakeRotation(M_PI);
        self.imgArrowTopBarPhoto.transform = sender.selected? CGAffineTransformIdentity: CGAffineTransformMakeRotation(M_PI);
    } completion:^(BOOL finished) {
        [self.tableViewLibrary setHidden:sender.selected];
        [self.btnCross setHidden:!sender.selected];
        [self.btnNext setHidden:!sender.selected];
        [self.btnCrossGlobal setHidden:!sender.selected];
        [self.btnNextGlobal setHidden:!sender.selected];
        
        if (!sender.selected) {
            if (!line) {
                line = [[CAShapeLayer alloc] init];
                line.strokeColor = [UIColor whiteColor].CGColor;
                line.lineWidth = 0.3; //etc.
                [line setPath:[self straightLinePath].CGPath];
                [[self.viewTopBarGlobal layer] addSublayer:line];
            }
            [line setHidden:NO];
        }

    }];
    if (line &&sender.selected) {
        [line setHidden:YES];
    }
   }

- (UIBezierPath*)straightLinePath
{
    UIBezierPath* path = [[UIBezierPath alloc]init];
    [path moveToPoint:CGPointMake(0.0, self.viewTopBarGlobal.frame.size.height)];
    [path addLineToPoint:CGPointMake(SCREEN_WIDTH,self.viewTopBarGlobal.frame.size.height)];
    [path closePath];
    return path;
}

- (IBAction)resetCrop:(id)sender {
    [self.cropperView setOriginalImage:self.originalSelectedImage];
}

- (IBAction)close:(UIButton *)sender {
    closePressed = YES;
    if (sender == _btnCross) {
        [_viewTopBarGlobal setHidden:YES];
    }
    else{
        [_viewTopBar setHidden:YES];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)library:(id)sender {
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    [self.scrollViewCamera setContentOffset:CGPointZero animated:NO];
}

- (IBAction)photo:(id)sender {
    if(self.player)
       [self.player stop];
    [self.scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:YES];
    [self.scrollViewCamera setContentOffset:CGPointZero animated:self.scrollView.contentOffset.x > 0];
}

- (IBAction)video:(id)sender {
    if(self.player)
        [self.player stop];
    [self.scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:YES];
    [self.scrollViewCamera setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:self.scrollView.contentOffset.x > 0];
}


- (IBAction)imageSelectedFromLibrary:(id)sender {
    if (recording && _recorder.session.segments.count > 0) {
        [self videoRecordedFromCamera:nil];
       // [self endCapture];
    }
    else if(self.btnLibrary.selected){
        if(!self.assetEditing)
            return;
        // Set the appropriate toolbarItems based on the mediaType of the asset.
        if (self.assetEditing.mediaType == PHAssetMediaTypeVideo) {
           // [Localytics tagEvent:@"Video selected from Library"];
            // Request an AVAsset for the PHAsset we're displaying.
            [[PHImageManager defaultManager] requestAVAssetForVideo:self.assetEditing options:nil resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                
                    //    // output file
                    //    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                    //    NSString * uniqueImageName = [NSString stringWithFormat:@"output%f.mp4",[[NSDate date] timeIntervalSince1970] * 1000];
                    //
                    //    outputPath = [docFolder stringByAppendingPathComponent:uniqueImageName];
                    //    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
                    //        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
                    [self squareVideo:avAsset muteAudio:self.btnMuteVideo.selected audioAsset:nil completed:^(NSURL *url) {
                       UIVideoEditorController *editor = [[UIVideoEditorController alloc] init];
                       editor.videoMaximumDuration = maxCaptureDuration;
                       editor.videoQuality = UIImagePickerControllerQualityTypeMedium;
                       editor.videoPath = url.path;
                       editor.delegate = self;
                       [self presentViewController:editor animated:YES completion:nil];
                   }];
                   
                });
            }];
            
        } else {
          //  [Localytics tagEvent:@"Image selected from Library"];
//            UIImage *image = [self.cropperView originalImage];
//            CGFloat smallest = MIN(image.size.width, image.size.height);
//            CGFloat largest = MAX(image.size.width, image.size.height);
//            
//            CGFloat ratio = largest/smallest;
//            
//            CGFloat maximumRatioForNonePanorama = 4 / 3; // set this yourself depending on
//            
//            if (ratio > maximumRatioForNonePanorama) {
//                // it is probably a panorama
//                [self showImageEditor:image];
//            }
//            else{
                [self showImageEditor:[self.cropperView processedImage]];
//            }
        }
    }
    else if (self.selectedMedia) {
            [self proceedWithMedia:self.selectedMedia];
            return;
    }
}

- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath{
    [self dismissViewControllerAnimated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            NSMutableDictionary *media =[[NSMutableDictionary alloc] init];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:editedVideoPath]];
            [media setValue:data forKey:kVideoData];
            [media setValue:[self.cropperView originalImage] forKey:vPostTypeImage];
            [media setValue:vPostTypeVideo forKey:kPostType];
            [media setValue:[NSURL fileURLWithPath:editedVideoPath] forKey:kFileURL];
            
            if (self.assetEditing.mediaSubtypes == PHAssetMediaSubtypePhotoPanorama) {
                [media setValue:kPostSubTypePanorama forKey:kPostSubType];
            }
            if (self.assetEditing.location && self.assetEditing.location.coordinate.latitude > 0) {
                [media setValue:[NSNumber numberWithDouble:self.assetEditing.location.coordinate.latitude] forKey:kPostLatitude];
                [media setValue:[NSNumber numberWithDouble:self.assetEditing.location.coordinate.longitude] forKey:kPostLongitude];
            }
            [self proceedWithMedia:media];
        });
    }];
  }

- (void)videoEditorController:(UIVideoEditorController *)editor didFailWithError:(NSError *)error{
    
}

- (void)videoEditorControllerDidCancel:(UIVideoEditorController *)editor{
    [editor dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - scroll view delegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (scrollView == self.collectionView) {
        [super scrollViewDidScroll:scrollView];
        if (scrollView.contentOffset.y < 0) {
            [self dragViewDown:YES up:NO];
        }
        else if(scrollView.contentOffset.y > (self.view.bounds.size.height-self.view.bounds.size.width-88))
        {
            [self dragViewDown:NO up:YES];
        }
        return;
    }
    self.constraintLeadingScrollIndicator.constant = (_scrollView.contentOffset.x+_scrollViewCamera.contentOffset.x)/3.0;
    [self.viewBottomBar layoutIfNeeded];
    
    CGFloat finalOffset = (_scrollView.contentOffset.x+_scrollViewCamera.contentOffset.x);
    
    if (finalOffset < SCREEN_WIDTH/2.0) {
        [self setButtonSelected:self.btnLibrary];
    }
    else if (finalOffset < SCREEN_WIDTH + (SCREEN_WIDTH/2.0)){
        [self setButtonSelected:self.btnPhoto];
    }
    else if (finalOffset >= SCREEN_WIDTH + (SCREEN_WIDTH/2.0)){
        [self setButtonSelected:self.btnVideo];
    }
}

-(void)setButtonSelected:(UIButton *)button{
    [self.btnLibrary setSelected:NO];
    [self.btnPhoto setSelected:NO];
    [self.btnVideo setSelected:NO];
    [button setSelected:YES];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self resetCameraType:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView{
    [self resetCameraType:scrollView];
}

-(void)resetCameraType:(UIScrollView *)scrollView{
    if (scrollView == self.collectionView) {
        return;
    }
    CGFloat finalOffset = (_scrollView.contentOffset.x+_scrollViewCamera.contentOffset.x);

    if (finalOffset < SCREEN_WIDTH){
        [self.btnTitleTopBarGlobal setTitle:[self.btnAssetGroup titleForState:UIControlStateNormal] forState:UIControlStateNormal];
        [self.btnTitleTopBarGlobal setHidden:NO];
        [self.imgArrowTopBarGlobal setHidden:NO];
        [self.lblTitleTopBarGloba setHidden:YES];
    }
    else{
        [self.btnTitleTopBarGlobal setHidden:YES];
        [self.imgArrowTopBarGlobal setHidden:YES];
        [self.lblTitleTopBarGloba setHidden:NO];
    }
    
    [self.btnNext setEnabled:NO];
    [self.btnNextGlobal setEnabled:NO];
    
    if (finalOffset < SCREEN_WIDTH){
        [self.btnTitleTopBarGlobal setTitle:[self.btnAssetGroup titleForState:UIControlStateNormal] forState:UIControlStateNormal];
        [self.btnNext setEnabled:YES];
        [self.btnNextGlobal setEnabled:YES];
    }
    else if (finalOffset < 2*SCREEN_WIDTH){
//        PBJVision *vision = [PBJVision sharedInstance];
//        vision.cameraMode = PBJCameraModePhoto;
//        [self setFlashImage];

        _recorder.captureSessionPreset = AVCaptureSessionPresetPhoto;
        _recorder.flashMode = photoFlashMode;
        [self setFlashImage];
        
        [self.btnTitleImageVideo setTitle:@"PHOTO" forState:UIControlStateNormal];
        [self.lblTitleTopBarGloba setText:@"PHOTO"];
       // [self.btnNext setHidden:YES];
       // [self.btnNextGlobal setHidden:YES];
    }
    else if(finalOffset >= 2*SCREEN_WIDTH){
//        PBJVision *vision = [PBJVision sharedInstance];
//        vision.cameraMode = PBJCameraModeVideo;
        
        _recorder.captureSessionPreset = kVideoPreset;
        _recorder.flashMode = videoFlashMode;
        [self setFlashImage];
        //[self.btnFlash setHidden:YES];
        [self.btnTitleImageVideo setTitle:@"VIDEO" forState:UIControlStateNormal];
        [self.lblTitleTopBarGloba setText:@"VIDEO"];
//        [self.btnNext setHidden:YES];
//        [self.btnNextGlobal setHidden:YES];
    }
}


#pragma mark - CAMERA TAB

#pragma mark - setup camera

-(void)initializeCamera{
    
//    // preview and AV layer
//    AVCaptureVideoPreviewLayer *previewLayer = [[PBJVision sharedInstance] previewLayer];
//    previewLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
//    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    [self.viewCameraPreview.layer addSublayer:previewLayer];
    
    
    _ghostImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _ghostImageView.contentMode = UIViewContentModeScaleAspectFill;
    _ghostImageView.alpha = 0.2;
    _ghostImageView.userInteractionEnabled = NO;
    _ghostImageView.hidden = YES;
    
    [self.view insertSubview:_ghostImageView aboveSubview:self.viewCameraPreview];
    
    _recorder = [SCRecorder recorder];
    _recorder.captureSessionPreset = [SCRecorderTools bestCaptureSessionPresetCompatibleWithAllDevices];
        _recorder.maxRecordDuration = CMTimeMake(maxCaptureDuration, 1);
    //    _recorder.fastRecordMethodEnabled = YES;
    
    _recorder.delegate = self;
    _recorder.autoSetVideoOrientation = NO; //YES causes bad orientation for video from camera roll
    
    UIView *previewView = self.viewCameraPreview;
    _recorder.previewView = previewView;
    
    
    [self.btnRecordVideo addGestureRecognizer:[[SCTouchDetector alloc] initWithTarget:self action:@selector(handleTouchDetected:)]];
    
    self.focusView = [[SCRecorderToolsView alloc] initWithFrame:previewView.bounds];
    self.focusView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.focusView.recorder = _recorder;
    [previewView addSubview:self.focusView];
    
    self.focusView.outsideFocusTargetImage = [UIImage imageNamed:@"capture_flip"];
    self.focusView.insideFocusTargetImage = [UIImage imageNamed:@"capture_flip"];
    
    _recorder.initializeSessionLazily = NO;
    
    NSError *error;
    if (![_recorder prepare:&error]) {
        NSLog(@"Prepare error: %@", error.localizedDescription);
    }
    
    // Get the video configuration object
    SCVideoConfiguration *video = _recorder.videoConfiguration;
    
    // Whether the output video size should be infered so it creates a square video
    video.sizeAsSquare = YES;
    
    photoFlashMode = SCFlashModeAuto;
    videoFlashMode = SCFlashModeOff;
}

-(void)startPreview{
//    [self resetCapture];
//    [[PBJVision sharedInstance] startPreview];
    if (_recorder.session == nil) {
        
        SCRecordSession *session = [SCRecordSession recordSession];
        session.fileType = AVFileTypeQuickTimeMovie;
        
        _recorder.session = session;
    }
    
  //  [self updateTimeRecordedLabel];
  //  [self updateGhostImage];

}

-(void)setFlashImage{
    
    if ([_recorder.captureSessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) {
        switch (_recorder.flashMode) {
            case SCFlashModeAuto:
                [self.btnFlash setImage:[UIImage imageNamed:@"flash-auto"] forState:UIControlStateNormal];
                break;
            case SCFlashModeOff:
                [self.btnFlash setImage:[UIImage imageNamed:@"flash-off"] forState:UIControlStateNormal];
                break;
            case SCFlashModeOn:
                [self.btnFlash setImage:[UIImage imageNamed:@"flash-on"] forState:UIControlStateNormal];
                break;
            case SCFlashModeLight:
                [self.btnFlash setImage:[UIImage imageNamed:@"light"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
    } else {
        switch (_recorder.flashMode) {
            case SCFlashModeOff:
                [self.btnFlash setImage:[UIImage imageNamed:@"flash-off"] forState:UIControlStateNormal];;
                break;
            case SCFlashModeLight:
                [self.btnFlash setImage:[UIImage imageNamed:@"light"] forState:UIControlStateNormal];
                break;
            default:
                break;
        }
    }
}
//
//- (void)visionDidChangeFlashAvailablility:(PBJVision *)vision{
//    [self setFlashImage];
//}
//
- (IBAction)toggleFlash:(id)sender {
    if ([_recorder.captureSessionPreset isEqualToString:AVCaptureSessionPresetPhoto]) {
        switch (_recorder.flashMode) {
            case SCFlashModeAuto:
                _recorder.flashMode = SCFlashModeOff;
                break;
            case SCFlashModeOff:
                _recorder.flashMode = SCFlashModeOn;
                break;
            case SCFlashModeOn:
                _recorder.flashMode = SCFlashModeLight;
                break;
            case SCFlashModeLight:
                _recorder.flashMode = SCFlashModeAuto;
                break;
            default:
                break;
        }
        photoFlashMode = _recorder.flashMode;
        if(photoFlashMode == SCFlashModeLight){
            videoFlashMode = _recorder.flashMode;
        }
        else{
            videoFlashMode = SCFlashModeOff;
        }
    } else {
        switch (_recorder.flashMode) {
            case SCFlashModeOff:
                _recorder.flashMode = SCFlashModeLight;
                break;
            case SCFlashModeLight:
                _recorder.flashMode = SCFlashModeOff;
                break;
            default:
                break;
        }
        videoFlashMode = _recorder.flashMode;
        photoFlashMode = _recorder.flashMode;
    }
    
    [self setFlashImage];
}

- (IBAction)frontBackToggle:(id)sender {
    [_recorder switchCaptureDevices];
}

- (IBAction)takePhotoFromCamera:(id)sender {
    recording = NO;
    [_recorder capturePhoto:^(NSError *error, UIImage *image) {
        if (image != nil) {
            [self showPhoto:image];
        } else {
            //[self showAlertViewWithTitle:@"Failed to capture photo" message:error.localizedDescription];
        }
    }];
}

- (void)showPhoto:(UIImage *)photo {
    UIImage *image=[self squareImageFromImage:photo scaledToSize:SCREEN_WIDTH*2 rect:CGRectMake(0, -50, self.view.frame.size.width, self.view.frame.size.width) zoom:1];
    [self showImageEditor:image];
    //[Localytics tagEvent:@"Image taken"];
    
    [library saveImage:image toAlbum:[self getAppName] withCompletionBlock:^(NSError *error) {
        if (error) {
            NSLog(@"Big error: %@", [error description]);
        }
    } imageUrl:^(NSURL *url) {
        
    }];
}

-(NSString *)getAppName{
    NSString *str = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (str == nil || str.length == 0){
        str = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    return str;
}

- (UIImage *)squareImageFromImage:(UIImage *)image scaledToSize:(CGFloat)newSize rect:(CGRect)rect zoom:(float)zoom{
    CGAffineTransform scaleTransform;
    CGPoint origin=rect.origin;
    
    if (image.size.width > image.size.height) {
        CGFloat scaleRatio = newSize / image.size.height;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio*zoom, scaleRatio*zoom);
        CGFloat scale=image.size.height/rect.size.width;
        origin.x*=scale/zoom;
        origin.y*=scale/zoom;
    } else {
        CGFloat scale=image.size.width/rect.size.width;
        origin.x*=scale/zoom;
        origin.y*=scale/zoom;
        
        CGFloat scaleRatio = newSize / image.size.width;
        scaleTransform = CGAffineTransformMakeScale(scaleRatio*zoom, scaleRatio*zoom);
    }
    
    
    CGSize size = CGSizeMake(newSize, newSize);
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    } else {
        UIGraphicsBeginImageContext(size);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextConcatCTM(context, scaleTransform);
    
    [image drawAtPoint:origin];
    
    image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - VIDEO RECORDING

- (void)recorder:(SCRecorder *)recorder didSkipVideoSampleBufferInSession:(SCRecordSession *)recordSession {
    NSLog(@"Skipped video buffer");
}

- (void)recorder:(SCRecorder *)recorder didReconfigureAudioInput:(NSError *)audioInputError {
    NSLog(@"Reconfigured audio input: %@", audioInputError);
}

- (void)recorder:(SCRecorder *)recorder didReconfigureVideoInput:(NSError *)videoInputError {
    NSLog(@"Reconfigured video input: %@", videoInputError);
}

/**
Called when the recorder has started a segment in a session
*/
- (void)recorder:(SCRecorder *__nonnull)recorder didBeginSegmentInSession:(SCRecordSession *__nonnull)session error:(NSError *__nullable)error{
    float totalSessionDuration = CMTimeGetSeconds(session.duration);
    recording = YES;
    current_value = 0.0;
    new_to_value = 0.0;
    
    float x = 0;
    x = (totalSessionDuration/maxCaptureDuration)*SCREEN_WIDTH;
    if (![self.viewBgVideo viewWithTag:session.segments.count+1 + 100]) {
        progressView = [[ProgressView alloc] initWithFrame:CGRectMake(x, 0, 2, 4)];
        [progressView setBackgroundColor:[UIColor whiteColor]];
        [self.viewBgVideo addSubview:progressView];
        progressView.tag = session.segments.count+1 + 100;
        
        if (_blinkTimer) {
            [_blinkTimer invalidate];
            _blinkTimer = nil;
        }
        _blinkTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startBlinking) userInfo:nil repeats:YES];
        
        if (session.segments.count > 0) {
            [self.btnNextGlobal setEnabled:YES];
            [self.btnNext setEnabled:YES];
        }
    }
}

-(ProgressView *)lastRecordedSegment{
    ProgressView *previousSegment = [self.viewBgVideo viewWithTag:_recorder.session.segments.count + 100];
    return previousSegment;
}

-(void)startBlinking{
    [progressView setHidden:!progressView.hidden];
}


/**
 Called when the recorder has appended a video buffer in a session
 */
- (void)recorder:(SCRecorder *__nonnull)recorder didAppendVideoSampleBufferInSession:(SCRecordSession *__nonnull)session{
    //  float totalSessionDuration = CMTimeGetSeconds(session.duration);
    float currentSegmentDuration = CMTimeGetSeconds(session.currentSegmentDuration);
    
    if (_blinkTimer) {
        [_blinkTimer invalidate];
        _blinkTimer = nil;
    }
    [progressView setHidden:NO];
    [progressView setProgress:[NSNumber numberWithFloat:(currentSegmentDuration/maxCaptureDuration)*SCREEN_WIDTH]];
}


/**
 Called when the recorder has completed a segment in a session
 */
- (void)recorder:(SCRecorder *__nonnull)recorder didCompleteSegment:(SCRecordSessionSegment *__nullable)segment inSession:(SCRecordSession *__nonnull)session error:(NSError *__nullable)error{
    CGRect rect = progressView.frame;
    rect.size.width -=1;
    progressView.frame = rect;
    [self videoSegmentRecorded];
}

/**
 Called when a session has reached the maxRecordDuration
 */
- (void)recorder:(SCRecorder *__nonnull)recorder didCompleteSession:(SCRecordSession *__nonnull)session{
    NSLog(@"max duration reached");
    [self videoSegmentRecorded];
    [self showTapToContinuePopup];
}

-(void)videoSegmentRecorded{
    if (recording) {
        [self showVideoCancelButton];
        [self.btnNext setEnabled:YES];
        [self.btnNextGlobal setEnabled:YES];
        self.scrollViewCamera.scrollEnabled = NO;
        self.scrollView.scrollEnabled = NO;
        [self.viewBottomBar setHidden:YES];
        [self.viewBottomVideoCancel setHidden:NO];
        [UIView animateWithDuration:0.25 animations:^{
            self.viewBottomBar.transform = CGAffineTransformMakeTranslation(0, self.viewBottomVideoCancel.frame.size.height);
            self.viewBottomVideoCancel.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            [self.viewBottomBar setHidden:YES];
        }];
    }
}

- (IBAction)videoRecordedFromCamera:(id)sender {
   // [Localytics tagEvent:@"Video taken"];
    //[self endCapture];
    [_recorder pause:^{
        [self saveAndShowSession:_recorder.session];
    }];
}

- (IBAction)muteVideo:(id)sender {
    [self.btnMuteVideo setSelected:!self.btnMuteVideo.selected];
}

- (IBAction)addMusicToVideo:(id)sender {
    MPMediaPickerController *mediaPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    mediaPicker.delegate = self;
    mediaPicker.allowsPickingMultipleItems = NO; // this is the default
    [self presentViewController:mediaPicker animated:YES completion:nil];
}

- (void)saveAndShowSession:(SCRecordSession *)recordSession {
 //   [[SCRecordSessionManager sharedInstance] saveRecordSession:recordSession];
    
    _recordSession = recordSession;
    [self showVideo];
}

- (void)showVideo {
    [self exportVideo:_recordSession.assetRepresentingSegments outputUrl:_recordSession.outputUrl completed:^(NSURL *url) {
        
            NSMutableDictionary *media =[[NSMutableDictionary alloc] init];
            [media setValue:[(SCRecordSessionSegment *)[_recordSession segments].firstObject thumbnail] forKey:vPostTypeImage];
            [media setValue:vPostTypeVideo forKey:kPostType];
            [media setValue:url forKey:kFileURL];
        [media setValue:vMediaSourceCamera forKey:kMediaSource];
            [self proceedWithMedia:media];
    }];

}

- (IBAction)cancelVideoCapture:(id)sender {
    // Remove the last segment
    ProgressView *lastRecordedView = [self lastRecordedSegment];
    if (lastRecordedView.canDelete) {
        [_recorder.session removeLastSegment];
        [lastRecordedView removeFromSuperview];
        float totalSessionDuration = CMTimeGetSeconds(_recorder.session.duration);
        float x = (totalSessionDuration/maxCaptureDuration)*SCREEN_WIDTH;
        CGRect newFrame = progressView.frame;
        newFrame.origin.x = x;
        progressView.frame = newFrame;
    }
    else{
        [lastRecordedView prepareToDelete];
    }
    if (_recorder.session.segments.count == 0) {
        [self hideVideoCancelButton];
        [self cancelVideoSession];
        self.selectedMedia = nil;
    }
}

-(void)cancelVideoSession{
    SCRecordSession *recordSession = _recorder.session;
    
    if (recordSession != nil) {
        _recorder.session = nil;
        
        // If the recordSession was saved, we don't want to completely destroy it
       // if ([[SCRecordSessionManager sharedInstance] isSaved:recordSession]) {
          //  [recordSession endSegmentWithInfo:nil completionHandler:nil];
       // } else {
            [recordSession cancelSession:nil];
      //  }
    }
    
    [self startPreview];
}

-(void)showVideoCancelButton{
    self.scrollViewCamera.scrollEnabled = NO;
    self.scrollView.scrollEnabled = NO;
    [self.viewBottomBar setHidden:YES];
    [self.viewBottomVideoCancel setHidden:NO];
    [UIView animateWithDuration:0.25 animations:^{
        self.viewBottomBar.transform = CGAffineTransformMakeTranslation(0, self.viewBottomVideoCancel.frame.size.height);
        self.viewBottomVideoCancel.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self.viewBottomBar setHidden:YES];
    }];
}

-(void)hideVideoCancelButton{
    [self.btnNext setEnabled:NO];
    [self.btnNextGlobal setEnabled:NO];
    [progressView removeFromSuperview];
    self.scrollViewCamera.scrollEnabled = YES;
    self.scrollView.scrollEnabled = YES;
    [self.viewBottomBar setHidden:NO];
    [self.viewBottomBar setHidden:NO];
    [UIView animateWithDuration:0.25 animations:^{
        self.viewBottomVideoCancel.transform = CGAffineTransformMakeTranslation(0, self.viewBottomVideoCancel.frame.size.height);
        self.viewBottomBar.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [self.viewBottomVideoCancel setHidden:YES];
    }];
}


- (void)handleTouchDetected:(SCTouchDetector*)touchDetector {
    if (touchDetector.state == UIGestureRecognizerStateBegan) {
        _ghostImageView.hidden = YES;
        float totalSessionDuration = CMTimeGetSeconds(_recorder.session.duration);
        if (totalSessionDuration >= maxCaptureDuration) {
            [self showTapToContinuePopup];
            return;
        }
        [_recorder record];
    } else if (touchDetector.state == UIGestureRecognizerStateEnded) {
        [_recorder pause];
    }
}

-(void)showTapToContinuePopup{
    [_viewContinue.layer setAnchorPoint:CGPointMake(0.8,0)];
    _viewContinue.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
    
    [_viewContinue setHidden:NO];
    [UIView animateWithDuration:0.3/1.5 animations:^{
        _viewContinue.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3/2 animations:^{
            _viewContinue.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2 animations:^{
                _viewContinue.transform = CGAffineTransformIdentity;
                [self performSelector:@selector(hidePopup) withObject:nil afterDelay:2];
            }];
        }];
    }];
}

-(void)hidePopup{
    [UIView animateWithDuration:0.3/1.5 animations:^{
        _viewContinue.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
    } completion:^(BOOL finished) {
        [_viewContinue setHidden:YES];
    }];
}

-(void)showImageEditor:(UIImage *)image{
    [[CurrentLocation sharedInstance] getCurrentLocation:YES success:^(CLLocation *location) {

    } failure:^(NSError *error) {

    }];

    [[CLImageEditorTheme theme] setBackgroundColor:[UIColor blackColor]];
    [[CLImageEditorTheme theme] setToolbarColor:kAppThemeColor];
    [[CLImageEditorTheme theme] setToolbarTextColor:[UIColor whiteColor]];
    CLImageEditor *editor = [[CLImageEditor alloc] initWithImage:image delegate:self];
    [self.navigationController pushViewController:editor animated:YES];

}

#pragma mark- CLImageEditor delegate

- (void)imageEditor:(CLImageEditor *)editor didFinishEdittingWithImage:(UIImage *)image
{
    NSMutableDictionary *media =[[NSMutableDictionary alloc] init];
    [media setValue:image forKey:vPostTypeImage];
    [media setValue:vPostTypeImage forKey:kPostType];
    
    CGFloat smallest = MIN(image.size.width, image.size.height);
    CGFloat largest = MAX(image.size.width, image.size.height);
    
    CGFloat ratio = largest/smallest;
    
    CGFloat maximumRatioForNonePanorama = 4 / 3; // set this yourself depending on
    
//    if (ratio > maximumRatioForNonePanorama) {
//        // it is probably a panorama
//    }
  //  NSUInteger height = self.assetEditing.pixelHeight;
    NSLog(@"pixels = %lu %lu",(unsigned long)self.assetEditing.pixelWidth,(unsigned long)self.assetEditing.pixelHeight);
    NSLog(@"size = %f %f",image.size.width,image.size.height);

    if (self.assetEditing.mediaSubtypes == PHAssetMediaSubtypePhotoPanorama || ratio > maximumRatioForNonePanorama) {
        [media setValue:kPostSubTypePanorama forKey:kPostSubType];
    }
    if (self.assetEditing.location && self.assetEditing.location.coordinate.latitude > 0) {
        [media setValue:[NSNumber numberWithDouble:self.assetEditing.location.coordinate.latitude] forKey:kPostLatitude];
        [media setValue:[NSNumber numberWithDouble:self.assetEditing.location.coordinate.longitude] forKey:kPostLongitude];
    }
    [self proceedWithMedia:media];
}

- (void)imageEditor:(CLImageEditor *)editor willDismissWithImageView:(UIImageView *)imageView canceled:(BOOL)canceled
{
    //[Localytics tagEvent:@"Cancel Camera"];
    @try {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    @catch (NSException *exception) {
        
    }
}

#pragma mark Media picker delegate methods

-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    
    // We need to dismiss the picker
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Assign the selected item(s) to the music player and start playback.
    if ([mediaItemCollection count] < 1) {
        return;
    }
    
    if (self.assetEditing.mediaType == PHAssetMediaTypeVideo) {
        //[Localytics tagEvent:@"Video selected from Library"];
        // Request an AVAsset for the PHAsset we're displaying.
        [[PHImageManager defaultManager] requestAVAssetForVideo:self.assetEditing options:nil resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                MPMediaItem *song = [[mediaItemCollection items] objectAtIndex:0];
                NSURL *assetURL = [song valueForProperty:MPMediaItemPropertyAssetURL];
                AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:assetURL options:nil];
                
                [self squareVideo:avAsset muteAudio:self.btnMuteVideo.selected audioAsset:songAsset completed:^(NSURL *url) {
                    UIVideoEditorController *editor = [[UIVideoEditorController alloc] init];
                    editor.videoMaximumDuration = maxCaptureDuration;
                    editor.videoQuality = UIImagePickerControllerQualityTypeMedium;
                    editor.videoPath = url.path;
                    editor.delegate = self;
                    [self presentViewController:editor animated:YES completion:nil];
                }];
                
            });
        }];
        
    }
    
}

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [self dismissViewControllerAnimated:YES completion:nil ];
}



-(void)proceedWithMedia:(NSDictionary *)media{
    self.selectedMedia = media;
}

#pragma mark - export taken video

-(void)exportVideo:(AVAsset *)asset outputUrl:(NSURL *)outputUrl completed:(void(^)(NSURL *url))completed{
    
    [[CurrentLocation sharedInstance] getCurrentLocation:YES success:^(CLLocation *location) {
        
    } failure:^(NSError *error) {
        
    }];
    
    [self.activityIndicator startAnimating];
    
    //AVVideoComposition *squareComposition = [self squareVideoCompositionForAsset:asset];
    SCAssetExportSession *exportSession = [[SCAssetExportSession alloc] initWithAsset:asset];
    //exportSession.videoConfiguration.filter = currentFilter;
    exportSession.videoConfiguration.preset = SCPresetHighestQuality;
    exportSession.audioConfiguration.preset = SCPresetHighestQuality;
    exportSession.videoConfiguration.maxFrameRate = 35;
//        if(squareComposition)
//        exportSession.videoConfiguration.composition = squareComposition;
    exportSession.outputUrl = outputUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    exportSession.delegate = self;
    exportSession.contextType = SCContextTypeAuto;
    self.exportSession = exportSession;
    
    NSLog(@"Starting exporting");
    
    CFTimeInterval time = CACurrentMediaTime();
    __weak typeof(self) wSelf = self;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        __strong typeof(self) strongSelf = wSelf;
        [self.activityIndicator stopAnimating];
        if (!exportSession.cancelled) {
            NSLog(@"Completed compression in %fs", CACurrentMediaTime() - time);
        }
        
        if (strongSelf != nil) {
            [strongSelf.player play];
            strongSelf.exportSession = nil;
            strongSelf.navigationItem.rightBarButtonItem.enabled = YES;
            
            [UIView animateWithDuration:0.3 animations:^{
                // strongSelf.exportView.alpha = 0;
            }];
        }
        
        NSError *error = exportSession.error;
        if (exportSession.cancelled) {
            NSLog(@"Export was cancelled");
        } else if (error == nil) {
            if (completed) {
                completed(exportSession.outputUrl);
                
            }
            //            [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
            //            [exportSession.outputUrl saveToCameraRollWithCompletion:^(NSString * _Nullable path, NSError * _Nullable error) {
            //                [[UIApplication sharedApplication] endIgnoringInteractionEvents];
            //
            //                if (error == nil) {
            //                    [[[UIAlertView alloc] initWithTitle:@"Saved to camera roll" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            //                } else {
            //                    [[[UIAlertView alloc] initWithTitle:@"Failed to save" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            //                }
            //            }];
        } else {
            if (!exportSession.cancelled) {
                [[[UIAlertView alloc] initWithTitle:@"Failed to save" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
        }
    }];

}


#pragma mark - square video chosen from library

-(AVVideoComposition *)squareVideoCompositionForAsset:(AVAsset *)asset{
    // input clip
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //    double durationTime = CMTimeGetSeconds(asset.duration);
    
    // make it square
    AVMutableVideoComposition* videoComposition;
    if(clipVideoTrack.naturalSize.height != clipVideoTrack.naturalSize.width)
    {
        videoComposition = [AVMutableVideoComposition videoComposition];
        CGSize videoSize = [clipVideoTrack naturalSize];
        float scaleFactor;
        if (videoSize.width > videoSize.height) {
            scaleFactor = videoSize.height/320;
        }
        else if (videoSize.width == videoSize.height){
            scaleFactor = videoSize.height/320;
        }
        else{
            scaleFactor = videoSize.width/320;
        }
        
        CGFloat cropWidth = 320 *scaleFactor;
        CGFloat cropHeight = 320 *scaleFactor;
        
        videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight);
        videoComposition.frameDuration = CMTimeMake(1, 30);
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
        
        // rotate to portrait
        AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
        
        float cropOffY = fabs((clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height) /2);
        
        UIImageOrientation videoOrientation = [self getVideoOrientationFromAsset:asset];
        
        CGAffineTransform t1 = CGAffineTransformIdentity;
        CGAffineTransform t2 = CGAffineTransformIdentity;
        
        switch (videoOrientation) {
            case UIImageOrientationUp:
                t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, 0 - cropOffY );
                t2 = CGAffineTransformRotate(t1, M_PI_2 );
                break;
            case UIImageOrientationDown:
                t1 = CGAffineTransformMakeTranslation(0, clipVideoTrack.naturalSize.width - cropOffY ); // not fixed width is the real height in upside down
                t2 = CGAffineTransformRotate(t1, - M_PI_2 );
                break;
            case UIImageOrientationRight:
                t1 = CGAffineTransformMakeTranslation(0, 0 - cropOffY );
                t2 = CGAffineTransformRotate(t1, 0 );
                break;
            case UIImageOrientationLeft:
                t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.width , clipVideoTrack.naturalSize.height - cropOffY );
                t2 = CGAffineTransformRotate(t1, M_PI  );
                break;
            default:
                NSLog(@"no supported orientation has been found in this video");
                break;
        }
        
        CGAffineTransform finalTransform = t2;
        NSLog(@"videoSize = %f %f",clipVideoTrack.naturalSize.width,clipVideoTrack.naturalSize.height);
        [transformer setTransform:finalTransform atTime:kCMTimeZero];
        instruction.layerInstructions = [NSArray arrayWithObject:transformer];
        videoComposition.instructions = [NSArray arrayWithObject: instruction];
    }
    return videoComposition;
}

-(void)squareVideo:(AVAsset *)asset muteAudio:(BOOL)muteAudio audioAsset:(AVAsset *)customAudio completed:(void(^)(NSURL *url))completed;
{
    [self.activityIndicator startAnimating];
    //exportProgressBarTimer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(updateExportDisplay) userInfo:nil repeats:YES];
    // output file
    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString * uniqueImageName = [NSString stringWithFormat:@"output%f.mp4",[[NSDate date] timeIntervalSince1970] * 1000];
    
    outputPath = [docFolder stringByAppendingPathComponent:uniqueImageName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    
    CMTimeRange video_timeRange = CMTimeRangeMake(kCMTimeZero,asset.duration);
    CMTimeRange audio_timeRange = CMTimeRangeMake(kCMTimeZero,asset.duration);

    // input clip
    //AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //    double durationTime = CMTimeGetSeconds(asset.duration);
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    //[composition  addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    BOOL ok= NO;
    AVMutableCompositionTrack *compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    ok = [compositionVideoTrack insertTimeRange:video_timeRange ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    
    if (customAudio) {
        if (CMTimeGetSeconds(customAudio.duration) < CMTimeGetSeconds(asset.duration)) {
            audio_timeRange = CMTimeRangeMake(kCMTimeZero,customAudio.duration);
        }
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        ok = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[customAudio tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }
    else if (!muteAudio) {
        //Now we are creating the first AVMutableCompositionTrack containing our audio and add it to our AVMutableComposition object.
        AVMutableCompositionTrack *compositionAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        ok = [compositionAudioTrack insertTimeRange:audio_timeRange ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }
    
    // make it square
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    if(compositionVideoTrack.naturalSize.height != compositionVideoTrack.naturalSize.width)
    {
        CGSize videoSize = [compositionVideoTrack naturalSize];
        float scaleFactor;
        if (videoSize.width > videoSize.height) {
            scaleFactor = videoSize.height/320;
        }
        else if (videoSize.width == videoSize.height){
            scaleFactor = videoSize.height/320;
        }
        else{
            scaleFactor = videoSize.width/320;
        }
        
        CGFloat cropWidth = 320 *scaleFactor;
        CGFloat cropHeight = 320 *scaleFactor;
        
        videoComposition.renderSize = CGSizeMake(cropWidth, cropHeight);
        videoComposition.frameDuration = CMTimeMake(1, 30);
        
        AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
        
        // rotate to portrait
        AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];

        float cropOffY = fabs((compositionVideoTrack.naturalSize.width - compositionVideoTrack.naturalSize.height) /2);
        
        UIImageOrientation videoOrientation = [self getVideoOrientationFromAsset:asset];
        
        CGAffineTransform t1 = CGAffineTransformIdentity;
        CGAffineTransform t2 = CGAffineTransformIdentity;
        
        switch (videoOrientation) {
            case UIImageOrientationUp:
                t1 = CGAffineTransformMakeTranslation(compositionVideoTrack.naturalSize.height, 0 - cropOffY );
                t2 = CGAffineTransformRotate(t1, M_PI_2 );
                break;
            case UIImageOrientationDown:
                t1 = CGAffineTransformMakeTranslation(0, compositionVideoTrack.naturalSize.width - cropOffY ); // not fixed width is the real height in upside down
                t2 = CGAffineTransformRotate(t1, - M_PI_2 );
                break;
            case UIImageOrientationRight:
                t1 = CGAffineTransformMakeTranslation(0, 0 - cropOffY );
                t2 = CGAffineTransformRotate(t1, 0 );
                break;
            case UIImageOrientationLeft:
                t1 = CGAffineTransformMakeTranslation(compositionVideoTrack.naturalSize.width , compositionVideoTrack.naturalSize.height - cropOffY );
                t2 = CGAffineTransformRotate(t1, M_PI  );
                break;
            default:
                NSLog(@"no supported orientation has been found in this video");
                break;
        }
        
        CGAffineTransform finalTransform = t2;
        NSLog(@"videoSize = %f %f",compositionVideoTrack.naturalSize.width,compositionVideoTrack.naturalSize.height);
        [transformer setTransform:finalTransform atTime:kCMTimeZero];
        instruction.layerInstructions = [NSArray arrayWithObject:transformer];
        videoComposition.instructions = [NSArray arrayWithObject: instruction];
    }
    
    // export
    exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    if(compositionVideoTrack.naturalSize.height != compositionVideoTrack.naturalSize.width)
    {
        exporter.videoComposition = videoComposition;
    }
    
    exporter.outputURL=[NSURL fileURLWithPath:outputPath];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    
    CMTime start = kCMTimeZero;
    CMTime duration = kCMTimeIndefinite;
    //    if (durationTime > 15.0)
    //    {
    //        start = CMTimeMakeWithSeconds(1.0, 600);
    //        duration = CMTimeMakeWithSeconds(15.0, 600);
    //    }
    //
    CMTimeRange range = CMTimeRangeMake(start, duration);
    exporter.timeRange = range;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void)
     {
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.activityIndicator stopAnimating];
             int exportStatus = exporter.status;
             switch (exportStatus) {
                     
                 case AVAssetExportSessionStatusFailed: {
                     
                     NSError *exportError = exporter.error;
                     NSLog (@"AVAssetExportSessionStatusFailed: %@", exportError);
                     break;
                 }
                 case AVAssetExportSessionStatusCompleted: {
                     NSLog (@"AVAssetExportSessionStatusCompleted--");
                     if (completed) {
                         completed(exporter.outputURL);
                     }
                     break;
                 }
                 case AVAssetExportSessionStatusUnknown: { NSLog (@"AVAssetExportSessionStatusUnknown"); break;}
                 case AVAssetExportSessionStatusExporting: { NSLog (@"AVAssetExportSessionStatusExporting"); break;}
                 case AVAssetExportSessionStatusCancelled: { NSLog (@"AVAssetExportSessionStatusCancelled"); break;}
                 case AVAssetExportSessionStatusWaiting: { NSLog (@"AVAssetExportSessionStatusWaiting"); break;}
                 default: { NSLog (@"didn't get export status"); break;}
             }
             
             

         });
         
     }];

}

- (UIImageOrientation)getVideoOrientationFromAsset:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    CGSize size = [videoTrack naturalSize];
    CGAffineTransform txf = [videoTrack preferredTransform];
    
    if (size.width == txf.tx && size.height == txf.ty)
        return UIImageOrientationLeft; //return UIInterfaceOrientationLandscapeLeft;
    else if (txf.tx == 0 && txf.ty == 0)
        return UIImageOrientationRight; //return UIInterfaceOrientationLandscapeRight;
    else if (txf.tx == 0 && txf.ty == size.width)
        return UIImageOrientationDown; //return UIInterfaceOrientationPortraitUpsideDown;
    else
        return UIImageOrientationUp;  //return UIInterfaceOrientationPortrait;
}

- (void)cancelExport
{
    [_exportSession cancelExport];
}

- (void)convertVideoToLowQuailtyWithAsset:(AVAsset*)videoAsset
                                   outputURL:(NSURL*)outputURL  completed:(void(^)(NSURL *url))completed;
{
    //setup video writer
   //AVAsset *videoAsset = [[AVURLAsset alloc] initWithURL:inputURL options:nil];
    
    AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    CGSize videoSize = videoTrack.naturalSize;
    
    NSDictionary *videoWriterCompressionSettings =  [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1250000], AVVideoAverageBitRateKey, nil];
    
    NSDictionary *videoWriterSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, videoWriterCompressionSettings, AVVideoCompressionPropertiesKey, [NSNumber numberWithFloat:videoSize.width], AVVideoWidthKey, [NSNumber numberWithFloat:videoSize.height], AVVideoHeightKey, nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoWriterSettings];
    
    videoWriterInput.expectsMediaDataInRealTime = YES;
    
    videoWriterInput.transform = videoTrack.preferredTransform;
    
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:nil];
    
    [videoWriter addInput:videoWriterInput];
    
    //setup video reader
    NSDictionary *videoReaderSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:videoReaderSettings];
    
    AVAssetReader *videoReader = [[AVAssetReader alloc] initWithAsset:videoAsset error:nil];
    
    [videoReader addOutput:videoReaderOutput];
    
    //setup audio writer
    AVAssetWriterInput* audioWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeAudio
                                            outputSettings:nil];
    
    audioWriterInput.expectsMediaDataInRealTime = NO;
    
    [videoWriter addInput:audioWriterInput];
    
    //setup audio reader
    AVAssetTrack* audioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    AVAssetReaderOutput *audioReaderOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:nil];
    
    AVAssetReader *audioReader = [AVAssetReader assetReaderWithAsset:videoAsset error:nil];
    
    [audioReader addOutput:audioReaderOutput];
    
    [videoWriter startWriting];
    
    //start writing from video reader
    [videoReader startReading];
    
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t processingQueue = dispatch_queue_create("processingQueue1", NULL);
    
    [videoWriterInput requestMediaDataWhenReadyOnQueue:processingQueue usingBlock:
     ^{
         
         while ([videoWriterInput isReadyForMoreMediaData]) {
             
             CMSampleBufferRef sampleBuffer;
             
             if ([videoReader status] == AVAssetReaderStatusReading &&
                 (sampleBuffer = [videoReaderOutput copyNextSampleBuffer])) {
                 
                 [videoWriterInput appendSampleBuffer:sampleBuffer];
                 CFRelease(sampleBuffer);
             }
             
             else {
                 
                 [videoWriterInput markAsFinished];
                 
                 if ([videoReader status] == AVAssetReaderStatusCompleted) {
                     
                     //start writing from audio reader
                     [audioReader startReading];
                     
                     [videoWriter startSessionAtSourceTime:kCMTimeZero];
                     
                     dispatch_queue_t processingQueue = dispatch_queue_create("processingQueue2", NULL);
                     
                     [audioWriterInput requestMediaDataWhenReadyOnQueue:processingQueue usingBlock:^{
                         
                         while (audioWriterInput.readyForMoreMediaData) {
                             
                             CMSampleBufferRef sampleBuffer;
                             
                             if ([audioReader status] == AVAssetReaderStatusReading &&
                                 (sampleBuffer = [audioReaderOutput copyNextSampleBuffer])) {
                                 
                                 [audioWriterInput appendSampleBuffer:sampleBuffer];
                                 CFRelease(sampleBuffer);
                             }
                             
                             else {
                                 
                                 [audioWriterInput markAsFinished];
                                 
                                 if ([audioReader status] == AVAssetReaderStatusCompleted) {
                                     
                                     [videoWriter finishWritingWithCompletionHandler:^(){
                                        //[self sendMovieFileAtURL:outputURL];
                                         if (completed) {
                                             completed(outputURL);
                                         }
                                     }];
                                     
                                 }
                             }
                         }
                         
                     }
                      ];
                 }
             }
         }
     }
     ];
}


@end
