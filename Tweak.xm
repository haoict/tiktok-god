/**
 * @author Hao Nguyen
 */

#import "Tweak.h"
#import "Masonry/Masonry.h"

#define kButtonAlpha 0.9

NSDictionary *region = nil;

static void reloadPrefs() {
    [TTGSettings.shared reloadPrefs];
    region = TTGSettings.shared.region;
}

static UIImage * UISystemImageNamed(NSString *name) {
    static UIImageSymbolConfiguration *imageConfig = nil;
    if (!imageConfig) {
        imageConfig = [UIImageSymbolConfiguration configurationWithPointSize:24];
    }
    
    return [UIImage systemImageNamed:name withConfiguration:imageConfig];
}

static id makeButton(id target, SEL handler, NSString *name, BOOL visible) {   
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:target action:handler forControlEvents:UIControlEventTouchUpInside];
    [button setImage:UISystemImageNamed(name) forState:UIControlStateNormal];
    button.tintColor = UIColor.whiteColor;
    button.alpha = kButtonAlpha;
    button.hidden = !visible;
    
    return button;
}

%group CoreLogic

%hook AWEAwemeModel
- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    self = %orig;
    return TTGSettings.shared.noads && self.isAds ? nil : self;
}

- (id)init {
    self = %orig;
    return TTGSettings.shared.noads && self.isAds ? nil : self;
}

- (BOOL)progressBarDraggable {
    return TTGSettings.shared.showProgressBar || %orig;
}

- (BOOL)progressBarVisible {
    return TTGSettings.shared.showProgressBar || %orig;
}
%end

%hook CTCarrier
// Thanks chenxk-j for this
// https://github.com/chenxk-j/hookTikTok/blob/master/hooktiktok/hooktiktok.xm#L23
- (NSString *)mobileCountryCode {
    return (TTGSettings.shared.changeRegion && region[@"mcc"] != nil) ? region[@"mcc"] : %orig;
}

- (NSString *)isoCountryCode {
    return (TTGSettings.shared.changeRegion && region[@"code"] != nil) ? region[@"code"] : %orig;
}

- (NSString *)mobileNetworkCode {
    return (TTGSettings.shared.changeRegion && region[@"mnc"] != nil) ? region[@"mnc"] : %orig;
}
%end

%hook AWEPlayVideoPlayerController
- (void)playerWillLoopPlaying:(id)arg1 {
    if (TTGSettings.shared.autoPlayNextVideo) {
        if ([self.container.parentViewController isKindOfClass:%c(AWEFeedTableViewController)]) {
            [((AWEFeedTableViewController *)self.container.parentViewController) scrollToNextVideo];
            return;
        }
    }
    %orig;
}
%end

%hook AWEFeedContainerViewController
static AWEFeedContainerViewController *__weak sharedInstance;
%property (nonatomic, assign) BOOL isUIHidden;

- (id)init {
    id orig = %orig;
    self.isUIHidden = NO;
    sharedInstance = orig;
    return orig;
}

%new
+ (AWEFeedContainerViewController *)sharedInstance {
    return sharedInstance;
}
%end

%hook AWEPlayInteractionViewController
%property (nonatomic, retain) UIStackView *ttgButtonStack;
%property (nonatomic, retain) UIButton *hideUIButton;
%property (nonatomic, retain) UIButton *downloadButton;

- (void)viewDidLoad {
    %orig;
    
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(toggleHideUI:)
    ];
    twoFingerTap.numberOfTouchesRequired = 2;
    [self.view addGestureRecognizer:twoFingerTap];

    self.downloadButton = makeButton(
        self, @selector(downloadButtonPressed:),
        @"icloud.and.arrow.down.fill",
        TTGSettings.shared.downloadWithoutWatermark
    );

    AWEFeedContainerViewController *afcVC = (id)[%c(AWEFeedContainerViewController) sharedInstance];
    self.hideUIButton = makeButton(
        self, @selector(toggleHideUI:),
        afcVC.isUIHidden ? @"eye.slash.fill" : @"eye.fill",
        TTGSettings.shared.canHideUI
    );
    
    self.ttgButtonStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.downloadButton, self.hideUIButton]];
    self.ttgButtonStack.axis = UILayoutConstraintAxisVertical;
    self.ttgButtonStack.spacing = 30;
    [self.ttgButtonStack sizeToFit];
    [self.view addSubview:self.ttgButtonStack];
    
    UIView *sibling = self.rightContainer.containerView;
    [self.ttgButtonStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.equalTo(sibling);
        make.leading.equalTo(sibling).offset(18);
        make.bottom.equalTo(sibling.mas_top).offset(-8);
    }];
}

- (void)stopLoadingAnimation {
    %orig;
    if (TTGSettings.shared.canHideUI) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateShowOrHideUI];
        });
    }
}

%new
- (void)toggleHideUI:(UIButton *)sender {
    AWEFeedContainerViewController *afcVC = (id)[%c(AWEFeedContainerViewController) sharedInstance];
    afcVC.isUIHidden = !afcVC.isUIHidden;
    [self updateShowOrHideUI];
}

%new
- (void)downloadButtonPressed:(UIButton *)sender {
    NSString *videoURLString = self.model.video.playURL.originURLList.firstObject;
    if ([videoURLString containsString:@".m3u8"]) {
        [HCommon showAlertMessage:@"This video format is not supported (.m3u8 file extension)" withTitle:@"Not supported" viewController:nil];
    }
    [[[HDownloadMediaWithProgress alloc] init] checkPermissionToPhotosAndDownload:videoURLString appendExtension:@"mp4" mediaType:Video toAlbum:@"TikTok" viewController:self];
}

%new
- (void)updateShowOrHideUI {
    AWEFeedContainerViewController *afcVC = (id)[%c(AWEFeedContainerViewController) sharedInstance];
    [self setHide:afcVC.isUIHidden];
    
    UIImage *eye = UISystemImageNamed(afcVC.isUIHidden ? @"eye.slash.fill" : @"eye.fill");
    [self.hideUIButton setImage:eye forState:UIControlStateNormal];
    if ([self.parentViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
        [afcVC setAccessoriesHidden:afcVC.isUIHidden];
    }
    
    self.hideUIButton.alpha = afcVC.isUIHidden ? 0.25 : kButtonAlpha;

    self.downloadButton.hidden = afcVC.isUIHidden || !TTGSettings.shared.downloadWithoutWatermark;
    afcVC.tabControl.hidden = afcVC.isUIHidden;
    afcVC.specialEventEntranceView.hidden = afcVC.isUIHidden;
    afcVC.searchEntranceView.hidden = afcVC.isUIHidden;
    afcVC.MTLiveEntranceView.hidden = afcVC.isUIHidden;
}
%end
    
%hook AWEFavoriteAwemeViewController
- (id)init {
    if (TTGSettings.shared.enableFavoritesCollections) {
        return [%c(TTKFavoriteAwemeCollectionsViewController) new];
    } else {
        return %orig;
    }
}
%end
%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    reloadPrefs();

    %init(CoreLogic);
}

