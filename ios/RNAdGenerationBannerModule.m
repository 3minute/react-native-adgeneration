//
//  RNAdGenerationBannerModule.m
//  RNAdGeneration
//
//  Created by chuross on 2018/05/26.
//  Copyright © 2018年 Facebook. All rights reserved.
//
#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(RNAdGenerationBannerManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(locationId, NSString)
RCT_EXPORT_VIEW_PROPERTY(locationType, NSString)
RCT_EXPORT_VIEW_PROPERTY(bannerType, NSString)
RCT_EXPORT_VIEW_PROPERTY(bannerWidth, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(bannerHeight, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(onMeasure, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onReceiveAdFailed, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onTapAd, RCTBubblingEventBlock);

RCT_EXTERN_METHOD(load:(nonnull NSNumber *) node)

@end
