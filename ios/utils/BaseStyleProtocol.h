#pragma once
#import "StylePair.h"
#import "StyleTypeEnum.h"

@protocol BaseStyleProtocol <NSObject>
+ (StyleType)getStyleType;
+ (BOOL)isParagraphStyle;
- (instancetype _Nonnull)initWithInput:(id _Nonnull)input;
- (void)applyStyle:(NSRange)range;
- (void)addAttributes:(NSRange)range;
- (void)addAttributesInAttributedString:
            (NSMutableAttributedString *_Nonnull)attributedString
                                  range:(NSRange)range;
- (void)removeAttributesInAttributedString:
            (NSMutableAttributedString *_Nonnull)attributedString
                                     range:(NSRange)range;
- (BOOL)detectStyleInAttributedString:
            (NSMutableAttributedString *_Nonnull)attributedString
                                range:(NSRange)range;
- (void)removeAttributes:(NSRange)range;
- (void)addTypingAttributes;
- (void)removeTypingAttributes;
- (BOOL)detectStyle:(NSRange)range;
- (BOOL)anyOccurence:(NSRange)range;
- (NSArray<StylePair *> *_Nullable)findAllOccurences:(NSRange)range;
- (NSArray<StylePair *> *_Nullable)
    findAllOccurencesInAttributedString:
        (NSAttributedString *_Nonnull)attributedString
                                  range:(NSRange)range;
@end
