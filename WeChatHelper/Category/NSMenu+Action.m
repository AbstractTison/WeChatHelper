#import "NSMenu+Action.h"

@implementation NSMenu (Action)

- (void)addItems:(NSArray *)subItems {
    for (NSMenuItem *item in subItems) {
        [self addItem:item];
    }
}

@end
