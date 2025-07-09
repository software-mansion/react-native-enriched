#pragma once
#import "BaseStyleProtocol.h"
#import "LinkData.h"
#import "MentionParams.h"

@interface BoldStyle : NSObject <BaseStyleProtocol>
@end

@interface ItalicStyle : NSObject <BaseStyleProtocol>
@end

@interface UnderlineStyle : NSObject <BaseStyleProtocol>
@end

@interface StrikethroughStyle : NSObject <BaseStyleProtocol>
@end

@interface InlineCodeStyle : NSObject <BaseStyleProtocol>
@end

@interface LinkStyle : NSObject <BaseStyleProtocol>
- (void)addLink:(NSString*)text url:(NSString*)url range:(NSRange)range manual:(BOOL)manual;
- (LinkData *)getLinkDataAt:(NSUInteger)location;
- (NSRange)getFullLinkRangeAt:(NSUInteger)location;
- (void)manageLinkTypingAttributes;
- (void)handleAutomaticLinks:(NSString *)word inRange:(NSRange)wordRange;
- (void)handleManualLinks:(NSString *)word inRange:(NSRange)wordRange;
@end

@interface MentionStyle : NSObject<BaseStyleProtocol>
- (void)addMention:(NSString *)indicator text:(NSString *)text attributes:(NSString *)attributes;
- (void)addMentionAtRange:(NSRange)range params:(MentionParams *)params;
- (void)startMentionWithIndicator:(NSString *)indicator;
- (void)handleExistingMentions;
- (void)manageMentionEditing;
- (void)manageMentionTypingAttributes;
- (MentionParams *)getMentionParamsAt:(NSUInteger)location;
- (NSRange)getFullMentionRangeAt:(NSUInteger)location;
- (NSValue *)getActiveMentionRange;
@end

@interface HeadingStyleBase : NSObject<BaseStyleProtocol> {
  id editor;
}
- (CGFloat)getHeadingFontSize;
@end

@interface H1Style : HeadingStyleBase
@end

@interface H2Style : HeadingStyleBase
@end

@interface H3Style : HeadingStyleBase
@end

@interface UnorderedListStyle : NSObject<BaseStyleProtocol>
- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text;
- (BOOL)tryHandlingListShorcutInRange:(NSRange)range replacementText:(NSString *)text;
- (void)handleListItemWithChangeRange:(NSRange)range;
@end

@interface OrderedListStyle : NSObject<BaseStyleProtocol>
- (BOOL)handleBackspaceInRange:(NSRange)range replacementText:(NSString *)text;
- (BOOL)tryHandlingListShorcutInRange:(NSRange)range replacementText:(NSString *)text;
- (void)handleListItemWithChangeRange:(NSRange)range;
@end

@interface BlockQuoteStyle : NSObject<BaseStyleProtocol>
@end
