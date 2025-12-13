@interface HTMLNode : NSObject
@property(nonatomic, strong) NSMutableArray<HTMLNode *> *children;
@end

@interface HTMLElement : HTMLNode
@property(nonatomic) const char *tag;
@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *attributes;
@property(nonatomic) BOOL selfClosing;
@end

@interface HTMLTextNode : HTMLNode
@property(nonatomic) NSString *source;
@property(nonatomic) NSRange range;
@end
