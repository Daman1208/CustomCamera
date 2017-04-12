//
//  CLFrameTool.m
//  SOLit
//
//  Created by Daman on 07/05/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#import "CLFrameTool.h"
#import "CLCircleView.h"
#import "CLToolbarMenuGroupIcon.h"

static NSString* const kCLFrameToolFramePathKey = @"framePath";

@interface _CLFrameView : UIView
+ (void)setActiveStickerView:(_CLFrameView*)view;
- (UIImageView*)imageView;
- (id)initWithImage:(UIImage *)image tool:(CLFrameTool*)tool frame:(CGRect)rect;
@end



@implementation CLFrameTool
{
    UIImage *_originalImage;
    
    UIView *_workingView;
    
    UIScrollView *_menuScroll;
}

+ (NSArray*)subtools
{
    return nil;
}

+ (NSString*)defaultTitle
{
    return [CLImageEditorTheme localizedString:@"CLFrameTool_DefaultTitle" withDefault:@"Frame"];
}

+ (BOOL)isAvailable
{
    return ([UIDevice iosVersion] >= 5.0);
}

+ (CGFloat)defaultDockedNumber
{
    return 7;
}

#pragma mark- optional info

+ (NSString*)defaultFramePath
{
    return [[[CLImageEditorTheme bundle] bundlePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/frames", NSStringFromClass(self)]];
}

+ (NSDictionary*)optionalInfo
{
    return @{
             kCLFrameToolFramePathKey:[self defaultFramePath],
             };
}

#pragma mark- implementation

- (void)setup
{
    _originalImage = self.editor.imageView.image;
    
   // [self.editor fixZoomScaleWithAnimated:YES];
    
    _menuScroll = [[UIScrollView alloc] initWithFrame:self.editor.menuView.frame];
    _menuScroll.backgroundColor = self.editor.menuView.backgroundColor;
    _menuScroll.showsHorizontalScrollIndicator = NO;
    [self.editor.view addSubview:_menuScroll];
    
    _workingView = [[UIView alloc] initWithFrame:[self.editor.view convertRect:self.editor.imageView.frame fromView:self.editor.imageView.superview]];
    _workingView.clipsToBounds = YES;
    [self.editor.view addSubview:_workingView];
    [self setStickerMenu];
    
    _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformIdentity;
                     }];
}

- (void)cleanup
{
    [self.editor resetZoomScaleWithAnimated:YES];
    
    [_workingView removeFromSuperview];
    
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         _menuScroll.transform = CGAffineTransformMakeTranslation(0, self.editor.view.height-_menuScroll.top);
                     }
                     completion:^(BOOL finished) {
                         [_menuScroll removeFromSuperview];
                     }];
}

- (void)executeWithCompletionBlock:(void (^)(UIImage *, NSError *, NSDictionary *))completionBlock
{
    [_CLFrameView setActiveStickerView:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *image = [self buildImage:_originalImage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(image, nil, nil);
        });
    });
}

#pragma mark-

- (void)setStickerMenu
{
    CGFloat W = 90;
    CGFloat H = _menuScroll.height;
    CGFloat x = 0;

    NSString *stickerPath = self.toolInfo.optionalInfo[kCLFrameToolFramePathKey];
    if(stickerPath==nil){ stickerPath = [[self class] defaultFramePath]; }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    NSArray *list = [fileManager contentsOfDirectoryAtPath:stickerPath error:&error];
    
    for(NSString *groupPath in list){
        CLToolbarMenuGroupIcon *group = [[CLToolbarMenuGroupIcon alloc] initWithFrame:CGRectMake(x, 0, 30, H) title:groupPath];
        [_menuScroll addSubview:group];
        x += 30;
        
        NSArray *list1 = [fileManager contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/%@",stickerPath,groupPath] error:&error];
        
        for(NSString *path in list1){
            NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", stickerPath,groupPath, path];
            UIImage *image = [UIImage imageWithContentsOfFile:filePath];
            if(image){
                CLToolbarMenuItem *view = [CLImageEditorTheme menuItemWithFrame:CGRectMake(x, 0, W, H) target:self action:@selector(tappedStickerPanel:) toolInfo:nil];
                view.iconImage = [image aspectFit:CGSizeMake(70, 70)];
                view.userInfo = @{@"filePath" : filePath};
                
                [_menuScroll addSubview:view];
                x += W;
            }
        }
    }
    
    _menuScroll.contentSize = CGSizeMake(MAX(x, _menuScroll.frame.size.width+1), 0);
}

- (void)tappedStickerPanel:(UITapGestureRecognizer*)sender
{
    UIView *view = sender.view;
    
    NSString *filePath = view.userInfo[@"filePath"];
    if(_currentFramePath && [_currentFramePath isEqualToString:filePath]){
        return;
    }
    else if(_currentFramePath){
        UIView *oldView = [[_workingView subviews] lastObject];
        if(oldView)
            [oldView removeFromSuperview];
    }
    _currentFramePath=filePath;
    if(filePath){
        _CLFrameView *view = [[_CLFrameView alloc] initWithImage:[UIImage imageWithContentsOfFile:filePath] tool:self frame:_workingView.frame];
        view.frame=CGRectMake(0, 0, _workingView.frame.size.width, _workingView.frame.size.height);
        [_workingView addSubview:view];
        [_CLFrameView setActiveStickerView:view];
    }
    
    view.alpha = 0.2;
    [UIView animateWithDuration:kCLImageToolAnimationDuration
                     animations:^{
                         view.alpha = 1;
                     }
     ];
}

- (UIImage*)buildImage:(UIImage*)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    [image drawAtPoint:CGPointZero];
    
    CGFloat scale = image.size.width / _workingView.width;
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), scale, scale);
    [_workingView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return tmp;
}

@end


@implementation _CLFrameView
{
    UIImageView *_imageView;
    UIButton *_deleteButton;
    CLCircleView *_circleView;
    
    CGFloat _scale;
    CGFloat _arg;
    
    CGPoint _initialPoint;
    CGFloat _initialArg;
    CGFloat _initialScale;
}

+ (void)setActiveStickerView:(_CLFrameView*)view
{
    static _CLFrameView *activeView = nil;
    if(view != activeView){
        [activeView setAvtive:NO];
        activeView = view;
        [activeView setAvtive:YES];
        
        [activeView.superview bringSubviewToFront:activeView];
    }
}

- (id)initWithImage:(UIImage *)image tool:(CLFrameTool*)tool frame:(CGRect)rect
{
    self = [super initWithFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    if(self){
        _imageView = [[UIImageView alloc] initWithImage:image];
        //        _imageView.center = self.center;
        _imageView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height);
        [_imageView setContentMode:UIViewContentModeScaleToFill];
        [self addSubview:_imageView];
        _imageView.userInteractionEnabled = YES;
        _scale = 1;
        _arg = 0;
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* view= [super hitTest:point withEvent:event];
    if(view==self){
        return nil;
    }
    return view;
}

- (UIImageView*)imageView
{
    return _imageView;
}

- (void)pushedDeleteBtn:(id)sender
{
    _CLFrameView *nextTarget = nil;
    
    const NSInteger index = [self.superview.subviews indexOfObject:self];
    
    for(NSInteger i=index+1; i<self.superview.subviews.count; ++i){
        UIView *view = [self.superview.subviews objectAtIndex:i];
        if([view isKindOfClass:[_CLFrameView class]]){
            nextTarget = (_CLFrameView*)view;
            break;
        }
    }
    
    if(nextTarget==nil){
        for(NSInteger i=index-1; i>=0; --i){
            UIView *view = [self.superview.subviews objectAtIndex:i];
            if([view isKindOfClass:[_CLFrameView class]]){
                nextTarget = (_CLFrameView*)view;
                break;
            }
        }
    }
    
    [[self class] setActiveStickerView:nextTarget];
    [self removeFromSuperview];
}

- (void)setAvtive:(BOOL)active
{
    _deleteButton.hidden = !active;
    _circleView.hidden = !active;
    _imageView.layer.borderWidth = (active) ? 1/_scale : 0;
}


@end
