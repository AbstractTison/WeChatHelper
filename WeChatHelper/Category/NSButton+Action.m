#import "NSButton+Action.h"

@implementation NSButton (Action)

+ (instancetype)checkboxWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    NSButton *btn = [self buttonWithTitle:title target:target action:action];
    [btn setButtonType:NSButtonTypeSwitch];
    return btn;
}

+ (instancetype)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    NSButton *btn = [[self alloc] init];
    btn.title = title;
    btn.target = target;
    btn.action = action;
    return btn;
}

@end
