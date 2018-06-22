#import "HelperMessageService.h"
#import "WeChatHelper.h"

@implementation HelperMessageService

+ (instancetype)getInstance {
    static id messageService = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ messageService = [[self alloc] init]; });
    return messageService;
}

- (void)sendTextMessage:(id)msgContent toUsrName:(id)toUser delay:(NSInteger)delayTime {
    MessageService *service = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    if (delayTime == 0) {
        [service SendTextMessage:currentUserName toUsrName:toUser msgText:msgContent atUserList:nil];
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [service SendTextMessage:currentUserName toUsrName:toUser msgText:msgContent atUserList:nil];
        });
    });
}

@end
