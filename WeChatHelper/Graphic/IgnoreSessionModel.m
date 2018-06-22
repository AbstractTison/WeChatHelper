#import "IgnoreSessionModel.h"

@implementation IgnoreSessionModel

- (instancetype)initWithDict:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        self.selfContact = dict[@"selfContact"];
        self.userName = dict[@"userName"];
        self.ignore = [dict[@"ignore"] boolValue];
    }
    return self;
}

- (NSDictionary *)dictionary {
    return @{@"selfContact": self.selfContact,
             @"userName": self.userName,
             @"ignore": @(self.ignore)};
}

@end
