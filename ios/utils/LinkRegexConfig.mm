#import "LinkRegexConfig.h"
#import "StringExtension.h"

@implementation LinkRegexConfig

- (instancetype)initWithLinkRegexProp:
    (EnrichedTextInputViewLinkRegexStruct)prop {
  if (!self)
    return nil;

  _pattern = [NSString fromCppString:prop.pattern];
  _caseInsensitive = prop.caseInsensitive;
  _dotAll = prop.dotAll;
  _isDefault = prop.isDefault;
  _isDisabled = prop.isDisabled;

  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  LinkRegexConfig *copy = [[[self class] allocWithZone:zone] init];
  copy->_pattern = [_pattern copy];
  copy->_caseInsensitive = _caseInsensitive;
  copy->_dotAll = _dotAll;
  copy->_isDefault = _isDefault;
  copy->_isDisabled = _isDisabled;
  return copy;
}

- (BOOL)isEqualToConfig:(LinkRegexConfig *)otherObj {
  return [_pattern isEqualToString:otherObj.pattern] &&
         _caseInsensitive == otherObj.caseInsensitive &&
         _dotAll == otherObj.dotAll && _isDefault == otherObj.isDefault &&
         _isDisabled == otherObj.isDisabled;
}

@end
