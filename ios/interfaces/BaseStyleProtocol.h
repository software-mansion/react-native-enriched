#pragma once
#import "StylePair.h"
#import "StyleTypeEnum.h"

@protocol BaseStyleProtocol <NSObject>
+ (StyleType)getStyleType;
+ (BOOL)isParagraphStyle;
- (instancetype _Nonnull)initWithInput:(id _Nonnull)input;
- (void)applyStyle:(NSRange)range;
- (void)addAttributes:(NSRange)range withTypingAttr:(BOOL)withTypingAttr;
- (void)removeAttributes:(NSRange)range;
- (void)addTypingAttributes;
- (void)removeTypingAttributes;
- (BOOL)detectStyle:(NSRange)range;
- (BOOL)anyOccurence:(NSRange)range;
- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range;
@end
