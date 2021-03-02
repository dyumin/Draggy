//
//  main.m
//  Draggy
//
//  Created by El D on 02.03.2021.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

int main(const int argc, const char *argv[]) {
    @autoreleasepool {
        __auto_type const mainBundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
        __block NSRunningApplication *anotherInstance;
        // may be unreliable, but should do the job
        const __auto_type index = [NSWorkspace.sharedWorkspace.runningApplications indexOfObjectPassingTest:^BOOL(NSRunningApplication *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            const bool isEqual = [obj.bundleIdentifier isEqualToString:mainBundleIdentifier];
            if (isEqual) {
                anotherInstance = obj;
            }
            return isEqual;
        }];

        if (index != NSNotFound) {
            NSLog(@"%s: another instance already running: %@", __PRETTY_FUNCTION__, anotherInstance);
            return 0;
        }
    }

    return NSApplicationMain(argc, argv);
}
