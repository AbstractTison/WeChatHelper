#import <Foundation/Foundation.h>

@interface Configuration : NSObject

@property (nonatomic, assign) BOOL preventRevokeEnable;
@property (nonatomic, assign) BOOL autoReplyEnable;
@property (nonatomic, assign) BOOL autoAuthEnable;
@property (nonatomic, assign) BOOL stickyEnable;
@property (nonatomic, assign) BOOL multipleSelectionEnable;

@property (nonatomic, copy) NSMutableArray *autoReplyModels;
@property (nonatomic, copy) NSMutableArray *selectSessions;
@property (nonatomic, copy) NSMutableArray *ignoreSessionModels;
@property (nonatomic, copy) NSMutableSet *revokeMsgSet;
@property (nonatomic, copy) NSString *currentUserName;

+ (instancetype)getInstance;
- (void)saveAutoReplyModels;

@end

