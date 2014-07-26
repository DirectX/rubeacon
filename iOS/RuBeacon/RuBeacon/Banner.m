//
//  Banner.m
//  RuBeacon
//
//  Created by Denis on 27.07.14.
//  Copyright (c) 2014 RuBeacon. All rights reserved.
//

#import "Banner.h"
#import "AFNetworking.h"
#import "UIKit+AFNetworking.h"

#define PROTOCOL_FORMAT @"banner://%@"

@class BannerLoader;


typedef void(^BannerLoaderCompleteBlock)(NSURL* url);
typedef void(^BannerLoaderErrorBlock)(NSError* error);


@interface BannerLoader : NSObject

@property (readonly) NSString* applicationKey;
@property (nonatomic) AFHTTPRequestOperationManager* requestOperationManager;

+ (BannerLoader*)shared;
- (id)init;
- (void)loadBanner:(BannerLoaderCompleteBlock)loaderCompleteBlock errorBlock:(BannerLoaderErrorBlock)loaderErrorBlock;

@end


#pragma mark -


@interface BannerView ()

- (UIImage*)closeButtonImageForState:(UIControlState)controlState size:(const CGSize)size;

@end


@implementation BannerView {
@private
    UIWebView* _webView;
    UIButton* _closeButton;
    NSMutableDictionary* _closeButtonImages;
    BannerViewBlock _closeBlock;
}

- (id)initWithFrame:(CGRect)frame placeId:(NSString*)placeId
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _placeId = placeId;
        
        _webView = [[UIWebView alloc] initWithFrame:self.bounds];
        _webView.delegate = self;
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_webView];
        
        _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.bounds.size.width - 20.0f - 4.0f, 4.0f, 20.0f, 20.0f)];
        _closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_closeButton setImage:[self closeButtonImageForState:UIControlStateNormal size:CGSizeMake(20.0f, 20.0f)] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
}

- (void)show:(BannerViewBlock)completeBlock errorBlock:(BannerViewErrorBlock)errorBlock closeBlock:(BannerViewBlock)closeBlock {
    _closeBlock = closeBlock;
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html"]]
                 progress:nil
                  success:^NSString* (NSHTTPURLResponse* response, NSString* HTML) {
                      _closeButton.alpha = 0.0f;
                      [self addSubview:_closeButton];
                      
                      [UIView animateWithDuration:0.3f delay:1.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                          _closeButton.alpha = 0.5f;
                      } completion:nil];
                      
                      if (completeBlock)
                          completeBlock(self);
                      return HTML;
                  }
                  failure:nil
     ];
}

- (void)show {
    [self show:nil errorBlock:nil closeBlock:nil];
}

- (void)hide {
    if (_closeBlock) {
        _closeBlock(self);
        _closeBlock = nil;
    }
    
    [_closeButton removeFromSuperview];
}

#pragma mark UIWebViewDelegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = [request URL];
    
    if ([url.scheme isEqualToString:@"banner"]) {
        if ([url.host isEqualToString:@"close"]) {
            [self hide];
        }
        else if ([url.host isEqualToString:@"expand"]) {
            FullscreenBanner* fullscreenBanner = [[FullscreenBanner alloc] initWithPlaceId:_placeId];
            [fullscreenBanner show];
        }
        else if ([url.host isEqualToString:@"open"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[url.absoluteString substringFromIndex:18]]];
        }
        
        return NO;
    }
    
    return YES;
}

#pragma mark Private methods

// Формирование изображения кнопки закрытия баннера
- (UIImage*)closeButtonImageForState:(UIControlState)controlState size:(const CGSize)size
{
	if (!_closeButtonImages)
		_closeButtonImages = [NSMutableDictionary new];
	
	NSString *imageKey = [NSString stringWithFormat:@"%@%i", NSStringFromCGSize(size), (int)controlState];
	UIImage *image = [_closeButtonImages objectForKey:imageKey];
	if (image)
		return image;
    
    CGFloat scale = [[UIScreen mainScreen]respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f;
	
	// Создаем контекст для рисования
	if (UIGraphicsBeginImageContextWithOptions != NULL)
		UIGraphicsBeginImageContextWithOptions(size, NO, scale);
	else
        UIGraphicsBeginImageContext(size);
	// Добываем на него указатель
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Вычисляем основные параметры иконки
	const CGFloat margin = rintf(size.height / 8.0f);
	const CGRect rect = CGRectMake(margin, margin, size.width - 2.0f * margin, size.height - 2.0f * margin);
	
	// Рисуем круг
	CGContextAddEllipseInRect(context, rect);
	CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
	CGContextSetShadowWithColor(context, CGSizeMake(0, 1), 2, [UIColor blackColor].CGColor);
	CGContextFillPath(context);
	
	// Рисуем внутренний круг
	const CGRect innerRect = CGRectInset(rect, margin / 2., margin / 2.);
	CGContextAddEllipseInRect(context, innerRect);
	CGContextSetFillColorWithColor(context, (controlState == UIControlStateHighlighted ? [UIColor lightGrayColor].CGColor : (controlState == UIControlStateDisabled ? [UIColor grayColor].CGColor : [UIColor darkGrayColor].CGColor)));
	CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
	CGContextFillPath(context);
	
	// Рисуем крестик
	CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
	CGContextSetLineWidth(context, margin * 2/3.);
	const CGPoint center = CGPointMake(rect.origin.x + rect.size.width / 2, rect.origin.y + rect.size.height / 2);
	const CGFloat radiusX = (innerRect.size.width - 2*margin) / 2;
	const CGFloat radiusY = (innerRect.size.height - 2*margin) / 2;
	static const CGFloat Koef = M_SQRT2 / 2.; // cos(π/4) = sin(π/4) = (√2)/2
	// Справа-сверху влево-вниз [↙]
	CGContextMoveToPoint(context,    center.x + radiusX * Koef, center.y + radiusY * Koef);
	CGContextAddLineToPoint(context, center.x - radiusX * Koef, center.y - radiusY * Koef);
	CGContextStrokePath(context);
	// Слева-сверху вправо-вниз [↘]
	CGContextMoveToPoint(context,    center.x - radiusX * Koef, center.y + radiusY * Koef);
	CGContextAddLineToPoint(context, center.x + radiusX * Koef, center.y - radiusY * Koef);
	CGContextStrokePath(context);
	
	// Получаем нарисованную картинку
	image = UIGraphicsGetImageFromCurrentImageContext();
	// Закрываем созданный контекст
	UIGraphicsEndImageContext();
	
	[_closeButtonImages setObject:image forKey:imageKey];
	return image;
}

@end


#pragma mark -


@interface FullscreenBannerViewController : UIViewController

- (void)show:(BannerViewBlock)completeBlock errorBlock:(BannerViewErrorBlock)errorBlock closeBlock:(BannerViewBlock)closeBlock;

@end


@implementation FullscreenBannerViewController {
    BannerView* _banner;
}

- (id)initWithPlaceId:(NSString*)placeId
{
    self = [super init];
    
    if (self) {
        _banner = [[BannerView alloc] initWithFrame:[[UIScreen mainScreen] bounds] placeId:placeId];
        self.view = _banner;
    }
    
    return self;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)show:(BannerViewBlock)completeBlock errorBlock:(BannerViewErrorBlock)errorBlock closeBlock:(BannerViewBlock)closeBlock {
    
    UIWindow* window = (([UIApplication sharedApplication].delegate).window);
    
    [_banner show:^(BannerView *bannerView) {
        [[window rootViewController] presentViewController:self animated:YES completion:^{
            if (completeBlock)
                completeBlock(_banner);
        }];
    } errorBlock:^(BannerView *bannerView, NSError *error) {
        if (errorBlock)
            errorBlock(_banner, errorBlock);
    } closeBlock:^(BannerView *bannerView) {
        [self dismissViewControllerAnimated:YES completion:^{
            if (closeBlock)
                closeBlock(_banner);
        }];
    }];
}

- (void)hide {
    [_banner hide];
}

@end


#pragma mark -


@implementation FullscreenBanner {
@private
    BannerView* _banner;
    FullscreenBannerViewController* _bannerViewController;
}

- (id)initWithPlaceId:(NSString*)placeId
{
    self = [super init];
    
    if (self) {
        _banner = [[BannerView alloc] initWithFrame:[[UIScreen mainScreen] bounds] placeId:placeId];
        _bannerViewController = [[FullscreenBannerViewController alloc] initWithPlaceId:placeId];
    }
    
    return self;
}


- (void)show:(BannerViewBlock)completeBlock errorBlock:(BannerViewErrorBlock)errorBlock closeBlock:(BannerViewBlock)closeBlock {
    [_bannerViewController show:completeBlock errorBlock:errorBlock closeBlock:closeBlock];
}

- (void)show {
    [self show:nil errorBlock:nil closeBlock:nil];
}

- (void)hide {
    [_bannerViewController hide];
}

@end
