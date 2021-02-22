//
//  DragSessionManager.h
//  Draggy
//
//  Created by El D on 20.02.2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DragSessionManager : NSObject

@property (nonatomic, readonly) NSURL* current;

+ (instancetype)sharedInstance NS_SWIFT_NAME(shared());

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
