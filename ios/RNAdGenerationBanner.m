//
//  RNAdGenerationBanner.m
//  RNAdGeneration
//
//  Created by chuross on 2018/05/28.
//  Copyright © 2018年 Facebook. All rights reserved.
//
#import "RNAdGenerationBanner.h"
#import <ADG/ADG.h>
#import "FBAudienceNetwork.h"

//#define MIN(a,b)    ((a) < (b) ? (a) : (b))

/**
 * Extension
 */
@interface RNAdGenerationBanner() <ADGManagerViewControllerDelegate, FBNativeAdDelegate>

@property (nonatomic) ADGManagerViewController *adg;

@end


/**
 * Implementation
 */
@implementation RNAdGenerationBanner : UIView

- (void)dealloc
{
    self.adg.delegate = nil;
    self.adg = nil;
}

- (void)load
{
    if (self.locationId == nil) {
        return;
    }
    if (self.bannerType == nil) {
        return;
    }
    if (self.bannerType == nil) {
        if(self.bannerWidth == nil || self.bannerHeight == nil) {
            return;
        }
    }
    
    NSMutableDictionary *params = @{}.mutableCopy;
    [params setObject:self.locationId forKey:@"locationid"];
    
    NSDictionary *event;
    if ([self.bannerType isEqualToString:@"sp"]) {
        [params setObject:@(kADG_AdType_Sp) forKey:@"adtype"];
        event = @{ @"width": @(kADGAdSize_Sp_Width), @"height": @(kADGAdSize_Sp_Height) };
    }
    if ([self.bannerType isEqualToString:@"rect"]) {
        [params setObject:@(kADG_AdType_Rect) forKey:@"adtype"];
        event = @{ @"width": @(kADGAdSize_Rect_Width), @"height": @(kADGAdSize_Rect_Height) };
    }
    if ([self.bannerType isEqualToString:@"large"]) {
        [params setObject:@(kADG_AdType_Large) forKey:@"adtype"];
        event = @{ @"width": @(kADGAdSize_Large_Width), @"height": @(kADGAdSize_Large_Height) };
    }
    if ([self.bannerType isEqualToString:@"tablet"]) {
        [params setObject:@(kADG_AdType_Tablet) forKey:@"adtype"];
        event = @{ @"width": @(kADGAdSize_Tablet_Width), @"height": @(kADGAdSize_Tablet_Height) };
    }
    if ([self.bannerType isEqualToString:@"free"]) {
        [params setObject:@(kADG_AdType_Free) forKey:@"adtype"];
        [params setObject:self.bannerHeight forKey:@"h"];
        [params setObject:self.bannerWidth forKey:@"w"];
        event = @{ @"width": self.bannerWidth, @"height": self.bannerHeight };
    }
    
    if (self.onMeasure) {
        self.onMeasure(event);
    }
    
    self.adg = [[ADGManagerViewController new] initWithAdParams:params adView:self];
    self.adg.delegate = self;
    self.adg.usePartsResponse = YES;
    [self.adg loadRequest];
}

- (void)ADGManagerViewControllerReceiveAd:(ADGManagerViewController *)adgManagerViewController
                        mediationNativeAd:(id)mediationNativeAd {
    NSLog(@"Received an ad.");
    
    UIView *nativeAdView;
    if ([mediationNativeAd isKindOfClass: [ADGNativeAd class]]) {
        UIView *adgNativeAdView = [self createNativeAdView:mediationNativeAd];
        //        [adgNativeAdView apply:(ADGNativeAd *)mediationNativeAd viewController:self];
        nativeAdView = adgNativeAdView;
    } else if ([mediationNativeAd isKindOfClass: [FBNativeAd class]]) {
        UIView *fbNativeAdView = [self createFBAdView:mediationNativeAd];
        //        [fbNativeAdView apply:(FBNativeAd *)mediationNativeAd
        //               viewController:self];
        nativeAdView = fbNativeAdView;
    }
    
    if (nativeAdView) {
        // ローテーション時に自動的にViewを削除します
        [adgManagerViewController setAutomaticallyRemoveOnReload:nativeAdView];
        
        [self addSubview:nativeAdView];
    }
}

- (void)ADGManagerViewControllerFailedToReceiveAd:(ADGManagerViewController *)adgManagerViewController code:(kADGErrorCode)code
{
    switch (code) {
        case kADGErrorCodeNeedConnection:
        case kADGErrorCodeExceedLimit:
        case kADGErrorCodeNoAd:
            if (self.onReceiveAdFailed) {
                self.onReceiveAdFailed(@{@"locationId":self.locationId, @"reason":@"noAd"});
            }
            break;
        default:
            [self.adg loadRequest];
            break;
    }
}

- (void)ADGManagerViewControllerDidTapAd:(ADGManagerViewController *)adgManagerViewController
{
    NSLog(@"Did tap the ad.");
    if (self.onTapAd) {
        self.onTapAd(@{@"locationId":self.locationId});
    }
}

- (UIView *)createNativeAdView:(ADGNativeAd *)mediationNativeAd
{
    if ([self.locationType isEqualToString:@"2"]) {
        float ratio = MIN([self.bannerWidth floatValue]/300,[self.bannerHeight floatValue]/250);
        // セルの全体View
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(([self.bannerWidth floatValue]-300*ratio)/2,0,300*ratio,250*ratio)];
        
        // 左部：アイコン、タイトル、動画View
        UIView *imageView = [[UIView alloc] initWithFrame:CGRectMake(0,0,300*ratio,195*ratio)];
        
        UIImageView *imageIconView;
        if (mediationNativeAd.iconImage.url.length > 0) {
            NSURL *iconImageUrl = [NSURL URLWithString:mediationNativeAd.iconImage.url];
            NSData *iconImageData = [NSData dataWithContentsOfURL:iconImageUrl];
            imageIconView = [[UIImageView alloc]initWithFrame:CGRectMake(4*ratio,4*ratio,30*ratio,30*ratio)];
            imageIconView.image = [UIImage imageWithData:iconImageData];
            imageIconView.clipsToBounds = true;
            [imageIconView setContentMode:UIViewContentModeScaleAspectFit];
            [imageView addSubview:imageIconView];
        }
        
        //// タイトルラベル
        UILabel *tLabel = [[UILabel alloc] initWithFrame:CGRectMake(mediationNativeAd.iconImage.url.length > 0?38*ratio:9*ratio,9*ratio,258*ratio,20*ratio)];
        [tLabel setNumberOfLines:1];
        [tLabel setFont:[UIFont systemFontOfSize:16*ratio]];
        [tLabel setTextColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]];
        tLabel.text = mediationNativeAd.title ? mediationNativeAd.title.text : @"";
        
        [imageView addSubview:tLabel];
        
        //// メインイメージ
        UIImageView *mainImageView;
        if (mediationNativeAd.mainImage.url.length > 0) {
            NSURL *mainImageUrl = [NSURL URLWithString:mediationNativeAd.mainImage.url];
            NSData *mainImageData = [NSData dataWithContentsOfURL:mainImageUrl];
            mainImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0,38*ratio,300*ratio,157*ratio)];
            mainImageView.image = [UIImage imageWithData:mainImageData];
            mainImageView.clipsToBounds = true;
            [mainImageView setContentMode:UIViewContentModeScaleAspectFit];
            [imageView addSubview:mainImageView];
        }
        
        // 右部：本文、PR、スポンサー名View
        UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(0,195*ratio,300*ratio,55*ratio)];
        
        //// 本文ラベル
        UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(4*ratio,4*ratio,292*ratio,22*ratio)];
        [bodyLabel setNumberOfLines:1];
        [bodyLabel setFont:[UIFont systemFontOfSize:11*ratio]];
        bodyLabel.text = mediationNativeAd.desc ? mediationNativeAd.desc.value : @"";
        [infoView addSubview:bodyLabel];
        //// PRラベル
        UILabel *prLabel = [[UILabel alloc] initWithFrame:CGRectMake(4*ratio,32.5*ratio,28*ratio,20*ratio)];
        [prLabel setFont:[UIFont systemFontOfSize:10*ratio]];
        [prLabel setText:@"PR"];
        [prLabel setTextAlignment:NSTextAlignmentCenter];
        [prLabel setTextColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]];
        [prLabel setBackgroundColor:[UIColor colorWithRed:255/255.0 green:127.5/255.0 blue:0/255.0 alpha:1.0]];
        // [prLabel.layer setBorderColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1.0].CGColor];
        // [prLabel.layer setBorderWidth:1];
        [infoView addSubview:prLabel];
        //// スポンサー名ラベル
        UILabel *sponLabel = [[UILabel alloc] initWithFrame:CGRectMake(36*ratio,36*ratio,260*ratio,12*ratio)];
        [sponLabel setTextAlignment:NSTextAlignmentLeft];
        [sponLabel setFont:[UIFont systemFontOfSize:10]];
        [sponLabel setTextColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]];
        sponLabel.text = mediationNativeAd.sponsored.value.length > 0 ?
        [NSString stringWithFormat:@"%@",mediationNativeAd.sponsored.value] :
        @"sponsored";
        [infoView addSubview:sponLabel];
        
        [view addSubview:imageView];
        [view addSubview:infoView];
        
        // クリック領域
        [mediationNativeAd setTapEvent:self handler:^{
            if (self.onTapAd) {
                self.onTapAd(@{@"locationId":self.locationId});
            }
        }];
        
        return view;
    }else {
        // セルの全体View
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,[self.bannerWidth floatValue],[self.bannerHeight floatValue])];
        
        // 左部：イメージ、動画View
        UIView *imageView = [[UIView alloc] initWithFrame:CGRectMake(0,0,180,[self.bannerHeight floatValue])];
        UIImageView *imageMainView;
        if (mediationNativeAd.mainImage.url.length > 0) {
            NSURL *mainImageUrl = [NSURL URLWithString:mediationNativeAd.mainImage.url];
            NSData *mainImageData = [NSData dataWithContentsOfURL:mainImageUrl];
            imageMainView = [[UIImageView alloc]initWithFrame:CGRectMake(10,10,160,90)];
            imageMainView.image = [UIImage imageWithData:mainImageData];
            [imageView addSubview:imageMainView];
        }
        
        // 右部：タイトル、PR、スポンサー名View
        UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(imageView.frame.size.width,
                                                                    0,
                                                                    [self.bannerWidth floatValue] - imageView.frame.size.width,
                                                                    [self.bannerHeight floatValue])];
        //// タイトルラベル
        UILabel *tLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                    10,
                                                                    infoView.frame.size.width -20,
                                                                    [self.bannerHeight floatValue])];
        [tLabel setNumberOfLines:3];
        [tLabel setFont:[UIFont systemFontOfSize:14]];
        tLabel.text = mediationNativeAd.title ? mediationNativeAd.title.text : @"";
        //// タイトルラベルの上寄せ
        CGRect rect = tLabel.frame;
        [tLabel sizeToFit];
        rect.size.height = CGRectGetHeight(tLabel.frame);
        tLabel.frame = rect;
        [infoView addSubview:tLabel];
        //// PRラベル
        UILabel *prLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,90,20,10)];
        [prLabel setFont:[UIFont systemFontOfSize:10]];
        [prLabel setText:@"PR"];
        [prLabel setTextAlignment:NSTextAlignmentCenter];
        [prLabel setTextColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1.0]];
        [prLabel.layer setBorderColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1.0].CGColor];
        [prLabel.layer setBorderWidth:1];
        [infoView addSubview:prLabel];
        //// スポンサー名ラベル
        float sponWidth = infoView.frame.size.width - 10;
        UILabel *sponLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,90,sponWidth,13)];
        [sponLabel setTextAlignment:NSTextAlignmentRight];
        [sponLabel setFont:[UIFont systemFontOfSize:10]];
        [sponLabel setTextColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1.0]];
        sponLabel.text = mediationNativeAd.sponsored.value.length > 0 ?
        [NSString stringWithFormat:@"%@",mediationNativeAd.sponsored.value] :
        @"sponsored";
        [infoView addSubview:sponLabel];
        
        [view addSubview:imageView];
        [view addSubview:infoView];
        
        [mediationNativeAd setTapEvent:self handler:^{
            if (self.onTapAd) {
                self.onTapAd(@{@"locationId":self.locationId});
            }
        }];
        
        return view;
    }
    
}

- (UIView *)createFBAdView:(FBNativeAd *)mediationFBAd
{
    if ([self.locationType isEqualToString:@"2"]) {
        float ratio = MIN([self.bannerWidth floatValue]/300,[self.bannerHeight floatValue]/250);
        // セルの全体View
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(([self.bannerWidth floatValue]-300*ratio)/2,0,300*ratio,250*ratio)];
        
        // 左部：アイコン、タイトル、動画View
        UIView *imageView = [[UIView alloc] initWithFrame:CGRectMake(0,0,300*ratio,195*ratio)];
        //// 画像アイコン
        FBAdIconView *imageIconView;
        imageIconView = [[FBAdIconView alloc]initWithFrame:CGRectMake(4*ratio,4*ratio,30*ratio,30*ratio)];
        [imageView addSubview:imageIconView];
        //// タイトルラベル
        UILabel *tLabel = [[UILabel alloc] initWithFrame:CGRectMake(38*ratio,9*ratio,258*ratio,20*ratio)];
        [tLabel setNumberOfLines:1];
        [tLabel setFont:[UIFont systemFontOfSize:16*ratio]];
        [tLabel setTextColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]];
        tLabel.text = mediationFBAd.headline ? mediationFBAd.headline : @"";
        [imageView addSubview:tLabel];
        //// 動画
        UIView  *FBMediaViewCon = [[UIView alloc] initWithFrame:CGRectMake(0,38*ratio,300*ratio,157*ratio)];
        FBMediaView *mediaView = [[FBMediaView alloc] initWithFrame:CGRectMake(0,0,300*ratio,157*ratio)];
        [FBMediaViewCon setClipsToBounds:true];
        [FBMediaViewCon addSubview:mediaView];
        //// FANのiマーク
        FBAdChoicesView *adChoices = [[FBAdChoicesView alloc] initWithNativeAd:mediationFBAd expandable:YES];
        adChoices.backgroundShown = NO;
        [FBMediaViewCon addSubview:adChoices];
        [adChoices updateFrameFromSuperview:UIRectCornerTopRight];
        [imageView addSubview:FBMediaViewCon];
        
        // 右部：本文、PR、スポンサー名View
        UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(0,195*ratio,300*ratio,55*ratio)];
        
        //// 本文ラベル
        UILabel *bodyLabel = [[UILabel alloc] initWithFrame:CGRectMake(4*ratio,4*ratio,292*ratio,22*ratio)];
        [bodyLabel setNumberOfLines:1];
        [bodyLabel setFont:[UIFont systemFontOfSize:11*ratio]];
        bodyLabel.text = mediationFBAd.bodyText ? mediationFBAd.bodyText : @"";
        [infoView addSubview:bodyLabel];
        //// PRラベル
        UILabel *prLabel = [[UILabel alloc] initWithFrame:CGRectMake(4*ratio,32.5*ratio,28*ratio,20*ratio)];
        [prLabel setFont:[UIFont systemFontOfSize:10*ratio]];
        [prLabel setText:@"PR"];
        [prLabel setTextAlignment:NSTextAlignmentCenter];
        [prLabel setTextColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]];
        [prLabel setBackgroundColor:[UIColor colorWithRed:255/255.0 green:127.5/255.0 blue:0/255.0 alpha:1.0]];
        // [prLabel.layer setBorderColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1.0].CGColor];
        // [prLabel.layer setBorderWidth:1];
        [infoView addSubview:prLabel];
        //// スポンサー名ラベル
        UILabel *sponLabel = [[UILabel alloc] initWithFrame:CGRectMake(36*ratio,36*ratio,116*ratio,12*ratio)];
        [sponLabel setTextAlignment:NSTextAlignmentLeft];
        [sponLabel setFont:[UIFont systemFontOfSize:10]];
        [sponLabel setTextColor:[UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]];
        sponLabel.text = mediationFBAd.socialContext.length > 0 ?
        [NSString stringWithFormat:@"%@",mediationFBAd.socialContext] :
        @"sponsored";
        [infoView addSubview:sponLabel];
        //// ctaラベル
        UILabel *ctaLabel = [[UILabel alloc] initWithFrame:CGRectMake(156*ratio,31*ratio,140*ratio,23*ratio)];
        [ctaLabel setTextAlignment:NSTextAlignmentCenter];
        [ctaLabel setFont:[UIFont systemFontOfSize:10]];
        [ctaLabel setTextColor:[UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]];
        [ctaLabel setBackgroundColor: [UIColor colorWithRed:51/255.0 green:204/255.0 blue:0/255.0 alpha:1.0]];
        ctaLabel.text = mediationFBAd.socialContext.length > 0 ?[NSString stringWithFormat:@"%@",mediationFBAd.callToAction] :@"";
        ctaLabel.layer.masksToBounds = YES;
        ctaLabel.layer.cornerRadius = 5.0;
        [infoView addSubview:ctaLabel];
        
        [view addSubview:imageView];
        [view addSubview:infoView];
        
        mediationFBAd.delegate = self;
        // クリック領域
        NSArray *clickableViews = @[imageView, infoView];
        [mediationFBAd registerViewForInteraction:self
                                        mediaView:mediaView
                                        iconView:imageIconView
                                viewController:nil
                                clickableViews:clickableViews];
        
        return view;
    }else {
        // セルの全体View
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,[self.bannerWidth floatValue],[self.bannerHeight floatValue])];
        
        // 左部：イメージ、動画View
        UIView *imageView = [[UIView alloc] initWithFrame:CGRectMake(0,0,180,[self.bannerHeight floatValue])];
        //// 画像アイコン
        FBAdIconView *imageIconView;
        imageIconView = [[FBAdIconView alloc]initWithFrame:CGRectMake(10,10,160,90)];
        [imageView addSubview:imageIconView];
        //// 動画
        UIView  *FBMediaViewCon = [[UIView alloc] initWithFrame:CGRectMake(10,10,160,90)];
        FBMediaView *mediaView = [[FBMediaView alloc] initWithFrame:CGRectMake(0,0,160,90)];
        [FBMediaViewCon addSubview:mediaView];
        //// FANのiマーク
        FBAdChoicesView *adChoices = [[FBAdChoicesView alloc] initWithNativeAd:mediationFBAd expandable:YES];
        adChoices.backgroundShown = NO;
        [FBMediaViewCon addSubview:adChoices];
        [adChoices updateFrameFromSuperview:UIRectCornerTopRight];
        [imageView addSubview:FBMediaViewCon];
        
        // 右部：タイトル、PR、スポンサー名View
        UIView *infoView = [[UIView alloc] initWithFrame:CGRectMake(imageView.frame.size.width,
                                                                    0,
                                                                    [self.bannerWidth floatValue] - imageView.frame.size.width,
                                                                    [self.bannerHeight floatValue])];
        //// タイトルラベル
        UILabel *tLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                    10,
                                                                    infoView.frame.size.width -20,
                                                                    [self.bannerHeight floatValue])];
        [tLabel setNumberOfLines:3];
        [tLabel setFont:[UIFont systemFontOfSize:14]];
        tLabel.text = mediationFBAd.headline ? mediationFBAd.headline : @"";
        //// タイトルラベルの上寄せ
        CGRect rect = tLabel.frame;
        [tLabel sizeToFit];
        rect.size.height = CGRectGetHeight(tLabel.frame);
        tLabel.frame = rect;
        [infoView addSubview:tLabel];
        //// PRラベル
        UILabel *prLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,90,20,10)];
        [prLabel setFont:[UIFont systemFontOfSize:10]];
        [prLabel setText:@"PR"];
        [prLabel setTextAlignment:NSTextAlignmentCenter];
        [prLabel setTextColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1.0]];
        [prLabel.layer setBorderColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1.0].CGColor];
        [prLabel.layer setBorderWidth:1];
        [infoView addSubview:prLabel];
        //// スポンサー名ラベル
        float sponWidth = infoView.frame.size.width - 10;
        UILabel *sponLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,90,sponWidth,13)];
        [sponLabel setTextAlignment:NSTextAlignmentRight];
        [sponLabel setFont:[UIFont systemFontOfSize:10]];
        [sponLabel setTextColor:[UIColor colorWithRed:159/255.0 green:159/255.0 blue:159/255.0 alpha:1.0]];
        sponLabel.text = mediationFBAd.socialContext.length > 0 ?
        [NSString stringWithFormat:@"%@",mediationFBAd.socialContext] :
        @"sponsored";
        [infoView addSubview:sponLabel];
        
        [view addSubview:imageView];
        [view addSubview:infoView];
        
        mediationFBAd.delegate = self;
        // クリック領域
        NSArray *clickableViews = @[imageView, infoView];
        [mediationFBAd registerViewForInteraction:self
                                        mediaView:mediaView
                                        iconView:imageIconView
                                viewController:nil
                                clickableViews:clickableViews];
        
        return view;
    }
    
}

-(void)nativeAdDidClick:(FBNativeAd *)nativeAd
{
    if (self.onTapAd) {
        self.onTapAd(@{@"locationId":self.locationId});
    }
}
@end
