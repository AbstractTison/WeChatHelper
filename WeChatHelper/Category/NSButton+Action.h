#import <Cocoa/Cocoa.h>

@interface NSButton (Action)

+ (instancetype)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)checkboxWithTitle:(NSString *)title target:(id)target action:(SEL)action;

@end
