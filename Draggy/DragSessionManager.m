//
//  DragSessionManager.m
//  Draggy
//
//  Created by El D on 20.02.2021.
//

#import "DragSessionManager.h"
#import <Cocoa/Cocoa.h>

@implementation DragSessionManager {
    NSArray<NSPasteboardType> *_acceptedPasteboardTypes;
    NSWindow *_hudWindow;
    NSInteger _eventNumber;
    NSInteger _ignoreEventNumber;
    NSPasteboard *_dragPasteboard;
    NSArray<NSPasteboardItem *> *_lastPasteboardItems;
    bool _stopTracking;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _acceptedPasteboardTypes = @[NSPasteboardTypeFileURL];

        _dragPasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
        _lastPasteboardItems = _dragPasteboard.pasteboardItems;

        _hudWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(20, 20, 100, 150) styleMask:(NSWindowStyleMaskBorderless | NSWindowStyleMaskResizable) backing:NSBackingStoreBuffered defer:NO];

        _hudWindow.releasedWhenClosed = NO;

        _hudWindow.opaque = NO;
        _hudWindow.hasShadow = NO;
        _hudWindow.backgroundColor = NSColor.clearColor;

        _hudWindow.level = NSPopUpMenuWindowLevel;

        NSView *contentView = [[NSView alloc] initWithFrame:NSMakeRect(100, 200, 300, 400)];
        contentView.wantsLayer = YES;

        NSVisualEffectView *hudBackground = [NSVisualEffectView new];
        if (@available(macOS 10.14, *)) {
            hudBackground.material = NSVisualEffectMaterialHUDWindow;
        } else {
            hudBackground.material = NSVisualEffectMaterialSidebar;
        }
        hudBackground.state = NSVisualEffectStateActive;

        hudBackground.wantsLayer = YES;

        hudBackground.layer.cornerRadius = 20.0;
        hudBackground.layer.masksToBounds = YES;

        _hudWindow.contentView = hudBackground;

        [hudBackground addSubview:contentView];

        [contentView.topAnchor constraintEqualToAnchor:hudBackground.topAnchor].active = YES;
        [contentView.bottomAnchor constraintEqualToAnchor:hudBackground.bottomAnchor].active = YES;
        [contentView.leadingAnchor constraintEqualToAnchor:hudBackground.leadingAnchor].active = YES;
        [contentView.trailingAnchor constraintEqualToAnchor:hudBackground.trailingAnchor].active = YES;

        contentView.translatesAutoresizingMaskIntoConstraints = NO;

        [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDragged | NSEventMaskLeftMouseUp handler:^(NSEvent *_Nonnull event) {
            const NSInteger eventNumber = event.eventNumber;
            if (eventNumber == self->_ignoreEventNumber) {
                // first drag event does not yep adds elements to pasteboard
                if ([self->_lastPasteboardItems isEqualToArray:self->_dragPasteboard.pasteboardItems]) // todo: refactor
                {
//                    NSLog(@"return var 3");
                    return;
                }

                self->_ignoreEventNumber = 0;
            }

            if (event.type == NSEventTypeLeftMouseUp) {
                if (self->_eventNumber) {
                    self->_eventNumber = 0;

                    self->_lastPasteboardItems = self->_dragPasteboard.pasteboardItems;

//                    [NSAnimationContext beginGrouping];
//                    [NSAnimationContext.currentContext setCompletionHandler:^{
//                        NSLog(@"All done! _hudWindow close");
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
                //            NSArray<NSURL*>* urls = [_dragPasteboard readObjectsForClasses:_classes options:nil]; // slow if there are a lot of elements

                bool anyUrlFound = false;
                for (NSPasteboardItem *item in pasteboardItems) {
                    if ([item availableTypeFromArray:self->_acceptedPasteboardTypes] != nil) {
                        anyUrlFound = true;
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
                [NSAnimationContext.currentContext setDuration:0.25];
                NSAnimationContext.currentContext.completionHandler = ^
                {
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

@end
