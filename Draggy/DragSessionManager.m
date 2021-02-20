//
//  DragSessionManager.m
//  Draggy
//
//  Created by El D on 20.02.2021.
//

#import "DragSessionManager.h"
#import <Cocoa/Cocoa.h>

@implementation DragSessionManager
{
    NSArray<NSPasteboardType>* _acceptedPasteboardTypes;
    NSWindow* _hudWindow;
    NSInteger _eventNumber;
    NSInteger _ignoreEventNumber;
    NSPasteboard* _dragPasteboard;
    NSArray<NSPasteboardItem *>* _lastPasteboardItems;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _acceptedPasteboardTypes = @[ NSPasteboardTypeFileURL ]; // todo: optimise
        
        _dragPasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
        
        _hudWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(20, 20, 100, 150) styleMask:(NSWindowStyleMaskBorderless | NSWindowStyleMaskResizable) backing:NSBackingStoreBuffered defer:NO];
        
        _hudWindow.releasedWhenClosed = NO;
    //    _hudWindow.ignoresMouseEvents = YES;
        
        _hudWindow.opaque = NO;
        _hudWindow.hasShadow = NO;
        _hudWindow.backgroundColor = NSColor.clearColor;
    //    _hudWindow.ignoresMouseEvents = YES;
    //    _hudWindow.acceptsMouseMovedEvents = NO;
    //    [_hudWindow unregisterDraggedTypes];
        
    //    [_hudWindow becomeFirstResponder]
        
        _hudWindow.level = NSScreenSaverWindowLevel;
        
    //    _hudWindow.contentView = [[NSView alloc] initWithFrame:NSMakeRect(100, 200, 300, 400)];
    //    _hudWindow.contentView.wantsLayer = YES;
    //    _hudWindow.contentView.layer.backgroundColor = NSColor.greenColor.CGColor;
    //
    //    [_hudWindow.contentView setNeedsDisplay:YES];
        
        NSView* contentView = [[NSView alloc] initWithFrame:NSMakeRect(100, 200, 300, 400)];
        contentView.wantsLayer = YES;
    //    contentView.layer.backgroundColor = NSColor.redColor.CGColor;
        
    //    [contentView unregisterDraggedTypes];
        
        NSVisualEffectView* hudBackground = [NSVisualEffectView new];
        if (@available(macOS 10.14, *)) {
            hudBackground.material = NSVisualEffectMaterialHUDWindow;
        } else {
            hudBackground.material = NSVisualEffectMaterialSidebar;
        }
        hudBackground.state = NSVisualEffectStateActive;
        
        hudBackground.wantsLayer = YES;
        
        hudBackground.layer.cornerRadius = 20.0;
        hudBackground.layer.masksToBounds = YES;
        
    //    [hudBackground unregisterDraggedTypes];
        
        _hudWindow.contentView = hudBackground;
        
        [hudBackground addSubview:contentView];
        
        [contentView.topAnchor constraintEqualToAnchor:hudBackground.topAnchor].active=YES;
        [contentView.bottomAnchor constraintEqualToAnchor:hudBackground.bottomAnchor].active=YES;
        [contentView.leadingAnchor constraintEqualToAnchor:hudBackground.leadingAnchor].active=YES;
        [contentView.trailingAnchor constraintEqualToAnchor:hudBackground.trailingAnchor].active=YES;
        
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        
    //    hudBackground.translatesAutoresizingMaskIntoConstraints = NO;
        
    //    self.contentViewController.view.frame = hudBackground.frame;
        
    //    co
        
    //    _hudWindow.contentViewController.view.frame = _hudWindow.frame;
        
        [_hudWindow orderFront:nil];
        
    //    [_dragPasteboard addObserver:self forKeyPath:@"pasteboardItems.count" options:NSKeyValueObservingOptionNew context:nil];
        
        [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDragged|NSEventMaskLeftMouseUp handler:^(NSEvent * _Nonnull event)
        {
            const NSInteger eventNumber = event.eventNumber;
            if (eventNumber == self->_ignoreEventNumber)
            {
                // first drag event does not yep adds elements to pasteboard
                if ([self->_lastPasteboardItems isEqualToArray:self->_dragPasteboard.pasteboardItems]) // todo: refactor
                {
                    NSLog(@"return var 3");
                    return;
                }

                self->_ignoreEventNumber = 0;
            }
            
            if (event.type == NSEventTypeLeftMouseUp)
            {
                if (self->_eventNumber)
                {
                    self->_eventNumber = 0;
    //                contentView.layer.opacity = 0.0;
    //                _hudWindow.alphaValue = 0;
    //                [_hudWindow close];
                    
                    self->_lastPasteboardItems = self->_dragPasteboard.pasteboardItems;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [NSAnimationContext beginGrouping];
                        [NSAnimationContext.currentContext setCompletionHandler:^{
                              // This block will be invoked when all of the animations
                              //  started below have completed or been cancelled.
                               NSLog(@"All done! _hudWindow close");
                            [self->_hudWindow close];
    //                           [_dragPasteboard clearContents]; // may break dropping
                           }];
                        [NSAnimationContext.currentContext setDuration:0.3];
        //                NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
        //                contentView.animator.layer.opacity = 1.0;
                        self->_hudWindow.animator.alphaValue = 0;
                        [NSAnimationContext endGrouping];
                    });
                }
                
                return;
            }
            
            if (!self->_eventNumber)
            {
                NSArray<NSPasteboardItem *> *pasteboardItems = self->_dragPasteboard.pasteboardItems;
                
                if (!pasteboardItems.count)
                {
                    NSLog(@"return var 1");
                    self->_ignoreEventNumber = eventNumber;
                    return;
                }
                
                if ([self->_lastPasteboardItems isEqualToArray:pasteboardItems])
                {
                    NSLog(@"return var 4");
                    self->_ignoreEventNumber = eventNumber;
                    return;
                }

                // https://stackoverflow.com/questions/56199062/get-uti-of-nspasteboardtypefileurl
    //            NSArray<NSURL*>* urls = [_dragPasteboard readObjectsForClasses:_classes options:nil];
                
                bool anyUrlFound = false;
                for (NSPasteboardItem* item in pasteboardItems)
                {
                    if ([item availableTypeFromArray:self->_acceptedPasteboardTypes] != nil)
                    {
                        anyUrlFound = true;
                        break;
                    }
                }
    //            const bool anyUrlFound = [_dragPasteboard availableTypeFromArray:self->_classes] != nil; // actually good but may change in future?
                if (!anyUrlFound)
                {
                    NSLog(@"return var 2");
                    self->_ignoreEventNumber = eventNumber;
                    return;
                }
            }
        
            if (self->_eventNumber != eventNumber)
            {
                self->_eventNumber = eventNumber;
                [self->_hudWindow orderFrontRegardless];
                
    //            if (!contentView.layer.opacity)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSAnimationContext beginGrouping];
                    [NSAnimationContext.currentContext setCompletionHandler:^{
                          // This block will be invoked when all of the animations
                          //  started below have completed or been cancelled.
                           NSLog(@"All done!");
                       }];
                    [NSAnimationContext.currentContext setDuration:0.25];
    //                NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
    //                contentView.animator.layer.opacity = 1.0;
                    self->_hudWindow.animator.alphaValue = 1;
                    [NSAnimationContext endGrouping];
                });
                
    //            [_hudWindow setFrame:NSMakeRect(NSEvent.mouseLocation.x, NSEvent.mouseLocation.y, _hudWindow.frame.size.width, _hudWindow.frame.size.height) display:YES animate:NO];
                
    //        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
    //                <#code#>
    //            } completionHandler:<#^(void)completionHandler#>]
            }
            
            [self->_hudWindow setFrame:NSMakeRect(NSEvent.mouseLocation.x, NSEvent.mouseLocation.y, self->_hudWindow.frame.size.width, self->_hudWindow.frame.size.height) display:YES animate:NO];
        }];
        
    //    [ViewController takeSystemPreferencesWindowScreenshot:&CGRectNull];
    }
    return self;
}

@end
