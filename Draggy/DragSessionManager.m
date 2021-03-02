//
//  DragSessionManager.m
//  Draggy
//
//  Created by El D on 20.02.2021.
//

#import "DragSessionManager.h"

@interface DragSessionManager ()

@property(nonatomic) NSURL *current;
@property(nonatomic) BOOL willCloseWindow;

@end

@implementation DragSessionManager {
    NSArray<NSPasteboardType> *_acceptedPasteboardTypes;
    NSWindow *_hudWindow;
    NSInteger _eventNumber;
    NSInteger _ignoreEventNumber;
    NSPasteboard *_dragPasteboard;
    NSArray<NSPasteboardItem *> *_lastPasteboardItems;
    __kindof NSViewController *_dragTargetViewController;
    bool _stopTracking;
    bool _dontCloseOnMouseUp;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _acceptedPasteboardTypes = @[NSPasteboardTypeFileURL];

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

                    // TODO: debug disabled
//                    [self closeWindow];
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
                        anyUrlFound = true;
                        self.current = [NSURL URLFromPasteboard:self->_dragPasteboard];
                        break;
                    }
                }

                if (!anyUrlFound) {
//                    NSLog(@"return var 2");
                    self->_ignoreEventNumber = eventNumber;
                    return;
                }
            }

            if (self->_eventNumber != eventNumber) {
                self->_eventNumber = eventNumber;
                self->_stopTracking = false;
                self->_hudWindow.level = NSPopUpMenuWindowLevel;
                [self->_hudWindow orderFrontRegardless]; // todo: what if previous (close) animation still active
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

- (void)closeWindow {
    self->_willCloseWindow = true;
    [NSAnimationContext beginGrouping];
    [NSAnimationContext.currentContext setCompletionHandler:^{
//                        NSLog(@"All done! _hudWindow close");
        [self->_hudWindow close];
        self->_willCloseWindow = false;
    }];
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
