#import "NSWindowController+Action.h"

@implementation NSWindowController (Action)

- (void)show {
    [self showWindow:self];
    [self.window center];
    [self.window makeKeyWindow];
}

@end
