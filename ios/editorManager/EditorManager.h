#pragma once
#import <UIKit/UIKit.h>

@interface EditorManager : NSObject
@property (nonatomic, weak) id currentEditor;
+ (instancetype)sharedManager;
@end
