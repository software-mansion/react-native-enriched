#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AttributedStringBuilder : NSObject

@property(nonatomic, weak) NSDictionary *stylesDict;

- (void)apply:(NSArray *)processedStyles
     toAttributedString:(NSMutableAttributedString *)attributedString
    offsetFromBeginning:(NSInteger)offset
      conflictingStyles:
          (NSDictionary<NSNumber *, NSArray<NSNumber *> *> *)conflictingStyles;

@end
