#import "MMChatsTableCellView+Tweaker.h"
#import "NSMenu+Action.h"
#import "Macro.h"
#import "WeChatHelper.h"
#import "IgnoreSessionModel.h"

@implementation NSObject (MMChatsTableCellViewTweaker)

+ (void)tweakMMChatsTableCellView {
    tweakInstanceMethod(objc_getClass("MMChatsTableCellView"), @selector(menuWillOpen:), [self class], @selector(tweakMenuWillOpen:));
    tweakInstanceMethod(objc_getClass("MMChatsTableCellView"), @selector(setSessionInfo:), [self class], @selector(tweakSetSessionInfo:));
    tweakInstanceMethod(objc_getClass("MMChatsTableCellView"), @selector(contextMenuSticky:), [self class], @selector(tweakContextMenuSticky:));
    tweakInstanceMethod(objc_getClass("MMChatsTableCellView"), @selector(contextMenuDelete:), [self class], @selector(tweakContextMenuDelete:));
    tweakInstanceMethod(objc_getClass("MMChatsViewController"), @selector(tableView:rowGotMouseDown:), [self class], @selector(tweakTableView:rowGotMouseDown:));
}

- (void)tweakTableView:(NSTableView *)arg1 rowGotMouseDown:(long long)arg2 {
    [self tweakTableView:arg1 rowGotMouseDown:arg2];
    
    if ([[Configuration getInstance] multipleSelectionEnable]) {
        NSMutableArray *selectSessions = [[Configuration getInstance] selectSessions];
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        MMSessionInfo *sessionInfo = [sessionMgr GetSessionAtIndex:arg2];
        if ([selectSessions containsObject:sessionInfo]) {
            [selectSessions removeObject:sessionInfo];
        } else {
            [selectSessions addObject:sessionInfo];
        }
        [arg1 reloadData];
    }
}

- (void)tweakSetSessionInfo:(MMSessionInfo *)sessionInfo {
    [self tweakSetSessionInfo:sessionInfo];
    
    MMChatsTableCellView *cellView = (MMChatsTableCellView *)self;
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    __block BOOL isIgnore = false;
    NSMutableArray *ignoreSessions = [[Configuration getInstance] ignoreSessionModels];
    [ignoreSessions enumerateObjectsUsingBlock:^(IgnoreSessionModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
            isIgnore = true;
            *stop = YES;
        }
    }];
    
    NSMutableArray *selectSessions = [[Configuration getInstance] selectSessions];
    if (isIgnore) {
        cellView.layer.backgroundColor = RGBA(0x2a, 0x2a, 0x2a, 0.5).CGColor;
    } else if ([selectSessions containsObject:sessionInfo]){
        cellView.layer.backgroundColor = RGBA(0x7a, 0x7a, 0x7a, 0.5).CGColor;
    } else {
        cellView.layer.backgroundColor = [NSColor clearColor].CGColor;
    }
    [cellView.layer setNeedsDisplay];
}

- (void)tweakMenuWillOpen:(NSMenu *)arg1 {
    MMChatsTableCellView *cellView = (MMChatsTableCellView *)self;
    MMSessionInfo *sessionInfo = [cellView sessionInfo];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    __block BOOL isIgnore = false;
    NSMutableArray *ignoreSessions = [[Configuration getInstance] ignoreSessionModels];
    [ignoreSessions enumerateObjectsUsingBlock:^(IgnoreSessionModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
            isIgnore = true;
            *stop = YES;
        }
    }];

    NSString *itemString = isIgnore ? HelperLocalizedString(@"assistant.chat.unStickyBottom") : HelperLocalizedString(@"assistant.chat.stickyBottom");
    NSMenuItem *preventRevokeItem = [[NSMenuItem alloc] initWithTitle:itemString action:@selector(contextMenuStickyBottom) keyEquivalent:@""];
    
    BOOL multipleSelectionEnable = [[Configuration getInstance] multipleSelectionEnable];
    NSString *multipleSelectionString = multipleSelectionEnable ? HelperLocalizedString(@"assistant.chat.unMultiSelect") : HelperLocalizedString(@"assistant.chat.multiSelect");
    NSMenuItem *multipleSelectionItem = [[NSMenuItem alloc] initWithTitle:multipleSelectionString action:@selector(contextMenuMutipleSelection) keyEquivalent:@""];
    
    NSMenuItem *clearUnReadItem = [[NSMenuItem alloc] initWithTitle:HelperLocalizedString(@"assistant.chat.readAll") action:@selector(contextMenuClearUnRead) keyEquivalent:@""];
    
    NSMenuItem *clearEmptySessionItem = [[NSMenuItem alloc] initWithTitle:HelperLocalizedString(@"assistant.chat.clearEmpty") action:@selector(contextMenuClearEmptySession) keyEquivalent:@""];
    [arg1 addItems:@[[NSMenuItem separatorItem],
                     preventRevokeItem,
                     multipleSelectionItem,
                     clearUnReadItem,
                     clearEmptySessionItem
                     ]];
    [self tweakMenuWillOpen:arg1];
}

- (void)contextMenuStickyBottom {
    MMChatsTableCellView *cellView = (MMChatsTableCellView *)self;
    MMSessionInfo *sessionInfo = [cellView sessionInfo];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    NSMutableArray *ignoreSessions = [[Configuration getInstance] ignoreSessionModels];
    __block NSInteger index = -1;
    [ignoreSessions enumerateObjectsUsingBlock:^(IgnoreSessionModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqualToString:currentUserName]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    
    if (index == -1 && sessionInfo.m_nsUserName) {
        IgnoreSessionModel *model = [[IgnoreSessionModel alloc] init];
        model.userName = sessionInfo.m_nsUserName;
        model.selfContact = currentUserName;
        model.ignore = true;
        [ignoreSessions addObject:model];
        if (!sessionInfo.m_bShowUnReadAsRedDot) {
            [sessionMgr MuteSessionByUserName:sessionInfo.m_nsUserName];
        }
        if (sessionInfo.m_bIsTop) {
            [sessionMgr UntopSessionByUserName:sessionInfo.m_nsUserName];
        } 
    } else {
        [ignoreSessions removeObjectAtIndex:index];
        if (sessionInfo.m_bShowUnReadAsRedDot && sessionInfo.m_nsUserName) {
            [sessionMgr UnmuteSessionByUserName:sessionInfo.m_nsUserName];
        }
    }
    [sessionMgr sortSessions];
}

- (void)contextMenuMutipleSelection {
    BOOL multipleSelectionEnable = [[Configuration getInstance] multipleSelectionEnable];
    if (multipleSelectionEnable) {
        [[[Configuration getInstance] selectSessions] removeAllObjects];
        WeChat *WeChatInstance = [objc_getClass("WeChat") sharedInstance];
        [WeChatInstance.chatsViewController.tableView reloadData];
    }
    
    [[Configuration getInstance] setMultipleSelectionEnable:!multipleSelectionEnable];
}

- (void)contextMenuClearUnRead {
    MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    NSMutableArray *arrSession = sessionMgr.m_arrSession;

    [arrSession enumerateObjectsUsingBlock:^(MMSessionInfo *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [msgService ClearUnRead:obj.m_nsUserName FromID:0 ToID:0];
        });
    }];
}

- (void)contextMenuClearEmptySession {
    MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
    MessageService *msgService = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MessageService")];
    
    NSMutableArray *arrSession = sessionMgr.m_arrSession;
    NSMutableArray *emptyArrSession = [NSMutableArray array];
    
    [arrSession enumerateObjectsUsingBlock:^(MMSessionInfo *sessionInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL hasEmplyMsgSession = ![msgService hasMsgInChat:sessionInfo.m_nsUserName];
        WCContactData *contact = sessionInfo.m_packedInfo.m_contact;
        if (![sessionInfo.m_nsUserName isEqualToString:@"brandsessionholder"] && ![contact isSelf] && hasEmplyMsgSession) {
            [emptyArrSession addObject:sessionInfo];
        }
    }];
    
    while (emptyArrSession.count > 0) {
        [emptyArrSession enumerateObjectsUsingBlock:^(MMSessionInfo *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [sessionMgr deleteSessionWithoutSyncToServerWithUserName:obj.m_nsUserName];
            [emptyArrSession removeObject:obj];
        }];
    }
}

- (void)tweakContextMenuSticky:(id)arg1 {
    [self tweakContextMenuSticky:arg1];
    
    MMChatsTableCellView *cellView = (MMChatsTableCellView *)self;
    MMSessionInfo *sessionInfo = [cellView sessionInfo];
    if (!sessionInfo.m_bIsTop) return;
    
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    NSMutableArray *ignoreSessions = [[Configuration getInstance] ignoreSessionModels];
    __block NSInteger index = -1;
    [ignoreSessions enumerateObjectsUsingBlock:^(IgnoreSessionModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([model.userName isEqualToString:sessionInfo.m_nsUserName] && [model.selfContact isEqual:currentUserName]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    if (index != -1) {
        [ignoreSessions removeObjectAtIndex:index];
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        
        if (sessionInfo.m_bShowUnReadAsRedDot && sessionInfo.m_nsUserName) {
            [sessionMgr UnmuteSessionByUserName:sessionInfo.m_nsUserName];
        }
        [sessionMgr sortSessions];
    }
}

- (void)tweakContextMenuDelete:(id)arg1 {
    BOOL multipleSelection = [[Configuration getInstance] multipleSelectionEnable];
    
    if (multipleSelection) {
        MMSessionMgr *sessionMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("MMSessionMgr")];
        NSMutableArray *selectSessions = [[Configuration getInstance] selectSessions];
        
        [selectSessions  enumerateObjectsUsingBlock:^(MMSessionInfo *sessionInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *sessionUserName = sessionInfo.m_nsUserName;
            if (sessionUserName.length != 0) {
                [sessionMgr deleteSessionWithoutSyncToServerWithUserName:sessionUserName];
            }
        }];
        [[Configuration getInstance] setMultipleSelectionEnable:NO];
        WeChat *WeChatInstance = [objc_getClass("WeChat") sharedInstance];
        [WeChatInstance.chatsViewController.tableView reloadData];
    } else {
        [self tweakContextMenuDelete:arg1];
    }
}

@end
