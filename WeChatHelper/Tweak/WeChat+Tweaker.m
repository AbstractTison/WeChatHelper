#import "WeChat+Tweaker.h"
#import "NSButton+Action.h"
#import "NSString+Enhance.h"
#import "fishhook.h"
#import "Macro.h"
#import "WeChatHelper.h"
#import "AutoReplyModel.h"
#import "HelperMenuService.h"
#import "IgnoreSessionModel.h"
#import "HelperMessageService.h"

@implementation NSObject (WeChatTweaker)

+ (void)tweakWeChat {
    // Prevent revoke message
    tweakInstanceMethod(objc_getClass("MessageService"), @selector(onRevokeMsg:), [self class], @selector(tweakOnRevokeMsg:));

    // Synchronize chat history
    tweakInstanceMethod(objc_getClass("MessageService"), @selector(OnSyncBatchAddMsgs:isFirstSync:), [self class], @selector(tweakOnSyncBatchAddMsgs:isFirstSync:));
    
    // Auto login
    tweakInstanceMethod(objc_getClass("LogoutCGI"), @selector(sendLogoutCGIWithCompletion:), [self class], @selector(tweakSendLogoutCGIWithCompletion:));
    tweakInstanceMethod(objc_getClass("AccountService"), @selector(ManualLogout), [self class], @selector(tweakManualLogout));
    
    // Ignore sessions
    tweakInstanceMethod(objc_getClass("MMSessionMgr"), @selector(sortSessions), [self class], @selector(tweakSortSessions));

    // Sticky
    tweakInstanceMethod(objc_getClass("NSWindow"), @selector(makeKeyAndOrderFront:), [self class], @selector(tweakMakeKeyAndOrderFront:));
    
    // WeChat initialize
    tweakInstanceMethod(objc_getClass("WeChat"), @selector(onAuthOK:), [self class], @selector(tweakOnAuthOK:));
    tweakInstanceMethod(objc_getClass("MMURLHandler"), @selector(startGetA8KeyWithURL:), [self class], @selector(tweakStartGetA8KeyWithURL:));
    tweakInstanceMethod(objc_getClass("WeChat"), @selector(applicationDidFinishLaunching:), [self class], @selector(tweakApplicationDidFinishLaunching:));

    // Force to save chat history
    tweakInstanceMethod(objc_getClass("UserDefaultsService"), @selector(stringForKey:), [self class], @selector(tweakStringForKey:));
    
    // Replace sandbox path
    rebind_symbols((struct rebinding[2]) {
        { "NSSearchPathForDirectoriesInDomains", tweakNSSearchPathForDirectoriesInDomains, (void *)&origNSSearchPathForDirectoriesInDomains },
        { "NSHomeDirectory", tweakNSHomeDirectory, (void *)&origNSHomeDirectory }
    }, 2);

    [self setup];
}

#pragma mark - WeChat initialize

+ (void)setup {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupWindowSticky];
    });
}

+ (void)setupWindowSticky {
    BOOL onTop = [[Configuration getInstance] stickyEnable];
    WeChat *WeChatInstance = [objc_getClass("WeChat") sharedInstance];
    WeChatInstance.mainWindowController.window.level = onTop == NSControlStateValueOn ? NSNormalWindowLevel+2 : NSNormalWindowLevel;
}

- (void)tweakOnAuthOK:(BOOL)arg1 {
    [self tweakOnAuthOK:arg1];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
        NSMenuItem *pluginMenu = mainMenu.itemArray.lastObject;
        pluginMenu.enabled = YES;
    });
}

- (void)tweakStartGetA8KeyWithURL:(id)arg1 {
    MMURLHandler *urlHandler = (MMURLHandler *)self;
    [urlHandler openURLWithDefault:arg1];
}

- (void)tweakApplicationDidFinishLaunching:(id)arg1 {
    [[HelperMenuService getInstance] initAssistantMenuItems];
    [self tweakApplicationDidFinishLaunching:arg1];
}

#pragma mark - Prevent revoke message

- (void)tweakOnRevokeMsg:(id)msg {
    if (![[Configuration getInstance] preventRevokeEnable]) {
        [self tweakOnRevokeMsg:msg];
        return;
    }

    // Decode message
    NSString *session = [msg subStringFrom:@"<session>" to:@"</session>"];
    NSString *newmsgid = [msg subStringFrom:@"<newmsgid>" to:@"</newmsgid>"];
    
    NSMutableSet *revokeMsgSet = [[Configuration getInstance] revokeMsgSet];
    
    if ([revokeMsgSet containsObject:newmsgid] || !newmsgid) {
        // Return if this message has been already dealed with
        return;
    }

    [revokeMsgSet addObject:newmsgid];
    
    // Get content of the message that has been revoked
    MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    MessageData *revokeMsgData = [msgService GetMsgData:session svrId:[newmsgid integerValue]];
    if ([revokeMsgData isSendFromSelf]) {
        // Never prevent revoking from self.
        [self tweakOnRevokeMsg:msg];
        return;
    }

    NSString *msgContent = [revokeMsgData getRealMessageContent];
    NSString *msgType;
    if (revokeMsgData.messageType == 1) { // is text
        msgType = @"";
    } else if ([revokeMsgData isCustomEmojiMsg]) {
        msgType = HelperLocalizedString(@"assistant.revokeType.emoji");
    } else if ([revokeMsgData isImgMsg]) {
        msgType = HelperLocalizedString(@"assistant.revokeType.image");
    } else if ([revokeMsgData isVideoMsg]) {
        msgType = HelperLocalizedString(@"assistant.revokeType.video");
    } else if ([revokeMsgData isVoiceMsg]) {
        msgType = HelperLocalizedString(@"assistant.revokeType.voice");
    } else {
        msgType = HelperLocalizedString(@"assistant.revokeType.other");
    }
    
    NSString *newMsgContent = [NSString stringWithFormat:@"%@\n%@",HelperLocalizedString(@"assistant.revoke.otherMessage.tip"), msgType];
    NSString *displayName = [revokeMsgData groupChatSenderDisplayName];
    if (revokeMsgData.messageType == 1) {
        if ([revokeMsgData isChatRoomMessage]) {
            newMsgContent = [NSString stringWithFormat:@"%@\n%@ %@ %@", HelperLocalizedString(@"assistant.revoke.otherMessage.tip"), displayName, HelperLocalizedString(@"assistant.revoke.chatroom.tip"), msgContent];
        } else {
            newMsgContent = [NSString stringWithFormat:@"%@\n%@",HelperLocalizedString(@"assistant.revoke.otherMessage.tip"), msgContent];
        }
    } else {
        if ([revokeMsgData isChatRoomMessage]) {
            newMsgContent = [NSString stringWithFormat:@"%@\n%@ %@ %@",HelperLocalizedString(@"assistant.revoke.otherMessage.tip"), displayName, HelperLocalizedString(@"assistant.revoke.chatroom.tip"), msgType];
        }
    }

    // Write back prevent info message as local message data
    MessageData *newMsgData = ({
        MessageData *msg = [[objc_getClass("MessageData") alloc] initWithMsgType:0x2710];
        [msg setFromUsrName:revokeMsgData.toUsrName];
        [msg setToUsrName:revokeMsgData.fromUsrName];
        [msg setMsgStatus:4];
        [msg setMsgContent:newMsgContent];
        [msg setMsgCreateTime:[revokeMsgData msgCreateTime]];
        msg;
    });
    [msgService AddLocalMsg:session msgData:newMsgData];
}

#pragma mark - Synchronize chat history
- (void)tweakOnSyncBatchAddMsgs:(NSArray *)msgs isFirstSync:(BOOL)arg2 {
    [self tweakOnSyncBatchAddMsgs:msgs isFirstSync:arg2];
    
    [msgs enumerateObjectsUsingBlock:^(AddMsg *addMsg, NSUInteger idx, BOOL * _Nonnull stop) {
        NSDate *now = [NSDate date];
        NSTimeInterval nowSecond = now.timeIntervalSince1970;
        if (nowSecond - addMsg.createTime > 180) {
            // Ignore message before 3 miniutes ago
            return;
        }
        
        [self autoReplyWithMsg:addMsg];
    }];
}

#pragma mark - Auto login
- (void)tweakSendLogoutCGIWithCompletion:(id)arg1 {
    BOOL autoAuthEnable = [[Configuration getInstance] autoAuthEnable];
    WeChat *WeChatInstance = [objc_getClass("WeChat") sharedInstance];
    if (autoAuthEnable && WeChatInstance.isAppTerminating) return;
    
    return [self tweakSendLogoutCGIWithCompletion:arg1];
}

- (void)tweakManualLogout {
    BOOL autoAuthEnable = [[Configuration getInstance] autoAuthEnable];
    if (autoAuthEnable) return;
    
    [self tweakManualLogout];
}

#pragma mark - Ignore sessions

- (void)tweakSortSessions {
    [self tweakSortSessions];
    
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    NSMutableArray *arrSession = sessionMgr.m_arrSession;
    NSMutableArray *ignoreSessions = [[[Configuration getInstance] ignoreSessionModels] mutableCopy];
    
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    [ignoreSessions enumerateObjectsUsingBlock:^(IgnoreSessionModel *model, NSUInteger index, BOOL * _Nonnull stop) {
        __block NSInteger ignoreIdx = -1;
        [arrSession enumerateObjectsUsingBlock:^(MMSessionInfo *sessionInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
                ignoreIdx = idx;
                *stop = YES;
            }
        }];
        
        if (ignoreIdx != -1) {
            MMSessionInfo *sessionInfo = arrSession[ignoreIdx];
            [arrSession removeObjectAtIndex:ignoreIdx];
            [arrSession addObject:sessionInfo];
        }
    }];
    
    WeChat *WeChatInstance = [objc_getClass("WeChat") sharedInstance];
    [WeChatInstance.chatsViewController.tableView reloadData];
}

#pragma mark - Force to save chat history
- (id)tweakStringForKey:(NSString *)key {
    if ([key isEqualToString:@"kMMUserDefaultsKey_SaveChatHistory"]) {
        return @"1";
    }
    return [self tweakStringForKey:key];
}

#pragma mark - Sticky
- (void)tweakMakeKeyAndOrderFront:(nullable id)sender {
    BOOL stickyEnable = [[Configuration getInstance] stickyEnable];
    ((NSWindow *)self).level = stickyEnable == NSControlStateValueOn ? NSNormalWindowLevel+2 : NSNormalWindowLevel;
    
    [self tweakMakeKeyAndOrderFront:sender];
}

#pragma mark - Auto reply
- (void)autoReplyWithMsg:(AddMsg *)addMsg {
    if (![[Configuration getInstance] autoReplyEnable]) {
        return;
    }
    
    if (addMsg.msgType != 1 && addMsg.msgType != 3) {
        return;
    }
    
    NSString *userName = addMsg.fromUserName.string;
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    WCContactData *msgContact = [sessionMgr getContact:userName];
    
    if ([msgContact isBrandContact] || [msgContact isSelf]) {
        // Do not support auto reply if message is from self or a brand contact
        return;
    }
    
    NSArray *autoReplyModels = [[Configuration getInstance] autoReplyModels];
    [autoReplyModels enumerateObjectsUsingBlock:^(AutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!model.enable || !model.replyContent || model.replyContent.length == 0) {
            return;
        }
        
        if ((model.enableSpecificReply && ![model.specificContacts containsObject:userName])
            || ([addMsg.fromUserName.string containsString:@"@chatroom"] && !model.enableGroupReply)
            || (![addMsg.fromUserName.string containsString:@"@chatroom"] && !model.enableSingleReply)) {
            return;
        }
        
        [self replyWithMsg:addMsg model:model];
    }];
}

- (void)replyWithMsg:(AddMsg *)addMsg model:(AutoReplyModel *)model {
    NSString *msgContent = addMsg.content.string;
    if ([addMsg.fromUserName.string containsString:@"@chatroom"]) {
        NSRange range = [msgContent rangeOfString:@":\n"];
        if (range.length > 0) {
            msgContent = [msgContent substringFromIndex:range.location + range.length];
        }
    }
    
    NSArray *replyArray = [model.replyContent componentsSeparatedByString:@"|"];
    int index = arc4random() % replyArray.count;
    NSString *randomReplyContent = replyArray[index];
    NSInteger delayTime = model.enableDelay ? model.delayTime : 0;
    
    if (model.enableRegex) {
        NSString *regex = model.keyword;
        NSError *error;
        NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
        if (error) {
            return;
        }
        NSInteger count = [regular numberOfMatchesInString:msgContent options:NSMatchingReportCompletion range:NSMakeRange(0, msgContent.length)];
        if (count > 0) {
            [[HelperMessageService getInstance] sendTextMessage:randomReplyContent toUsrName:addMsg.fromUserName.string delay:delayTime];
        }
    } else {
        NSArray * keyWordArray = [model.keyword componentsSeparatedByString:@"|"];
        [keyWordArray enumerateObjectsUsingBlock:^(NSString *keyword, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([keyword isEqualToString:@"*"] || [msgContent isEqualToString:keyword]) {
                [[HelperMessageService getInstance] sendTextMessage:randomReplyContent toUsrName:addMsg.fromUserName.string delay:delayTime];
                *stop = YES;
            }
        }];
    }
}

#pragma mark - Replace NSSearchPathForDirectoriesInDomains and NSHomeDirectory
static NSArray<NSString *> *(*origNSSearchPathForDirectoriesInDomains)(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde);

NSArray<NSString *> *tweakNSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde) {
    NSMutableArray<NSString *> *paths = [origNSSearchPathForDirectoriesInDomains(directory, domainMask, expandTilde) mutableCopy];
    NSString *sandBoxPath = [NSString stringWithFormat:@"%@/Library/Containers/com.tencent.xinWeChat/Data",origNSHomeDirectory()];
    
    [paths enumerateObjectsUsingBlock:^(NSString *filePath, NSUInteger idx, BOOL * _Nonnull stop) {
        NSRange range = [filePath rangeOfString:origNSHomeDirectory()];
        if (range.length > 0) {
            NSMutableString *newFilePath = [filePath mutableCopy];
            [newFilePath replaceCharactersInRange:range withString:sandBoxPath];
            paths[idx] = newFilePath;
        }
    }];
    
    return paths;
}

static NSString *(*origNSHomeDirectory)(void);

NSString *tweakNSHomeDirectory(void) {
    return [NSString stringWithFormat:@"%@/Library/Containers/com.tencent.xinWeChat/Data",origNSHomeDirectory()];
}

@end
