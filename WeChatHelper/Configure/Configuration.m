#import "Configuration.h"
#import "WeChatHelper.h"
#import "AutoReplyModel.h"
#import "IgnoreSessionModel.h"

static NSString * const kPreventRevokeEnableKey = @"kPreventRevokeEnableKey";
static NSString * const kAutoReplyEnableKey = @"kAutoReplyEnableKey";
static NSString * const kAutoAuthEnableKey = @"kAutoAuthEnableKey";
static NSString * const kOnTopKey = @"kOnTopKey";
static NSString * const kWeChatResourcesPath = @"/Applications/WeChat.app/Contents/MacOS/WeChatHelper.framework/Resources/";

@interface Configuration ()

@property (nonatomic, copy) NSString *autoReplyPlistFilePath;
@property (nonatomic, copy) NSString *ignoreSessionPlistFilePath;

@end

@implementation Configuration

+ (instancetype)getInstance {
    static Configuration *configuration = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ configuration = [[Configuration alloc] init]; });
    return configuration;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.preventRevokeEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kPreventRevokeEnableKey];
        self.autoReplyEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kAutoReplyEnableKey];
        self.autoAuthEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kAutoAuthEnableKey];
        self.stickyEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kOnTopKey];
    }
    return self;
}

- (void)setPreventRevokeEnable:(BOOL)preventRevokeEnable {
    _preventRevokeEnable = preventRevokeEnable;
    [[NSUserDefaults standardUserDefaults] setBool:preventRevokeEnable forKey:kPreventRevokeEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyEnable:(BOOL)autoReplyEnable {
    _autoReplyEnable = autoReplyEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoReplyEnable forKey:kAutoReplyEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoAuthEnable:(BOOL)autoAuthEnable {
    _autoAuthEnable = autoAuthEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoAuthEnable forKey:kAutoAuthEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setStickyEnable:(BOOL)stickyEnable {
    _stickyEnable = stickyEnable;
    [[NSUserDefaults standardUserDefaults] setBool:_stickyEnable forKey:kOnTopKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)autoReplyModels {
    if (!_autoReplyModels) {
        _autoReplyModels = [self getModelsWithClass:[AutoReplyModel class] filePath:self.autoReplyPlistFilePath];
    }
    return _autoReplyModels;
}

- (void)saveAutoReplyModels {
    NSMutableArray *needSaveModels = [NSMutableArray array];
    [_autoReplyModels enumerateObjectsUsingBlock:^(AutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model.hasEmptyKeywordOrReplyContent) {
            model.enable = NO;
            model.enableGroupReply = NO;
        }
        model.replyContent = model.replyContent == nil ? @"" : model.replyContent;
        model.keyword = model.keyword == nil ? @"" : model.keyword;
        [needSaveModels addObject:model.dictionary];
    }];
    [needSaveModels writeToFile:self.autoReplyPlistFilePath atomically:YES];
}

- (NSArray *)ignoreSessionModels {
    if (!_ignoreSessionModels) {
        _ignoreSessionModels = [self getModelsWithClass:[IgnoreSessionModel class] filePath:self.ignoreSessionPlistFilePath];
    }
    return _ignoreSessionModels;
}

- (void)saveIgnoreSessionModels {
    NSMutableArray *needSaveArray = [NSMutableArray array];
    [self.ignoreSessionModels enumerateObjectsUsingBlock:^(BaseModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [needSaveArray addObject:obj.dictionary];
    }];
    
    [needSaveArray writeToFile:self.ignoreSessionPlistFilePath atomically:YES];
    
}

- (NSMutableArray *)selectSessions {
    if (!_selectSessions) {
        _selectSessions = [NSMutableArray array];
    }
    return _selectSessions;
}

- (NSMutableSet *)revokeMsgSet {
    if (!_revokeMsgSet) {
        _revokeMsgSet = [NSMutableSet set];
    }
    return _revokeMsgSet;
}

- (NSString *)autoReplyPlistFilePath {
    if (!_autoReplyPlistFilePath) {
        _autoReplyPlistFilePath = [self getSandboxFilePathWithPlistName:@"AutoReplyModels.plist"];
    }
    return _autoReplyPlistFilePath;
}

- (NSString *)ignoreSessionPlistFilePath {
    if (!_ignoreSessionPlistFilePath) {
        _ignoreSessionPlistFilePath = [self getSandboxFilePathWithPlistName:@"IgnoreSessons.plist"];
    }
    return _ignoreSessionPlistFilePath;
}

- (NSMutableArray *)getModelsWithClass:(Class)class filePath:(NSString *)filePath {
    NSArray *originModels = [NSArray arrayWithContentsOfFile:filePath];
    NSMutableArray *newModels = [NSMutableArray array];
    
    __weak Class weakClass = class;
    [originModels enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IgnoreSessionModel *model = [[weakClass alloc] initWithDict:obj];
        [newModels addObject:model];
    }];
    return newModels;
}

- (NSString *)getSandboxFilePathWithPlistName:(NSString *)plistName {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *currentUserName = [objc_getClass("CUtility") GetCurrentUserName];
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *WeChatHelperDirectory = [documentDirectory stringByAppendingFormat:@"/WeChatHelper/%@/",currentUserName];
    NSString *plistFilePath = [WeChatHelperDirectory stringByAppendingPathComponent:plistName];
    if ([manager fileExistsAtPath:plistFilePath]) {
        return plistFilePath;
    }
    
    [manager createDirectoryAtPath:WeChatHelperDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *resourcesFilePath = [kWeChatResourcesPath stringByAppendingString:plistName];
    if (![manager fileExistsAtPath:resourcesFilePath]) {
        return plistFilePath;
    }
    
    NSError *error = nil;
    [manager copyItemAtPath:resourcesFilePath toPath:plistFilePath error:&error];
    if (!error) {
        return plistFilePath;
    }
    return resourcesFilePath;
}

@end

