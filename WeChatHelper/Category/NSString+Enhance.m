#import "NSString+Enhance.h"

@implementation NSString (Enhance)

- (NSString *)subStringFrom:(NSString *)from to:(NSString *)to {
    NSRange a = [self rangeOfString:from];
    NSRange b = [self rangeOfString:to];
    return [self substringWithRange:NSMakeRange(a.location+a.length, b.location-a.location-a.length)];
}

@end
