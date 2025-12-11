#import <UIKit/UIKit.h>

@class MediaAttachment;

@protocol MediaAttachmentDelegate <NSObject>
- (void)mediaAttachmentDidUpdate:(MediaAttachment *)attachment;
@end

@interface MediaAttachment : NSTextAttachment

@property(nonatomic, weak) id<MediaAttachmentDelegate> delegate;
@property(nonatomic, strong) NSString *uri;
@property(nonatomic, assign) CGFloat width;
@property(nonatomic, assign) CGFloat height;

- (instancetype)initWithURI:(NSString *)uri
                      width:(CGFloat)width
                     height:(CGFloat)height;

- (void)loadAsync;
- (void)notifyUpdate;

@end
