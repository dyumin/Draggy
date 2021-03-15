//
//  DragSessionManager.m
//  Draggy
//
//  Created by El D on 20.02.2021.
//

#import "DragSessionManager.h"
#import "Draggy-Swift.h" // DragSessionManager

@interface DragSessionManagerImpl ()

@property(nonatomic) NSURL *currentPasteboardURL;
@property(nonatomic) BOOL willCloseWindow;

@end

@implementation DragSessionManagerImpl {
    NSArray<NSPasteboardType> *_acceptedPasteboardTypes;
    NSWindow *_hudWindow;
    NSInteger _eventNumber;
    NSInteger _ignoreEventNumber;
    NSPasteboard *_dragPasteboard;
    NSArray<NSPasteboardItem *> *_lastPasteboardItems;
    bool _stopTracking;
    dispatch_block_t _postponedCloseWindow;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _acceptedPasteboardTypes = @[NSPasteboardTypeFileURL, NSPasteboardTypeString];

        _dragPasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
        _lastPasteboardItems = _dragPasteboard.pasteboardItems;

//        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskPressure handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
//
//            return event;
//        }];

        [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp | NSEventMaskPressure handler:^(NSEvent *_Nonnull event) {
            const NSInteger eventNumber = event.eventNumber;

            const NSEventType eventType = event.type;
            if (eventType == NSEventMaskPressure) { // TODO: global NSEventMaskPressure isn't working

            }

            if (eventNumber == self->_ignoreEventNumber) {
                // first drag event does not yep adds elements to pasteboard
                if ([self->_lastPasteboardItems isEqualToArray:self->_dragPasteboard.pasteboardItems]) // todo: refactor
                {
//                    NSLog(@"return var 3");
                    return;
                }

                self->_ignoreEventNumber = 0;
            }

            if (eventType == NSEventTypeLeftMouseUp) {
                if (self->_eventNumber) {
                    self->_eventNumber = 0;

                    self->_lastPasteboardItems = self->_dragPasteboard.pasteboardItems;
                    self->_hudWindow.level = NSNormalWindowLevel;

                    [self resetPostponedClose];
                    if (!NSApplication.sharedApplication.isActive) {
                        const __auto_type wself = self;
                        // close window automatically if no user interaction will happen in 1 minute
                        self->_postponedCloseWindow = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
                            const __auto_type sself = wself;
                            if (!sself) {
                                return;
                            }
                            const NSTimeInterval animationDuration = 1.2;
                            [sself closeWindowWithAnimationDuration:&animationDuration];
                            sself->_postponedCloseWindow = nil;
                        });
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC), dispatch_get_main_queue(), self->_postponedCloseWindow);
                    }
                }

                return;
            }

            if (!self->_eventNumber) {
                NSArray<NSPasteboardItem *> *pasteboardItems = self->_dragPasteboard.pasteboardItems;

                if (pasteboardItems.count != 1) { // multiple items support currently disabled
//                    NSLog(@"return var 1");
                    self->_ignoreEventNumber = eventNumber;
                    return;
                }

                if ([self->_lastPasteboardItems isEqualToArray:pasteboardItems]) {
//                    NSLog(@"return var 4");
                    self->_ignoreEventNumber = eventNumber;
                    return;
                }

                // https://stackoverflow.com/questions/56199062/get-uti-of-nspasteboardtypefileurl
//                            NSArray<NSURL*>* urls = [_dragPasteboard readObjectsForClasses:@[ NSURL.class ] options:nil]; // slow if there are a lot of elements

                bool anyUrlFound = false;
                NSPasteboardType type;
                for (NSPasteboardItem *item in pasteboardItems) {
                    if ((type = [item availableTypeFromArray:self->_acceptedPasteboardTypes])) {
                        if ([type isEqualToString:NSPasteboardTypeFileURL]) {
                            NSURL *url = [NSURL URLFromPasteboard:self->_dragPasteboard];
                            if (url) {
                                anyUrlFound = true;
                                [(DragSessionManager*)self setPasteboardItem:url with:FileURL];
                                self.currentPasteboardURL = url;
                                break;
                            }
                        } else if ([type isEqualToString:NSPasteboardTypeString]) {
                            NSString *pasteboardText = [self->_dragPasteboard stringForType:NSPasteboardTypeString];
                            if (![pasteboardText containsString:@"youtube.com/watch?"]) // TODO: use appopriate regex
                                continue;
                            NSURL *url = [NSURL URLWithString:pasteboardText];
                            if (url) {
                                anyUrlFound = true;
                                [(DragSessionManager*)self setPasteboardItem:url with:URL];
                                self.currentPasteboardURL = url;
                                break;
                            }
                        }
                    }
                }

                if (!anyUrlFound) {
//                    NSLog(@"return var 2");
                    self->_ignoreEventNumber = eventNumber;
                    return;
                }
            }

            if (self->_eventNumber != eventNumber) {
                self->_willCloseWindow = false; // prevent previous (close) animation (if any) from closing window in [NSAnimationContext.currentContext setCompletionHandler:]
                [self resetPostponedClose];
                self->_eventNumber = eventNumber;
                self->_stopTracking = false;
                self->_hudWindow.level = NSPopUpMenuWindowLevel;
                [self->_hudWindow orderFrontRegardless];
                [NSAnimationContext beginGrouping];
                [NSAnimationContext.currentContext setDuration:0.05];
                NSAnimationContext.currentContext.completionHandler = ^{
                    self->_stopTracking = true;
                };
                self->_hudWindow.animator.alphaValue = 1;
                [NSAnimationContext endGrouping];
            }

            if (!self->_stopTracking) {
                const __auto_type hudWindowHeight = self->_hudWindow.frame.size.height;
                [self->_hudWindow setFrame:NSMakeRect(NSEvent.mouseLocation.x + 10, NSEvent.mouseLocation.y - hudWindowHeight, self->_hudWindow.frame.size.width, hudWindowHeight) display:YES animate:NO];
            }
        }];
    }
    return self;
}

- (void)applicationDidBecomeActive {
    [self resetPostponedClose];
    if (self->_willCloseWindow) { // prevent previous (close) animation (if any) from closing window in [NSAnimationContext.currentContext setCompletionHandler:] and restore _hudWindow alphaValue
        self->_willCloseWindow = false;
        self->_hudWindow.animator.alphaValue = 1;
    }
}

- (void)resetPostponedClose {
    if (self->_postponedCloseWindow) {
        dispatch_block_cancel(self->_postponedCloseWindow);
        self->_postponedCloseWindow = nil;
    }
}

- (void)closeWindow {
    [self resetPostponedClose];
    if (self->_willCloseWindow) { // already closing, _postponedCloseWindow block was able to run (?)
        // actually I have no idea how to get to this case, but lets leave it here
        // initial idea was that func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool
        // may be triggered while window is closing, but that currently should be impossible
        return;
    }
    [self closeWindowWithAnimationDuration:nil];
}

- (void)closeWindowWithAnimationDuration:(const NSTimeInterval *const)duration {
    self->_willCloseWindow = true;
    [NSAnimationContext beginGrouping];
    [NSAnimationContext.currentContext setCompletionHandler:^{
//                        NSLog(@"All done! _hudWindow close");
        if (self->_willCloseWindow) {
            [self->_hudWindow close];
            self->_willCloseWindow = false;
        }
    }];
    if (duration) {
        NSAnimationContext.currentContext.duration = *duration;
    }
    self->_hudWindow.animator.alphaValue = 0;
    [NSAnimationContext endGrouping];
}

+ (instancetype)sharedInstance {
    static id _sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

@end
