//
//  HudWindow.h
//  Draggy
//
//  Created by El D on 02.03.2021.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HudWindow : NSObject

@property(nonatomic, readonly) NSWindow *hudWindow;

@property(class, readonly) HudWindow* sharedInstance NS_SWIFT_NAME(shared);

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

- (void)loadContentView; // contentview depends on HudWindow.sharedInstance hence the separate step

@end

NS_ASSUME_NONNULL_END
