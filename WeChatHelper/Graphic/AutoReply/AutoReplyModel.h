#import "BaseModel.h"

@interface AutoReplyModel : BaseModel

@property (nonatomic, assign) BOOL enable;
@property (nonatomic, copy) NSString *keyword;
@property (nonatomic, copy) NSString *replyContent;
@property (nonatomic, assign) BOOL enableGroupReply;
@property (nonatomic, assign) BOOL enableSingleReply;
@property (nonatomic, assign) BOOL enableRegex;
@property (nonatomic, assign) BOOL enableDelay;
@property (nonatomic, assign) NSInteger delayTime;
@property (nonatomic, assign) BOOL enableSpecificReply;
@property (nonatomic, strong) NSArray *specificContacts;

- (BOOL)hasEmptyKeywordOrReplyContent;

@end
