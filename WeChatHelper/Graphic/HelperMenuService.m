#import "HelperMenuService.h"
#import "AutoReplyWindowController.h"
#import "NSMenuItem+Action.h"
#import "Macro.h"
#import "WeChatHelper.h"
#import "NSMenu+Action.h"
#import "NSWindowController+Action.h"

static char kAutoReplyWindowController;

@implementation HelperMenuService

+ (instancetype)getInstance {
    static id menuService = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ menuService = [[self alloc] init]; });
    return menuService;
}

- (void)initAssistantMenuItems {
    NSMenuItem *preventRevokeItem = [NSMenuItem menuItemWithTitle:HelperLocalizedString(@"assistant.menu.revoke") action:@selector(onPreventRevoke:) target:self keyEquivalent:@"t" state:[[Configuration getInstance] preventRevokeEnable]];
    NSMenuItem *autoReplyItem = [NSMenuItem menuItemWithTitle:HelperLocalizedString(@"assistant.menu.autoReply") action:@selector(onAutoReply:) target:self keyEquivalent:@"k" state:[[Configuration getInstance] autoReplyEnable]];
    NSMenuItem *stickyItem = [NSMenuItem menuItemWithTitle:HelperLocalizedString(@"assistant.menu.windowSticky") action:@selector(onWeChatStickyControl:) target:self keyEquivalent:@"D" state:[[Configuration getInstance] stickyEnable]];
    NSMenuItem *autoAuthItem = [NSMenuItem menuItemWithTitle:HelperLocalizedString(@"assistant.menu.freeLogin") action:@selector(onAutoAuthControl:) target:self keyEquivalent:@"M" state:[[Configuration getInstance] autoAuthEnable]];
    
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:HelperLocalizedString(@"assistant.menu.title")];
    [subMenu addItems:@[preventRevokeItem, autoReplyItem, stickyItem, autoAuthItem]];
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    [menuItem setTitle:HelperLocalizedString(@"assistant.menu.title")];
    [menuItem setSubmenu:subMenu];
    menuItem.target = self;
    [[[NSApplication sharedApplication] mainMenu] addItem:menuItem];
    menuItem.enabled = NO;
    
    [self addObserverWeChatConfig];
}

#pragma mark - Listen to WeChatHelperConfig

- (void)addObserverWeChatConfig {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WeChatHelperConfigAutoReplyChange) name:NOTIFY_AUTO_REPLY_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WeChatHelperConfigPreventRevokeChange) name:NOTIFY_PREVENT_REVOKE_CHANGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WeChatHelperConfigAutoAuthChange) name:NOTIFY_AUTO_AUTH_CHANGE object:nil];
}

- (void)WeChatHelperConfigAutoReplyChange {
    Configuration *shareConfig = [Configuration getInstance];
    shareConfig.autoReplyEnable = !shareConfig.autoReplyEnable;
    [self changePluginMenuItemWithIndex:1 state:shareConfig.autoReplyEnable];
}

- (void)WeChatHelperConfigPreventRevokeChange {
    Configuration *shareConfig = [Configuration getInstance];
    shareConfig.preventRevokeEnable = !shareConfig.preventRevokeEnable;
    [self changePluginMenuItemWithIndex:0 state:shareConfig.preventRevokeEnable];
}

- (void)WeChatHelperConfigAutoAuthChange {
    Configuration *shareConfig = [Configuration getInstance];
    shareConfig.autoAuthEnable = !shareConfig.autoAuthEnable;
    [self changePluginMenuItemWithIndex:5 state:shareConfig.autoAuthEnable];
}

- (void)changePluginMenuItemWithIndex:(NSInteger)index state:(NSControlStateValue)state {
    NSMenuItem *pluginMenuItem = [[[[NSApplication sharedApplication] mainMenu] itemArray] lastObject];
    NSMenuItem *item = pluginMenuItem.submenu.itemArray[index];
    item.state = state;
}

#pragma mark - Listen menu item click
- (void)onPreventRevoke:(NSMenuItem *)item {
    item.state = !item.state;
    [[Configuration getInstance] setPreventRevokeEnable:item.state];
}

- (void)onAutoReply:(NSMenuItem *)item {
    WeChat *WeChatInstance = [objc_getClass("WeChat") sharedInstance];
    AutoReplyWindowController *autoReplyWC = objc_getAssociatedObject(WeChatInstance, &kAutoReplyWindowController);

    if (!autoReplyWC) {
        autoReplyWC = [[AutoReplyWindowController alloc] initWithWindowNibName:@"AutoReplyWindowController"];
        objc_setAssociatedObject(WeChatInstance, &kAutoReplyWindowController, autoReplyWC, OBJC_ASSOCIATION_RETAIN);
    }
    [autoReplyWC show];
}

- (void)onAutoAuthControl:(NSMenuItem *)item {
    item.state = !item.state;
    [[Configuration getInstance] setAutoAuthEnable:item.state];
}

- (void)onWeChatStickyControl:(NSMenuItem *)item {
    item.state = !item.state;
    [[Configuration getInstance] setStickyEnable:item.state];
    
    NSArray *windows = [[NSApplication sharedApplication] windows];
    [windows enumerateObjectsUsingBlock:^(NSWindow *window, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![window.className isEqualToString:@"NSStatusBarWindow"]) {
            window.level = item.state == NSControlStateValueOn ? NSNormalWindowLevel+2 : NSNormalWindowLevel;
        }
    }];
}

@end
