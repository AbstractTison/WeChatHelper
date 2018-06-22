#import "AutoReplyCell.h"
#import "NSButton+Action.h"
#import "NSTextField+Action.h"
#import "NSView+Action.h"
#import "Macro.h"

@interface AutoReplyCell ()

@property (nonatomic, strong) NSButton *selectBtn;
@property (nonatomic, strong) NSTextField *keywordLabel;
@property (nonatomic, strong) NSTextField *replyContentLabel;
@property (nonatomic, strong) NSBox *bottomLine;

@end

@implementation AutoReplyCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews {
    self.selectBtn = ({
        NSButton *btn = [NSButton checkboxWithTitle:@"" target:self action:@selector(clickSelectBtn:)];
        btn.frame = NSMakeRect(5, 15, 20, 20);
        
        btn;
    });

    self.keywordLabel = ({
        NSTextField *label = [NSTextField labelWithString:@""];
        label.placeholderString = HelperLocalizedString(@"assistant.autoReply.keyword");
        [[label cell] setLineBreakMode:NSLineBreakByCharWrapping];
        [[label cell] setTruncatesLastVisibleLine:YES];
        label.font = [NSFont systemFontOfSize:10];
        label.frame = NSMakeRect(30, 30, 160, 15);
        
        label;
    });
    
    self.replyContentLabel = ({
        NSTextField *label = [NSTextField labelWithString:@""];
        label.placeholderString = HelperLocalizedString(@"assistant.autoReply.content");
        [[label cell] setLineBreakMode:NSLineBreakByCharWrapping];
        [[label cell] setTruncatesLastVisibleLine:YES];
        label.frame = NSMakeRect(30, 10, 160, 15);
        
        label;
    });
    
    self.bottomLine = ({
        NSBox *v = [[NSBox alloc] init];
        v.boxType = NSBoxSeparator;
        v.frame = NSMakeRect(0, 0, 200, 1);
        
        v;
    });
    
    [self addSubviews:@[self.selectBtn,
                        self.keywordLabel,
                        self.replyContentLabel,
                        self.bottomLine]];
}

- (void)clickSelectBtn:(NSButton *)btn {
    self.model.enable = btn.state;
    if (!self.model.enableSingleReply && !self.model.enableGroupReply && btn.state == YES) {
        self.model.enableSingleReply = YES;
        if (self.updateModel) self.updateModel();
    }
}

- (void)setModel:(AutoReplyModel *)model {
    _model = model;
    if (model.keyword == nil && model.replyContent == nil) return;
    
    self.selectBtn.state = model.enable;
    self.keywordLabel.stringValue = model.keyword != nil ? model.keyword : @"";
    self.replyContentLabel.stringValue = model.replyContent != nil ? model.replyContent : @"";
}

@end
