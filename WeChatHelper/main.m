#import "WeChat+Tweaker.h"
#import "MMChatsTableCellView+Tweaker.h"
#import "MMStickerMessageCellView+Tweaker.h"

static void __attribute__((constructor)) initialize(void) {
    NSLog(@"---------- WeChat TweakWrapper loaded ----------");
    [NSObject tweakWeChat];
    [NSObject tweakMMChatsTableCellView];
    [NSObject tweakMMStickerMessageCellView];
}
