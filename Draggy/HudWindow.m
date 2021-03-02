//
//  HudWindow.m
//  Draggy
//
//  Created by El D on 02.03.2021.
//

#import "HudWindow.h"
#import "Draggy-Swift.h" // onMenuButtonPressed selector decraration

static NSString *const DragTargetViewStoryboardName = @"DragTargetView";
static NSWindowFrameAutosaveName const WindowRestorationFrameName = @"DraggyWindow"; // stored in ~/Library/Preferences/io.github.dyumin.Draggy.plist and! somewhere else (e.g. plist deletion won't help)

@implementation HudWindow
{
    NSWindow *_hudWindow;
    __kindof NSViewController *_dragTargetViewController;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hudWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 263, 403) styleMask:(NSWindowStyleMaskResizable | NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskFullSizeContentView) backing:NSBackingStoreBuffered defer:YES /* saves a couple mb on start */];
        _hudWindow.frameAutosaveName = WindowRestorationFrameName;

        _hudWindow.releasedWhenClosed = NO;
        _hudWindow.titlebarAppearsTransparent = YES;
        _hudWindow.titleVisibility = NSWindowTitleHidden;

        _hudWindow.opaque = NO;
        _hudWindow.hasShadow = NO;
        _hudWindow.backgroundColor = NSColor.clearColor;
    }
    return self;
}

- (void)loadContentView
{
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
    [self setUpMenuButtonForWindow:_hudWindow targetController:_dragTargetViewController];

    NSView *contentView = _dragTargetViewController.view;
    [hudBackground addSubview:contentView];

    contentView.wantsLayer = YES;

    contentView.translatesAutoresizingMaskIntoConstraints = NO;

    [contentView.topAnchor constraintEqualToAnchor:hudBackground.topAnchor].active = YES;
    [contentView.bottomAnchor constraintEqualToAnchor:hudBackground.bottomAnchor].active = YES;
    [contentView.leadingAnchor constraintEqualToAnchor:hudBackground.leadingAnchor].active = YES;
    [contentView.trailingAnchor constraintEqualToAnchor:hudBackground.trailingAnchor].active = YES;

}

- (void)setUpMenuButtonForWindow:(NSWindow *)window targetController:(__kindof NSViewController *)controller {
    NSButton *settingsButton = [NSButton buttonWithImage:[NSImage imageNamed:@"NSAdvanced"] target:nil action:nil];
    settingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    settingsButton.bezelStyle = NSBezelStyleShadowlessSquare;
    settingsButton.bordered = NO;
    settingsButton.imagePosition = NSImageOnly;
    settingsButton.imageScaling = NSImageScaleProportionallyUpOrDown;

    NSButton *expandButton = [window standardWindowButton:NSWindowZoomButton];
    [expandButton.superview addSubview:settingsButton];

    [settingsButton.widthAnchor constraintEqualToAnchor:expandButton.widthAnchor].active = YES;
    [settingsButton.heightAnchor constraintEqualToAnchor:expandButton.heightAnchor].active = YES;
    [settingsButton.centerYAnchor constraintEqualToAnchor:expandButton.centerYAnchor].active = YES;

    [settingsButton.trailingAnchor constraintEqualToAnchor:expandButton.superview.trailingAnchor constant: /* TODO: dont hardcode */ -7].active = YES;

    settingsButton.target = controller;
    settingsButton.action = @selector(onMenuButtonPressed);
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
