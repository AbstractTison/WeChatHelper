#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface TweakWrapper : NSObject

void tweakInstanceMethod(Class origClass, SEL origSelector, Class tweakClass, SEL tweakSelector);
void tweakClassMethod(Class origClass, SEL origSelector, Class tweakClass, SEL tweakSelector);

@end
