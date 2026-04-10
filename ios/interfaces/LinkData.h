#pragma once
#import <UIKit/UIKit.h>

@interface LinkData : NSObject <NSCopying>

@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSString *url;
@property(nonatomic, assign) BOOL isManual;
- (BOOL)isEqualToLinkData:(LinkData *)linkData;

@end
