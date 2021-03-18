//
//  DragSessionManager.h
//  Draggy
//
//  Created by El D on 20.02.2021.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

// Unfortunately it still will be available in compilation units whose headers included in Draggy-Bridging-Header.h, at least for .m files (HudWindow.m)
// NS_UNAVAILABLE seems to also fail there
// Dunno why
#if !defined(__swift__)
#define ONLY_SWIFT_AVAILABLE NS_UNAVAILABLE
#else
#define ONLY_SWIFT_AVAILABLE
#endif

typedef NS_ENUM(NSUInteger, PasteboardItemType) {
    FileURL,
    URL
};

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(_DragSessionManagerImpl)
@interface DragSessionManagerImpl : NSObject

@property(nonatomic, readonly, nullable) NSURL *currentPasteboardURL;

@property(nonatomic, readonly) BOOL willCloseWindow;

@property(nonatomic) NSWindow *hudWindow; // supposed to be set right after initialisation

- (instancetype)init ONLY_SWIFT_AVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)closeWindow;

- (void)applicationDidBecomeActive;

@end

NS_ASSUME_NONNULL_END
