#import "NSString+Action.h"
#import "WeChatHelper.h"

@implementation NSString (Action)

- (NSRect)rectWithFont:(NSFont *)font {
    return [self boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: font}];
}

- (CGFloat)widthWithFont:(NSFont *)font {
    return [self rectWithFont:font].size.width;
}

- (NSString *)substringFromString:(NSString *)fromStr {
    NSRange range = [self rangeOfString:fromStr];
    if (range.length > 0) {
        return [self substringFromIndex:range.location + range.length];
    }
    return nil;
}
@end
