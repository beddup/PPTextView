//
//  PPTextView.m
//  PPTextView
//
//  Created by Amay on 9/28/15.
//  Copyright © 2015 Beddup. All rights reserved.
//

#import "PPTextView.h"
#import <MobileCoreServices/MobileCoreServices.h>

//custom NSTextAttachment
@interface PPImageTextAttachment: NSTextAttachment
@property(copy,nonatomic,readonly)NSString *identifer;
-(instancetype)initWithImage:(UIImage *)image bounds:(CGRect)bounds;
@end

@implementation PPImageTextAttachment
-(instancetype)initWithImage:(UIImage *)image bounds:(CGRect)bounds{
    self = [super init];
    if (self) {
        _identifer=[@([[NSDate date] timeIntervalSince1970]) stringValue];
        self.image=image;
        self.bounds=bounds;
    }
    return self;
}

-(instancetype)initWithData:(NSData *)contentData ofType:(NSString *)uti{
    self=[super initWithData:contentData ofType:uti];
    if (self) {
        _identifer=[@([[NSDate date] timeIntervalSince1970]) stringValue];
    }
    return self;
}
@end


@interface PPTextView()<NSTextStorageDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIScrollViewDelegate>

@property(nonatomic)BOOL typeBullet;
@property(nonatomic)BOOL typeForward;

@property(nonatomic,weak)UILabel* placeHolderLabel;

@property(nonatomic,strong)NSAttributedString *bulletsImageString;

@property(weak,nonatomic)UIButton *insertPhotoButton;
@property(weak,nonatomic)UIButton *insertBulletButton;
@property(weak,nonatomic)UIButton *convertTVToPhoto;

@property(strong,nonatomic)NSMutableDictionary *attachmentImages; // this dictionary may use much memory, remove it if you don't need tap to display the full size image

@end

@implementation PPTextView

-(UIImage*)contentImage{

    CGSize size=CGSizeMake(self.contentSize.width, self.contentSize.height);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    UIBezierPath *path=[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, size.width, size.height)];
    [self.backgroundColor setFill];
    [path fill];
    [self.textStorage drawWithRect:CGRectMake(8,8, size.width, size.height) options:NSStringDrawingUsesLineFragmentOrigin context:nil];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;

}

-(NSMutableDictionary *)attachmentImages{
    if (!_attachmentImages) {
        _attachmentImages=[@{} mutableCopy];
    }
    return _attachmentImages;
}
-(NSAttributedString *)bulletsImageString{

    if (!_bulletsImageString){
        UIImage *image=[UIImage imageNamed:@"bulletIcon"];
        CGRect bounds=CGRectMake(0, 0, self.font.pointSize, self.font.pointSize);
        PPImageTextAttachment *attachment=[[PPImageTextAttachment alloc]initWithImage:image bounds:bounds];
        _bulletsImageString=[self attributedStringWithAttachment:attachment];
    }
    return _bulletsImageString;
    
}
-(void)setPlaceHolder:(NSString *)placeHolder{
    _placeHolder=placeHolder;
    self.placeHolderLabel.text=placeHolder;
}
-(void)setContainsPhotos:(BOOL)containsPhotos{
    _containsPhotos=containsPhotos;
    if (!containsPhotos) {
        return;
    }
    if (!self.inputAccessoryView) {
        [self configInputAccessoryView];
    }
    UIButton *photoButton=[[UIButton alloc]init];
    [self.inputAccessoryView addSubview:photoButton];
    [photoButton setBackgroundImage:[UIImage imageNamed:@"photoIcon"] forState:UIControlStateNormal];
    [photoButton addTarget:self action:@selector(photoButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.insertPhotoButton=photoButton;
}
-(void)setContainsBullets:(BOOL)containsBullets{

    _containsBullets=containsBullets;
    if (!containsBullets) {
        return;
    }
    if (!self.inputAccessoryView) {
        [self configInputAccessoryView];
    }
    UIButton *listButton=[[UIButton alloc]init];
    [self.inputAccessoryView addSubview:listButton];
    [listButton setBackgroundImage:[UIImage imageNamed:@"listIcon"] forState:UIControlStateNormal];
    [listButton addTarget:self action:@selector(listButtonTouched:) forControlEvents:UIControlEventTouchUpInside];

    self.insertBulletButton=listButton;
}
-(void)configInputAccessoryView{
    self.inputAccessoryView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 44)];
    self.inputAccessoryView.backgroundColor=[UIColor colorWithWhite:0.9 alpha:1.0];
    UIButton *dismissKBButton=[[UIButton alloc]init];
    [self.inputAccessoryView addSubview:dismissKBButton];
    [dismissKBButton setBackgroundImage:[UIImage imageNamed:@"dismissKBIcon"] forState:UIControlStateNormal];
    [dismissKBButton addTarget:self action:@selector(dismissKB:) forControlEvents:UIControlEventTouchUpInside];

    dismissKBButton.translatesAutoresizingMaskIntoConstraints=NO;
    NSLayoutConstraint *dismissKBCTrailing=[NSLayoutConstraint constraintWithItem:dismissKBButton attribute: NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.inputAccessoryView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0];
    NSLayoutConstraint *dismissKBCCenterY=[NSLayoutConstraint constraintWithItem:dismissKBButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.inputAccessoryView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    NSLayoutConstraint *dismissKBCWidth=[NSLayoutConstraint constraintWithItem:dismissKBButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:44];
    NSLayoutConstraint *dismissKBCHeight=[NSLayoutConstraint constraintWithItem:dismissKBButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:44];
    [dismissKBButton addConstraints:@[dismissKBCWidth,dismissKBCHeight]];
    [self.inputAccessoryView addConstraints:@[dismissKBCTrailing,dismissKBCCenterY]];

    UIButton *convertTVToPhoto=[[UIButton alloc]init];
    self.convertTVToPhoto=convertTVToPhoto;
    convertTVToPhoto.hidden=YES;// if no generateContentImageCompletionHandler,then hide this button;
    [self.inputAccessoryView addSubview:convertTVToPhoto];
    [convertTVToPhoto setBackgroundImage:[UIImage imageNamed:@"toImageIcon"] forState:UIControlStateNormal];
    [convertTVToPhoto addTarget:self action:@selector(convertToImage:) forControlEvents:UIControlEventTouchUpInside];
    convertTVToPhoto.translatesAutoresizingMaskIntoConstraints=NO;
    NSLayoutConstraint *convertTVTrailing=[NSLayoutConstraint constraintWithItem:convertTVToPhoto attribute: NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:dismissKBButton attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint *convertTVCenterY=[NSLayoutConstraint constraintWithItem:convertTVToPhoto attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.inputAccessoryView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    NSLayoutConstraint *convertTVWidth=[NSLayoutConstraint constraintWithItem:convertTVToPhoto attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:44];
    NSLayoutConstraint *convertTVHeight=[NSLayoutConstraint constraintWithItem:convertTVToPhoto attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:44];
    [convertTVToPhoto addConstraints:@[convertTVWidth,convertTVHeight]];
    [self.inputAccessoryView addConstraints:@[convertTVTrailing,convertTVCenterY]];

}

#pragma mark - actions
-(void)listButtonTouched:(UIButton *)button{
    self.typeBullet=!self.typeBullet;
    [button setBackgroundImage:[UIImage imageNamed:self.typeBullet ? @"listIconSelected":@"listIcon"] forState:UIControlStateNormal];
}
- (void)photoButtonTouched:(UIButton *)button {

    // get the current visible viewcontroller to present the alert contorller
    [self resignFirstResponder];
    UIViewController *visibleVC=[self viewControllerWhichHasThisTextView];
    UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIAlertAction *pickFromLibrary=[UIAlertAction actionWithTitle:@"从相册中选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImagePickerController *imagePicker=[self imagePicker];
            imagePicker.sourceType=UIImagePickerControllerSourceTypePhotoLibrary;

            [visibleVC presentViewController:imagePicker animated:YES completion:nil];
        }];
        [alertController addAction:pickFromLibrary];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertAction *pickFromcamera=[UIAlertAction actionWithTitle:@"拍摄照片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImagePickerController *imagePicker=[self imagePicker];
            imagePicker.sourceType=UIImagePickerControllerSourceTypeCamera;
            [visibleVC presentViewController:imagePicker animated:YES completion:nil];
        }];
        [alertController addAction:pickFromcamera];
    }

    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self becomeFirstResponder];
    }]];

    [visibleVC presentViewController:alertController animated:YES completion:nil];
}
- (void)dismissKB:(UIButton *)button {
    [self resignFirstResponder];
}

-(void)convertToImage:(UIButton *)button{
    [self resignFirstResponder];

    UIImage *newImage = [self contentImage];
    self.generateContentImageCompletionHandler(newImage);

}

#pragma mark - private methods
-(NSAttributedString *)attributedStringWithAttachment:(NSTextAttachment *)attachment{

    NSMutableAttributedString *attachmentString=[[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
    [attachmentString addAttributes:@{NSFontAttributeName:self.font} range:NSMakeRange(0, attachmentString.length)];
    return [attachmentString copy];

}
-(UIViewController *)viewControllerWhichHasThisTextView{
    UIView *view=self;
    while (![view.nextResponder isKindOfClass:[UIViewController class]]) {
        view=view.superview;
    }
    return (UIViewController *)view.nextResponder;
}


#pragma mark - UIImagePickerController
-(UIImagePickerController *)imagePicker{

    UIImagePickerController *imagePicker=[[UIImagePickerController alloc]init];
    imagePicker.delegate=self;
    return imagePicker;

}

- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize) size

{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{

    self.placeHolderLabel.hidden=YES;

    UIImage *image=info[UIImagePickerControllerOriginalImage];
    CGFloat ratio=image.size.height/image.size.width;
    CGFloat width=MIN(self.textContainer.size.width-16,image.size.width);
    CGFloat height=width *ratio;
    CGRect bounds=CGRectMake(0, 0, width, height);

    UIImage *scaleImage=[self scaleImage:image toSize:CGSizeMake(width, height)];
    PPImageTextAttachment *imageAttachment=[[PPImageTextAttachment alloc]initWithImage:scaleImage bounds:bounds];

    [self.attachmentImages setObject:image forKey:imageAttachment.identifer];

    NSRange selectedRange=self.selectedRange;
    NSAttributedString *returnString=[[NSAttributedString alloc]initWithString:@"\n" attributes:@{NSFontAttributeName:self.font}];
    [self.textStorage insertAttributedString:returnString atIndex:selectedRange.location];

    NSAttributedString *mediaString=[self attributedStringWithAttachment:imageAttachment];
    [self.textStorage insertAttributedString:mediaString atIndex:selectedRange.location+1];
    [self.textStorage insertAttributedString:returnString atIndex:selectedRange.location+2];

    [picker dismissViewControllerAnimated:YES completion:^{
        self.selectedRange=NSMakeRange(selectedRange.location+3, 0);
        [self scrollRangeToVisible:NSMakeRange(selectedRange.location+2, 0)];
        self.contentSize=CGSizeMake(self.contentSize.width, self.contentSize.height+height);
        [self becomeFirstResponder];
    }];

}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - NSTextStorageDelegate
-(void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta{
    self.typeForward=delta>0;
}
#pragma  mark -tap to show image full screen
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    if (touches.count==1 && !self.editable) {
        UITouch *touch=[touches anyObject];
        CGPoint location=[touch locationInView:self];
        NSUInteger characterIndex=[self.layoutManager characterIndexForPoint:location inTextContainer:self.textContainer fractionOfDistanceBetweenInsertionPoints:NULL];
        if (characterIndex >= self.textStorage.length) {
            return;
        }

        NSDictionary *attribute=[self.textStorage attributesAtIndex:characterIndex effectiveRange:NULL];
        NSTextAttachment *attachment=attribute[NSAttachmentAttributeName];

        if ([attachment isKindOfClass:[PPImageTextAttachment class]]) {
            NSString *identifer=((PPImageTextAttachment *)attachment).identifer;
            UIImage *image=self.attachmentImages[identifer] ? self.attachmentImages[identifer]: attachment.image;

            // show image
            UIView *topView=[self viewControllerWhichHasThisTextView].view;
            UIScrollView *scrollView=[[UIScrollView alloc]init];
            scrollView.backgroundColor=[UIColor blackColor];
            scrollView.delegate=self;
            scrollView.contentSize=CGSizeMake(CGRectGetWidth(topView.bounds), CGRectGetHeight(topView.bounds));
            scrollView.minimumZoomScale=1;
            scrollView.maximumZoomScale=2;
            UIImageView *imageView=[[UIImageView alloc]initWithImage:image];
            imageView.contentMode=UIViewContentModeScaleAspectFit;
            [scrollView addSubview:imageView];

            UITapGestureRecognizer *tapToDismiss=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissImage:)];
            [scrollView addGestureRecognizer:tapToDismiss];

            //animation
            [topView addSubview:scrollView];
            //get the image attachement rect in topView;
            NSUInteger glyphIndex=[self.layoutManager glyphIndexForCharacterAtIndex:characterIndex];
            CGPoint glyphLocation=[self.layoutManager locationForGlyphAtIndex:glyphIndex];
            CGSize attachmentSize=[self.layoutManager attachmentSizeForGlyphAtIndex:glyphIndex];
            CGPoint attachmentLocation=CGPointMake(glyphLocation.x, glyphLocation.y-attachmentSize.height);
            CGPoint locationInView=[topView convertPoint:attachmentLocation fromView:self];
            AnimatedImageAttachmentInitalRectInTopView=CGRectMake(locationInView.x, locationInView.y, attachmentSize.width,attachmentSize.height);
            CGRect finalRect=topView.bounds;

            scrollView.frame=AnimatedImageAttachmentInitalRectInTopView;
            imageView.frame=scrollView.bounds;
            [scrollView layoutIfNeeded];
            scrollView.alpha=0.1;
            [UIView animateWithDuration:0.8 delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
                scrollView.frame=finalRect;
                imageView.frame=scrollView.bounds;
                scrollView.alpha=1.0;
            } completion:nil];
        }

    }
}
static CGRect AnimatedImageAttachmentInitalRectInTopView;
-(void)dismissImage:(UIGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        UIView *view=gesture.view;
        [UIView animateWithDuration:0.8 delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionLayoutSubviews animations:^{
            view.frame=AnimatedImageAttachmentInitalRectInTopView;
            [view.subviews firstObject].frame=view.bounds;
            view.alpha=0.1;
        } completion:^(BOOL finished) {
            [gesture.view removeFromSuperview];
        }];

    }
}

#pragma mark- scroll view delegate
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return [scrollView.subviews firstObject];
}

#pragma mark - override super
-(void)layoutSubviews{
    if (self.insertBulletButton) {
        self.insertBulletButton.frame=CGRectMake(8, 0, 44, 44);
        self.insertPhotoButton.frame=CGRectOffset(self.insertBulletButton.frame, 44, 0);
    }else{
        self.insertPhotoButton.frame=CGRectMake(8, 0, 44, 44);
    }
    if (self.generateContentImageCompletionHandler) {
        self.convertTVToPhoto.hidden=NO;
    }


}
-(void)setFont:(UIFont *)font{
    [super setFont:font];
    self.placeHolderLabel.font=font;
}


#pragma  mark - setup
-(void)awakeFromNib{
    [self setup];
}

-(void)setup{

    self.textStorage.delegate=self;
    //default font
    self.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    //place holder label
    UILabel *placeHolderLabel=[[UILabel alloc]initWithFrame:CGRectMake(6, 0, 200, 35)];
    placeHolderLabel.textColor=[UIColor lightGrayColor];
    [self addSubview:placeHolderLabel];
    self.placeHolderLabel=placeHolderLabel;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ppTextViewDidChange:) name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ppTextViewDidEndEditing:) name:UITextViewTextDidEndEditingNotification object:nil];

}

-(instancetype)initWithFrame:(CGRect)frame{
    self=[super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UITextViewTextDidEndEditingNotification object:nil];
}

#pragma mark -UITextViewTextNotification
- (void)ppTextViewDidChange:(NSNotification *)notification {
    self.placeHolderLabel.hidden=self.text.length;
    if (self.typeBullet){
        NSRange selectedRange=self.selectedRange;
        if ([self.text characterAtIndex:selectedRange.location-1]=='\n' && self.typeForward) {
            // return key pressed,

            [self.textStorage insertAttributedString:self.bulletsImageString atIndex:selectedRange.location];
            self.selectedRange=NSMakeRange(selectedRange.location+1, 0);
        }
    }
}

- (void)ppTextViewDidEndEditing:(NSNotification *)notification {
    [self setContentOffset:self.contentOffset animated:YES];
    [self.layoutManager invalidateDisplayForCharacterRange:NSMakeRange(0,self.textStorage.length)];
    [self layoutIfNeeded];
}
@end
