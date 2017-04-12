//
//  ProgressView.h
//  ;
//
//  Created by Damandeep Kaur on 20/02/16.
//  Copyright © 2016 Damandeep Kaur. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProgressView : UIView
//{
//    UIBezierPath * bezierPath;
//}
//@property (nonatomic) float duration;
@property (nonatomic) BOOL canDelete;
-(void)setProgress:(NSNumber*)value;
-(void)prepareToDelete;
//@property(nonatomic,retain) UIBezierPath * bezierPath;
//- (void)addPathInRect:(CGRect)rectToRedraw;
@end
