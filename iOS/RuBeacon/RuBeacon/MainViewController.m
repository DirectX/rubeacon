//
//  MainViewController.m
//  RuBeacon
//
//  Created by Denis on 27.07.14.
//  Copyright (c) 2014 RuBeacon. All rights reserved.
//

#import "MainViewController.h"
#import "Banner.h"


@interface MainViewController ()

@end

@implementation MainViewController {
    BannerView* _banner;
    FullscreenBanner* _fullscreenBanner;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _banner = [[BannerView alloc] initWithFrame:CGRectMake(0.0f, 20.0f, self.view.frame.size.width, 50.0f) placeId:@"News"];
    _banner.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [self showBanner];
    
//    _fullscreenBanner = [[FullscreenBanner alloc] initWithPlaceId:@"News"];
//    [_fullscreenBanner show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)showBanner {
    [_banner show:^(BannerView *bannerView) {
        bannerView.alpha = 0.0f;
        [self.view addSubview:bannerView];
        [UIView animateWithDuration:0.3f animations:^{
            bannerView.alpha = 1.0f;
        } completion:nil];
    } errorBlock:^(BannerView *bannerView, NSError *error) {
        NSLog(@"%@", error);
    } closeBlock:^(BannerView *bannerView) {
        [UIView animateWithDuration:0.3f animations:^{
            bannerView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [bannerView removeFromSuperview];
        }];
    }];
}

@end
