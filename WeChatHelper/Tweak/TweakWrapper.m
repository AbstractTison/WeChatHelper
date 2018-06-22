#import "TweakWrapper.h"

@implementation TweakWrapper

void tweakInstanceMethod(Class origClass, SEL origSelector, Class tweakClass, SEL tweakSelector) {
    Method origMethod = class_getInstanceMethod(origClass, origSelector);
    Method tweakMethod = class_getInstanceMethod(tweakClass, tweakSelector);
    if (origMethod && tweakMethod)
        method_exchangeImplementations(origMethod, tweakMethod);
}

void tweakClassMethod(Class origClass, SEL origSelector, Class tweakClass, SEL tweakSelector) {
    Method origMethod = class_getClassMethod(origClass, origSelector);
    Method tweakMethod = class_getClassMethod(tweakClass, tweakSelector);
    if (origMethod && tweakMethod)
        method_exchangeImplementations(origMethod, tweakMethod);
}

@end
