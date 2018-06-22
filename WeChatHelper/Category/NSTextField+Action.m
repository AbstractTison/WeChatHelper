#import "NSTextField+Action.h"

@implementation NSTextField (Action)

+ (instancetype)labelWithString:(NSString *)stringValue {
    NSTextField *textField = [[self alloc] initWithFrame:NSMakeRect(10, 10, 200, 17)];
    [textField setStringValue:stringValue];
    [textField setBezeled:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    return textField;
}

@end
