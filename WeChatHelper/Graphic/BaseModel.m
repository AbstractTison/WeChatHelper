#import "BaseModel.h"

@implementation BaseModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    NSAssert(NO, @"BaseModel::initWithDict : must be override by subclass");
    return nil;
}

- (NSDictionary *)dictionary {
    NSAssert(NO, @"BaseModel::dictionary : must be override by subclass");
    return nil;
}
@end
