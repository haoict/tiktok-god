/**
 * @author Hao Nguyen
 */

#include "Tweak.h"

BOOL noads;
BOOL downloadWithoutWatermark;
BOOL autoPlayNextVideo;
BOOL changeRegion;
BOOL showProgressBar;
BOOL canHideUI;
BOOL enableFavoritesCollections;
NSDictionary *region;

static void reloadPrefs() {
    NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

    noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
    downloadWithoutWatermark = [[settings objectForKey:@"downloadWithoutWatermark"] ?: @(YES) boolValue];
    autoPlayNextVideo = [[settings objectForKey:@"autoPlayNextVideo"] ?: @(NO) boolValue];
    changeRegion = [[settings objectForKey:@"changeRegion"] ?: @(NO) boolValue];
    region = [settings objectForKey:@"region"] ?: [@{} mutableCopy];
    showProgressBar = [[settings objectForKey:@"showProgressBar"] ?: @(NO) boolValue];
    enableFavoritesCollections = [[settings objectForKey:@"enableFavoritesCollections"] ?: @(NO) boolValue];
    canHideUI = [[settings objectForKey:@"canHideUI"] ?: @(YES) boolValue];
}

%group CoreLogic
%hook AWEAwemeModel
- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    id orig = %orig;
    return noads && self.isAds ? nil : orig;
}

- (id)init {
    id orig = %orig;
    return noads && self.isAds ? nil : orig;
}

- (BOOL)progressBarDraggable {
    return showProgressBar || %orig;
}
- (BOOL)progressBarVisible {
    return showProgressBar || %orig;
}
%end

%hook CTCarrier
// Thanks chenxk-j for this
// https://github.com/chenxk-j/hookTikTok/blob/master/hooktiktok/hooktiktok.xm#L23
- (NSString *)mobileCountryCode {
    return (changeRegion && region[@"mcc"] != nil) ? region[@"mcc"] : %orig;
}

- (NSString *)isoCountryCode {
    return (changeRegion && region[@"code"] != nil) ? region[@"code"] : %orig;
}

- (NSString *)mobileNetworkCode {
    return (changeRegion && region[@"mnc"] != nil) ? region[@"mnc"] : %orig;
}
%end

%hook AWEPlayVideoPlayerController
- (void)playerWillLoopPlaying:(id)arg1 {
    if (autoPlayNextVideo) {
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
%property (nonatomic, retain) UIButton *hideUIButton;
%property (nonatomic, retain) UIButton *downloadButton;

- (void)viewDidLoad {
    %orig;

    if (downloadWithoutWatermark) {
        self.downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.downloadButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [self.downloadButton addTarget:self action:@selector(downloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        // [self.downloadButton setTitle:@"Download" forState:UIControlStateNormal];
        [self.downloadButton setImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/tiktokgod/download.png"] forState:UIControlStateNormal];
        self.downloadButton.imageEdgeInsets = UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);
        self.downloadButton.frame = CGRectMake(self.view.frame.size.width - 30 - 10, 135.0, 30.0, 30.0);
        [self.view addSubview:self.downloadButton];
    }

    if (canHideUI) {
        AWEFeedContainerViewController *afcVC = (AWEFeedContainerViewController *)[%c(AWEFeedContainerViewController) sharedInstance];
        self.hideUIButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.hideUIButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [self.hideUIButton addTarget:self action:@selector(hideUIButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        // [self.hideUIButton setTitle:afcVC.isUIHidden?@"Show UI":@"Hide UI" forState:UIControlStateNormal];
        [self.hideUIButton setImage:[UIImage imageWithContentsOfFile:afcVC.isUIHidden?@"/Library/Application Support/tiktokgod/showui.png":@"/Library/Application Support/tiktokgod/hideui.png"] forState:UIControlStateNormal];
        self.hideUIButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.hideUIButton.imageEdgeInsets = UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);
        self.hideUIButton.frame = CGRectMake(self.view.frame.size.width - 30 - 10, 100.0, 30.0, 30.0);
        [self.view addSubview:self.hideUIButton];
    }
}

- (void)stopLoadingAnimation {
    %orig;
    if (canHideUI) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateShowOrHideUI];
        });
    }
}

%new
- (void)hideUIButtonPressed:(UIButton *)sender {
    AWEFeedContainerViewController *afcVC = (AWEFeedContainerViewController *)[%c(AWEFeedContainerViewController) sharedInstance];
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
    AWEFeedContainerViewController *afcVC = (AWEFeedContainerViewController *)[%c(AWEFeedContainerViewController) sharedInstance];
    [self setHide:afcVC.isUIHidden];
    [self.downloadButton setHidden:afcVC.isUIHidden];
    // [self.hideUIButton setTitle:afcVC.isUIHidden?@"Show UI":@"Hide UI" forState:UIControlStateNormal];
    [self.hideUIButton setImage:[UIImage imageWithContentsOfFile:afcVC.isUIHidden?@"/Library/Application Support/tiktokgod/showui.png":@"/Library/Application Support/tiktokgod/hideui.png"] forState:UIControlStateNormal];
    if ([self.parentViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
        [afcVC setAccessoriesHidden:afcVC.isUIHidden];
    }

    afcVC.tabControl.hidden = afcVC.isUIHidden;
    afcVC.specialEventEntranceView.hidden = afcVC.isUIHidden;
}
%end
    
%hook AWEFavoriteAwemeViewController
- (id)init {
    if (enableFavoritesCollections) {
        return [%c(TTKFavoriteAwemeCollectionsViewController) new];
    } else {
        return %orig;
    }
}
%end

%hook AWEShareLinkModel
NSString* fullURLShared;
-(void)setTextForCopy:(id)arg1 {
	if ([(NSString*)arg1 containsString:@"@"]) {
		fullURLShared = [self parsedURL:arg1];
	}
	%orig(fullURLShared);
}

%new
-(NSString *)parsedURL:(NSString *)fullURL {
	
	NSRange  searchedRange = NSMakeRange(0, [fullURL length]);
	NSString *pattern = @"(.+?(?=\\\?))";
	NSError  *error = nil;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:&error];
	NSArray* matches = [regex matchesInString:fullURL options:0 range: searchedRange];
	for (NSTextCheckingResult* match in matches) {
		NSRange group1 = [match rangeAtIndex:1];
		return [fullURL substringWithRange:group1];
	}
	return nil;
}
%end
%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    reloadPrefs();

    %init(CoreLogic);
}

