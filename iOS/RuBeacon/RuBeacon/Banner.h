//
//  Banner.h
//  RuBeacon
//
//  Created by Denis on 27.07.14.
//  Copyright (c) 2014 RuBeacon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BannerView;


typedef void(^BannerViewBlock)(BannerView* bannerView);
typedef void(^BannerViewErrorBlock)(BannerView* bannerView, NSError* error);


@interface BannerView : UIView <UIWebViewDelegate>

@property (nonatomic, copy) NSString* placeId;

- (id)initWithFrame:(CGRect)frame placeId:(NSString*)placeId;
- (void)show:(BannerViewBlock)completeBlock errorBlock:(BannerViewErrorBlock)errorBlock closeBlock:(BannerViewBlock)closeBlock;
- (void)show;
- (void)hide;

@end


@interface FullscreenBanner : NSObject

@property (nonatomic, copy) NSString* placeId;

- (id)initWithPlaceId:(NSString*)placeId;
- (void)show:(BannerViewBlock)completeBlock errorBlock:(BannerViewErrorBlock)errorBlock closeBlock:(BannerViewBlock)closeBlock;
- (void)show;
- (void)hide;

@end
