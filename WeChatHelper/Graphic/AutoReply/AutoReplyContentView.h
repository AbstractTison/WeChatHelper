#import <Cocoa/Cocoa.h>
#import "AutoReplyModel.h"

@interface AutoReplyContentView : NSView

@property (nonatomic, strong) AutoReplyModel *model;
@property (nonatomic, copy) void (^endEdit)(void);

@end
