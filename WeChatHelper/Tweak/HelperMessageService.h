#import <Foundation/Foundation.h>

@interface HelperMessageService : NSObject

+ (instancetype)getInstance;
- (void)sendTextMessage:(id)msgContent toUsrName:(id)toUser delay:(NSInteger)delayTime;

@end
