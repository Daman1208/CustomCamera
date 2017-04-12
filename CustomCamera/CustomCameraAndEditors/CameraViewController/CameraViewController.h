//
//  CameraViewController.h
//  Camera
//
//  Created by Daman on 11/04/17.
//  Copyright © 2017 Tarsem. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhotoLibraryViewController.h"
#import "ProgressView.h"

@interface CameraViewController : PhotoLibraryViewController<UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (weak, nonatomic) IBOutlet UIView *viewTopBarGlobal;
@property (weak, nonatomic) IBOutlet UIButton *btnTitleTopBarGlobal;
@property (weak, nonatomic) IBOutlet UILabel *lblTitleTopBarGloba;
@property (weak, nonatomic) IBOutlet UIImageView *imgArrowTopBarGlobal;
@property (weak, nonatomic) IBOutlet UIImageView *imgArrowTopBarPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnTitleImageVideo;
//@property (weak, nonatomic) IBOutlet UIView *viewCrop;
//@property (weak, nonatomic) IBOutlet UIView *viewCropperContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintLeadingScrollIndicator;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollViewCamera;
@property (strong, nonatomic) IBOutlet UIView *viewTopBar;
@property (weak, nonatomic) IBOutlet UIView *viewBottomBar;
@property (weak, nonatomic) IBOutlet UIButton *btnLibrary;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnVideo;
//@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *dragView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTopBarTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *constraintTopTableViewLibrary;
//@property (weak, nonatomic) IBOutlet UITableView *tableViewLibrary;
@property (weak, nonatomic) IBOutlet UIView *viewBgVideo;
@property (weak, nonatomic) IBOutlet UIButton *btnAssetGroup;
@property (weak, nonatomic) IBOutlet UIButton *btnCross;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UIButton *btnCrossGlobal;
@property (weak, nonatomic) IBOutlet UIButton *btnNextGlobal;
@property (weak, nonatomic) IBOutlet UIView *viewCameraPreview;
@property (strong, nonatomic) IBOutlet UIView *viewContinue;
@property (weak, nonatomic) IBOutlet UIButton *btnResetCrop;

//@property (weak, nonatomic) IBOutlet UIButton *btnPreviewVideo;
- (IBAction)selectAssetGroup:(id)sender;
- (IBAction)resetCrop:(id)sender;
- (IBAction)close:(id)sender;
- (IBAction)library:(id)sender;
- (IBAction)photo:(id)sender;
- (IBAction)video:(id)sender;
- (IBAction)imageSelectedFromLibrary:(id)sender;
//- (IBAction)prewVideo:(id)sender;
@property (weak, nonatomic) IBOutlet UIView *viewBottomVideoCancel;
- (IBAction)cancelVideoCapture:(id)sender;

//Camera
@property (weak, nonatomic) IBOutlet UIButton *btnFrontBackToggle;
@property (weak, nonatomic) IBOutlet UIButton *btnFlash;
@property (weak, nonatomic) IBOutlet UIButton *btnRecordVideo;
@property (weak, nonatomic) IBOutlet ProgressView *viewProgress;
- (IBAction)takePhotoFromCamera:(id)sender;
- (IBAction)frontBackToggle:(id)sender;
- (IBAction)toggleFlash:(id)sender;
- (IBAction)videoRecordedFromCamera:(id)sender;
- (IBAction)muteVideo:(id)sender;
- (IBAction)addMusicToVideo:(id)sender;
+(void)presentOnViewController:(UIViewController *)vc;
@end
