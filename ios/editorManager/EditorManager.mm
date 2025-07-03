#import "EditorManager.h"

@implementation EditorManager

+ (instancetype)sharedManager {
  static EditorManager *sharedManager = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedManager = [[self alloc] init];
  });
  return sharedManager;
}

@end
