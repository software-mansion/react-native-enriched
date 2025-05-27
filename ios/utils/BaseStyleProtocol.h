#pragma once
#import "StyleTypeEnum.h"
#import "StylePair.h"

@protocol BaseStyleProtocol <NSObject>
+ (StyleType)getStyleType;
- (instancetype _Nonnull)initWithEditor:(id _Nonnull)editor;
- (void)applyStyle:(NSRange)range;
- (void)addAttributes:(NSRange)range;
- (void)removeAttributes:(NSRange)range;
- (void)addTypingAttributes;
- (void)removeTypingAttributes;
- (BOOL)detectStyle:(NSRange)range;
- (BOOL)anyOccurence:(NSRange)range;
- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range;
@end
