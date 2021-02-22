//
//  DragSessionManager.m
//  Draggy
//
//  Created by El D on 20.02.2021.
//

#import "DragSessionManager.h"
#import <Cocoa/Cocoa.h>

static NSString *const DragTargetViewStoryboardName = @"DragTargetView";
static NSWindowFrameAutosaveName const WindowRestorationFrameName = @"DraggyWindow";

@interface DragSessionManager ()

@property(nonatomic) NSURL *current;

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

        _hudWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 264, 406) styleMask:(NSWindowStyleMaskResizable|NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskFullSizeContentView) backing:NSBackingStoreBuffered defer:YES /* saves a couple mb on start */];
        _hudWindow.frameAutosaveName = WindowRestorationFrameName;

        _hudWindow.releasedWhenClosed = NO;
        _hudWindow.titlebarAppearsTransparent = YES;

        _hudWindow.opaque = NO;
        _hudWindow.hasShadow = NO;
        _hudWindow.backgroundColor = NSColor.clearColor;

        _hudWindow.level = NSPopUpMenuWindowLevel;

        NSVisualEffectView *hudBackground = [NSVisualEffectView new];
        if (@available(macOS 10.14, *)) {
            hudBackground.material = NSVisualEffectMaterialHUDWindow;
        } else {
            hudBackground.material = NSVisualEffectMaterialSidebar;
        }
        hudBackground.state = NSVisualEffectStateActive;

        hudBackground.wantsLayer = YES;
        hudBackground.emphasized = YES;

        hudBackground.layer.cornerRadius = 20.0;
        hudBackground.layer.masksToBounds = YES; // Note: NSWindowStyleMaskTitled required in order for this to take effect

        _hudWindow.contentView = hudBackground;

        NSStoryboard *dragTargetViewStoryboard = [NSStoryboard storyboardWithName:DragTargetViewStoryboardName bundle:nil];

        _dragTargetViewController = dragTargetViewStoryboard.instantiateInitialController;
        NSView *contentView = _dragTargetViewController.view;
        [hudBackground addSubview:contentView];

        contentView.wantsLayer = YES;

        [contentView.topAnchor constraintEqualToAnchor:hudBackground.topAnchor].active = YES;
        [contentView.bottomAnchor constraintEqualToAnchor:hudBackground.bottomAnchor].active = YES;
        [contentView.leadingAnchor constraintEqualToAnchor:hudBackground.leadingAnchor].active = YES;
        [contentView.trailingAnchor constraintEqualToAnchor:hudBackground.trailingAnchor].active = YES;

        contentView.translatesAutoresizingMaskIntoConstraints = NO;

//        [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskPressure handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
//
//            return event;
//        }];

        [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp | NSEventMaskPressure handler:^(NSEvent *_Nonnull event) {
            const NSInteger eventNumber = event.eventNumber;

            const NSEventType eventType = event.type;
            if (eventType == NSEventMaskPressure) { // TODO: global NSEventMaskPressure isnt working

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

                    // TODO: debug disabled
//                    [NSAnimationContext beginGrouping];
//                    [NSAnimationContext.currentContext setCompletionHandler:^{
////                        NSLog(@"All done! _hudWindow close");
//                        [self->_hudWindow close];
//                    }];
//                    [NSAnimationContext.currentContext setDuration:0.3];
//                    self->_hudWindow.animator.alphaValue = 0;
//                    [NSAnimationContext endGrouping];
                }

                return;
            }

            if (!self->_eventNumber) {
                NSArray<NSPasteboardItem *> *pasteboardItems = self->_dragPasteboard.pasteboardItems;

                if (!pasteboardItems.count) {
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
                [self->_hudWindow orderFrontRegardless]; // todo: what if previous (close) animation still active
                [NSAnimationContext beginGrouping];
                [NSAnimationContext.currentContext setDuration:0.05];
                NSAnimationContext.currentContext.completionHandler = ^{
                    self->_stopTracking = true;
                };
                self->_hudWindow.animator.alphaValue = 1;
                [NSAnimationContext endGrouping];
            }

            if (!self->_stopTracking)
                [self->_hudWindow setFrame:NSMakeRect(NSEvent.mouseLocation.x, NSEvent.mouseLocation.y, self->_hudWindow.frame.size.width, self->_hudWindow.frame.size.height) display:YES animate:NO];
        }];
    }
    return self;
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
