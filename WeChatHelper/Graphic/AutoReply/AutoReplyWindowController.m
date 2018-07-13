#import "AutoReplyWindowController.h"
#import "AutoReplyContentView.h"
#import "AutoReplyCell.h"
#import "Macro.h"
#import "NSButton+Action.h"
#import "WeChatHelper.h"
#import "NSView+Action.h"

@interface AutoReplyWindowController () <NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, strong) NSTableView *tableView;
@property (nonatomic, strong) AutoReplyContentView *contentView;
@property (nonatomic, strong) NSButton *addButton;
@property (nonatomic, strong) NSButton *reduceButton;
@property (nonatomic, strong) NSButton *enableButton;
@property (nonatomic, strong) NSAlert *alert;

@property (nonatomic, strong) NSMutableArray *autoReplyModels;
@property (nonatomic, assign) NSInteger lastSelectIndex;

@end

@implementation AutoReplyWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    [self initSubviews];
    [self setup];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [self.tableView reloadData];
    [self.contentView setHidden:YES];
    if (self.autoReplyModels && self.autoReplyModels.count == 0) {
        [self addModel];
    }
    if (self.autoReplyModels.count > 0 && self.tableView) {
         [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
    }
}

- (void)initSubviews {
    NSScrollView *scrollView = ({
        NSScrollView *scrollView = [[NSScrollView alloc] init];
        scrollView.hasVerticalScroller = YES;
        scrollView.frame = NSMakeRect(30, 50, 200, 375);
        scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

        scrollView;
    });
    
    self.tableView = ({
        NSTableView *tableView = [[NSTableView alloc] init];
        tableView.frame = scrollView.bounds;
        tableView.allowsTypeSelect = YES;
        tableView.delegate = self;
        tableView.dataSource = self;
        NSTableColumn *column = [[NSTableColumn alloc] init];
        column.title = HelperLocalizedString(@"assistant.autoReply.list");
        column.width = 200;
        [tableView addTableColumn:column];
        
        tableView;
    });
    
    self.contentView = ({
        AutoReplyContentView *contentView = [[AutoReplyContentView alloc] init];
        contentView.frame = NSMakeRect(250, 50, 400, 375);
        contentView.hidden = YES;
        
        contentView;
    });
    
    self.addButton = ({
        NSButton *btn = [NSButton buttonWithTitle:@"＋" target:self action:@selector(addModel)];
        btn.frame = NSMakeRect(30, 10, 40, 40);
        btn.bezelStyle = NSBezelStyleTexturedRounded;
        
        btn;
    });
    
    self.reduceButton = ({
        NSButton *btn = [NSButton buttonWithTitle:@"－" target:self action:@selector(reduceModel)];
        btn.frame = NSMakeRect(80, 10, 40, 40);
        btn.bezelStyle = NSBezelStyleTexturedRounded;
        btn.enabled = NO;
        
        btn;
    });
    
    self.enableButton = ({
        NSButton *btn = [NSButton checkboxWithTitle:HelperLocalizedString(@"assistant.autoReply.enable") target:self action:@selector(clickEnableBtn:)];
        btn.frame = NSMakeRect(130, 20, 130, 20);
        btn.state = [[Configuration getInstance] autoReplyEnable];
        
        btn;
    });
    
    self.alert = ({
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:HelperLocalizedString(@"assistant.autoReply.alert.confirm")];
        [alert setMessageText:HelperLocalizedString(@"assistant.autoReply.alert.title")];
        [alert setInformativeText:HelperLocalizedString(@"assistant.autoReply.alert.content")];
        
        alert;
    });
    
    scrollView.contentView.documentView = self.tableView;
    
    [self.window.contentView addSubviews:@[scrollView, self.contentView, self.addButton, self.reduceButton, self.enableButton]];
}

- (void)setup {
    self.window.title = HelperLocalizedString(@"assistant.autoReply.title");
    self.window.contentView.layer.backgroundColor = [RGBA(0xec, 0xec, 0xec, 1.0) CGColor];
    [self.window.contentView.layer setNeedsDisplay];
    
    self.lastSelectIndex = -1;
    self.autoReplyModels = [[Configuration getInstance] autoReplyModels];
    [self.tableView reloadData];
    
    __weak typeof(self) weakSelf = self;
    self.contentView.endEdit = ^(void) {
        [weakSelf.tableView reloadData];
        if (weakSelf.lastSelectIndex != -1) {
            [weakSelf.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:weakSelf.lastSelectIndex] byExtendingSelection:YES];
        }
    };
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowShouldClosed:) name:NSWindowWillCloseNotification object:nil];
}

#pragma mark - Listen to wiondow close
- (void)windowShouldClosed:(NSNotification *)notification {
    if (notification.object != self.window) {
        return;
    }
    [[Configuration getInstance] saveAutoReplyModels];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Listen to addButton and reduceButton
- (void)addModel {
    if (self.contentView.hidden) {
        self.contentView.hidden = NO;
    }
    __block NSInteger emptyModelIndex = -1;
    [self.autoReplyModels enumerateObjectsUsingBlock:^(AutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
        if (model.hasEmptyKeywordOrReplyContent) {
            emptyModelIndex = idx;
            *stop = YES;
        }
    }];
    
    if (self.autoReplyModels.count > 0 && emptyModelIndex != -1) {
        [self.alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            if(returnCode == NSAlertFirstButtonReturn){
                if (self.tableView.selectedRow != -1) {
                    [self.tableView deselectRow:self.tableView.selectedRow];
                }
                [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:emptyModelIndex] byExtendingSelection:YES];
            }
        }];
        return;
    };
    
    AutoReplyModel *model = [[AutoReplyModel alloc] init];
    [self.autoReplyModels addObject:model];
    [self.tableView reloadData];
    self.contentView.model = model;
    
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
}

- (void)reduceModel {
    NSInteger index = self.tableView.selectedRow;
    if (index > -1) {
        [self.autoReplyModels removeObjectAtIndex:index];
        [self.tableView reloadData];
        if (self.autoReplyModels.count == 0) {
            self.contentView.hidden = YES;
            self.reduceButton.enabled = NO;
        } else {
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.autoReplyModels.count - 1] byExtendingSelection:YES];
        }
    }
}

- (void)clickEnableBtn:(NSButton *)btn {
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFY_AUTO_REPLY_CHANGE object:nil];
}

#pragma mark - NSTableViewDataSource and NSTableViewDelegate
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.autoReplyModels.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    AutoReplyCell *cell = [[AutoReplyCell alloc] init];
    cell.frame = NSMakeRect(0, 0, self.tableView.frame.size.width, 40);
    cell.model = self.autoReplyModels[row];
     __weak typeof(self) weakSelf = self;
    cell.updateModel = ^{
        weakSelf.contentView.model = weakSelf.autoReplyModels[row];
    };
    return cell;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 50;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    self.contentView.hidden = tableView.selectedRow == -1;
    self.reduceButton.enabled = tableView.selectedRow != -1;
    
    if (tableView.selectedRow != -1) {
        AutoReplyModel *model = self.autoReplyModels[tableView.selectedRow];
        self.contentView.model = model;
        self.lastSelectIndex = tableView.selectedRow;
        __block NSInteger emptyModelIndex = -1;
        [self.autoReplyModels enumerateObjectsUsingBlock:^(AutoReplyModel *model, NSUInteger idx, BOOL * _Nonnull stop) {
            if (model.hasEmptyKeywordOrReplyContent) {
                emptyModelIndex = idx;
                *stop = YES;
            }
        }];
        
        if (emptyModelIndex != -1 && tableView.selectedRow != emptyModelIndex) {
            [self.alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
                if(returnCode == NSAlertFirstButtonReturn){
                    if (self.tableView.selectedRow != -1) {
                        [self.tableView deselectRow:self.tableView.selectedRow];
                    }
                    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:emptyModelIndex] byExtendingSelection:YES];
                }
            }];
        }
    }
}

@end