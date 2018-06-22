#ifndef Macro_h
#define Macro_h

#define RGBA(r, g, b, a) [NSColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:(a)]
#define HelperLocalizedString(key)  [[NSBundle bundleWithIdentifier:@"wch.WeChatHelper"] localizedStringForKey:(key) value:@"" table:nil]
#define WeChatLocalizedString(key)  [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]

static NSString * const NOTIFY_AUTO_REPLY_CHANGE = @"NOTIFY_AUTO_REPLY_CHANGE";
static NSString * const NOTIFY_PREVENT_REVOKE_CHANGE  = @"NOTIFY_PREVENT_REVOKE_CHANGE";
static NSString * const NOTIFY_AUTO_AUTH_CHANGE = @"NOTIFY_AUTO_AUTH_CHANGE";

#endif
