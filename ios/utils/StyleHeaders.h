#pragma once
#import "BaseStyleProtocol.h"
#import "LinkData.h"

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
- (LinkData *)getCurrentLinkDataIn:(NSRange)range;
- (NSRange)getFullLinkRangeAt:(NSUInteger)location;
- (void)manageLinkTypingAttributes;
- (void)handleAutomaticLinks:(NSString *)word inRange:(NSRange)wordRange;
@end
