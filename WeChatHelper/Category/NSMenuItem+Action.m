#import "NSMenuItem+Action.h"

@implementation NSMenuItem (Action)

+ (NSMenuItem *)menuItemWithTitle:(NSString *)title action:(SEL)selector target:(id)target keyEquivalent:(NSString *)key state:(NSControlStateValue)state {
    NSMenuItem *item = [[self alloc] initWithTitle:title action:selector keyEquivalent:key];
    item.target = target;
    item.state = state;
    return item;
}

@end
