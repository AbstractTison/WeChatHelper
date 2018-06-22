#import <Cocoa/Cocoa.h>
#import "AutoReplyModel.h"

@interface AutoReplyCell : NSControl

@property (nonatomic, strong) AutoReplyModel *model;
@property (nonatomic, copy) void (^updateModel)(void);

@end
