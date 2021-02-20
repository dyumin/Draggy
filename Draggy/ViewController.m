//
//  ViewController.m
//  Draggy
//
//  Created by El D on 18.02.2021.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic) NSWindow* hudWindow;
@property (nonatomic) NSInteger eventNumber;
@property (nonatomic) NSInteger ignoreEventNumber;
@property (nonatomic) NSPasteboard* dragPasteboard;

@property NSArray<NSPasteboardItem *>* lastPasteboardItems;

@end

@implementation ViewController
{
    NSArray* _classes;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _classes = @[ NSPasteboardTypeFileURL ]; // todo: optimise
    
    self.dragPasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
    
    self.hudWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(20, 20, 100, 150) styleMask:(NSWindowStyleMaskBorderless | NSWindowStyleMaskResizable) backing:NSBackingStoreBuffered defer:NO];
    
    self.hudWindow.releasedWhenClosed = NO;
//    self.hudWindow.ignoresMouseEvents = YES;
    
    self.hudWindow.opaque = NO;
    self.hudWindow.hasShadow = NO;
    self.hudWindow.backgroundColor = NSColor.clearColor;
//    self.hudWindow.ignoresMouseEvents = YES;
//    self.hudWindow.acceptsMouseMovedEvents = NO;
//    [self.hudWindow unregisterDraggedTypes];
    
//    [self.hudWindow becomeFirstResponder]
    
    self.hudWindow.level = NSScreenSaverWindowLevel;
    
//    self.hudWindow.contentView = [[NSView alloc] initWithFrame:NSMakeRect(100, 200, 300, 400)];
//    self.hudWindow.contentView.wantsLayer = YES;
//    self.hudWindow.contentView.layer.backgroundColor = NSColor.greenColor.CGColor;
//
//    [self.hudWindow.contentView setNeedsDisplay:YES];
    
    NSView* contentView = [[NSView alloc] initWithFrame:NSMakeRect(100, 200, 300, 400)];
    contentView.wantsLayer = YES;
    contentView.layer.backgroundColor = NSColor.redColor.CGColor;
    
//    [contentView unregisterDraggedTypes];
    
    NSVisualEffectView* hudBackground = [NSVisualEffectView new];
    hudBackground.material = NSVisualEffectMaterialHUDWindow;
    hudBackground.state = NSVisualEffectStateActive;
    
    hudBackground.wantsLayer = YES;
    
    hudBackground.layer.cornerRadius = 20.0;
    hudBackground.layer.masksToBounds = YES;
    
//    [hudBackground unregisterDraggedTypes];
    
    self.hudWindow.contentView = hudBackground;
    
    [hudBackground addSubview:contentView];
    
    [contentView.topAnchor constraintEqualToAnchor:hudBackground.topAnchor].active=YES;
    [contentView.bottomAnchor constraintEqualToAnchor:hudBackground.bottomAnchor].active=YES;
    [contentView.leadingAnchor constraintEqualToAnchor:hudBackground.leadingAnchor].active=YES;
    [contentView.trailingAnchor constraintEqualToAnchor:hudBackground.trailingAnchor].active=YES;
    
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
//    hudBackground.translatesAutoresizingMaskIntoConstraints = NO;
    
//    self.contentViewController.view.frame = hudBackground.frame;
    
//    co
    
//    self.hudWindow.contentViewController.view.frame = self.hudWindow.frame;
    
    [self.hudWindow orderFront:nil];
    
//    [self.dragPasteboard addObserver:self forKeyPath:@"pasteboardItems.count" options:NSKeyValueObservingOptionNew context:nil];
    
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDragged|NSEventMaskLeftMouseUp handler:^(NSEvent * _Nonnull event)
    {
        const NSInteger eventNumber = event.eventNumber;
        if (eventNumber == self.ignoreEventNumber)
        {
            // first drag event does not yep adds elements to pasteboard
            if ([self.lastPasteboardItems isEqualToArray:self.dragPasteboard.pasteboardItems]) // todo: refactor
            {
                NSLog(@"return var 3");
                return;
            }

            self.ignoreEventNumber = 0;
        }
        
        if (event.type == NSEventTypeLeftMouseUp)
        {
            if (self.eventNumber)
            {
                self.eventNumber = 0;
//                contentView.layer.opacity = 0.0;
//                self.hudWindow.alphaValue = 0;
//                [self.hudWindow close];
                
                self.lastPasteboardItems = self.dragPasteboard.pasteboardItems;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSAnimationContext beginGrouping];
                    [NSAnimationContext.currentContext setCompletionHandler:^{
                          // This block will be invoked when all of the animations
                          //  started below have completed or been cancelled.
                           NSLog(@"All done! self.hudWindow close");
                           [self.hudWindow close];
//                           [self.dragPasteboard clearContents]; // may break dropping
                       }];
                    [NSAnimationContext.currentContext setDuration:0.3];
    //                NSAnimationContext.currentContext.allowsImplicitAnimation = YES;
    //                contentView.animator.layer.opacity = 1.0;
                    self.hudWindow.animator.alphaValue = 0;
                    [NSAnimationContext endGrouping];
                });
            }
            
            return;
        }
        
        if (!self.eventNumber)
        {
            NSArray<NSPasteboardItem *> *pasteboardItems = self.dragPasteboard.pasteboardItems;
            
            if (!pasteboardItems.count)
            {
                NSLog(@"return var 1");
                self.ignoreEventNumber = eventNumber;
                return;
            }
            
            if ([self.lastPasteboardItems isEqualToArray:pasteboardItems])
            {
                NSLog(@"return var 4");
                self.ignoreEventNumber = eventNumber;
                return;
            }

            // https://stackoverflow.com/questions/56199062/get-uti-of-nspasteboardtypefileurl
//            NSArray<NSURL*>* urls = [self.dragPasteboard readObjectsForClasses:_classes options:nil];
            
            bool anyUrlFound = false;
            for (NSPasteboardItem* item in pasteboardItems)
            {
                if ([item availableTypeFromArray:self->_classes] != nil)
                {
                    anyUrlFound = true;
                    break;
                }
            }
//            const bool anyUrlFound = [self.dragPasteboard availableTypeFromArray:self->_classes] != nil; // actually good but may change in future?
            if (!anyUrlFound)
            {
                NSLog(@"return var 2");
                self.ignoreEventNumber = eventNumber;
                return;
            }
        }
    
        if (self.eventNumber != eventNumber)
        {
            self.eventNumber = eventNumber;
            [self.hudWindow orderFrontRegardless];
            
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
                self.hudWindow.animator.alphaValue = 1;
                [NSAnimationContext endGrouping];
            });
            
//            [self.hudWindow setFrame:NSMakeRect(NSEvent.mouseLocation.x, NSEvent.mouseLocation.y, self.hudWindow.frame.size.width, self.hudWindow.frame.size.height) display:YES animate:NO];
            
//        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
//                <#code#>
//            } completionHandler:<#^(void)completionHandler#>]
        }
        
        [self.hudWindow setFrame:NSMakeRect(NSEvent.mouseLocation.x, NSEvent.mouseLocation.y, self.hudWindow.frame.size.width, self.hudWindow.frame.size.height) display:YES animate:NO];
    }];
    
//    [ViewController takeSystemPreferencesWindowScreenshot:&CGRectNull];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.dragPasteboard) {
        self.ignoreEventNumber = 0;
        return;
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
