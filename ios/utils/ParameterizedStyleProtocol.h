@protocol ParameterizedStyleProtocol <NSObject>

+ (NSDictionary<NSString *, NSString *> *_Nullable)getParametersFromValue:
    (id _Nullable)value;

@end
