#import <Foundation/Foundation.h>

@interface NSString (Action)

- (NSRect)rectWithFont:(NSFont *)font;
- (CGFloat)widthWithFont:(NSFont *)font;
- (NSString *)substringFromString:(NSString *)fromStr;

@end
