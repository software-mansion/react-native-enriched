#pragma once
#import "ImageAttachment.h"
#import "InputConfig.h"
#import <UIKit/UIKit.h>

@interface AttachmentLayoutUtils : NSObject

+ (void)handleAttachmentUpdate:(MediaAttachment *)attachment
                      textView:(UITextView *)textView
                 onLayoutBlock:(dispatch_block_t)layoutBlock;

+ (NSMutableDictionary<NSValue *, UIImageView *> *)
    layoutAttachmentsInTextView:(UITextView *)textView
                         config:(InputConfig *)config
                  existingViews:
                      (NSMutableDictionary<NSValue *, UIImageView *> *)
                          attachmentViews;

+ (CGRect)frameForAttachment:(ImageAttachment *)attachment
                     atRange:(NSRange)range
                    textView:(UITextView *)textView
                      config:(InputConfig *)config;

@end
