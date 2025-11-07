//
//  EnrichedTextInputModule.h
//  ReactNativeEnriched
//
//  Created by Ivan Ignathuk on 04/11/2025.
//

#import <Foundation/Foundation.h>
#import <ReactNativeEnriched/RNEnrichedTextInputViewSpec.h>
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface EnrichedTextInputModule : NSObject<NativeEnrichedTextInputModuleSpec>
@property (nonatomic, weak) RCTBridge *bridge;

@end

NS_ASSUME_NONNULL_END
