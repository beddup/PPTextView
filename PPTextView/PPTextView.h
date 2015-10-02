//
//  PPTextView.h
//  PPTextView
//
//  Created by Amay on 9/28/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPTextView : UITextView

@property(copy,nonatomic)NSString *placeHolder;

@property(nonatomic)BOOL containsBullets; // whether the inputAccessoryView has a button that enable user to input bullet automatically when return key hit

@property(nonatomic)BOOL containsPhotos; // whether the inputAccessoryView has a button that enable user to insert photo

@property(copy,nonatomic) void(^generateContentImageCompletionHandler)(UIImage *contentImage);


@end
