#import "ParagraphsUtils.h"

@implementation ParagraphsUtils

+ (NSArray *)getSeparateParagraphsRangesIn:(UITextView *)textView range:(NSRange)range {
  // just in case, get full paragraphs range
  NSRange fullRange = [textView.textStorage.string paragraphRangeForRange:range];
  
  // we are in an empty paragraph
  if(fullRange.length == 0) {
    return @[[NSValue valueWithRange:fullRange]];
  }
  
  NSMutableArray *results = [[NSMutableArray alloc] init];
  
  NSInteger lastStart = fullRange.location;
  for(int i = fullRange.location; i < fullRange.location + fullRange.length; i++) {
    unichar currentChar = [textView.textStorage.string characterAtIndex:i];
    if([[NSCharacterSet newlineCharacterSet] characterIsMember:currentChar]) {
      NSRange paragraphRange = [textView.textStorage.string paragraphRangeForRange:NSMakeRange(lastStart, i - lastStart)];
      [results addObject: [NSValue valueWithRange:paragraphRange]];
      lastStart = i+1;
    }
  }
  
  if(lastStart < fullRange.location + fullRange.length) {
    NSRange paragraphRange = [textView.textStorage.string paragraphRangeForRange:NSMakeRange(lastStart, fullRange.location + fullRange.length - lastStart)];
    [results addObject: [NSValue valueWithRange:paragraphRange]];
  }
  
  return results;
}

@end
