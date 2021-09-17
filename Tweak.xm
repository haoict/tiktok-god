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
BOOL showAdditionalDownloadButton;
NSDictionary *region;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  downloadWithoutWatermark = [[settings objectForKey:@"downloadWithoutWatermark"] ?: @(YES) boolValue];
  autoPlayNextVideo = [[settings objectForKey:@"autoPlayNextVideo"] ?: @(NO) boolValue];
  changeRegion = [[settings objectForKey:@"changeRegion"] ?: @(NO) boolValue];
  region = [settings objectForKey:@"region"] ?: [@{} mutableCopy];
  showProgressBar = [[settings objectForKey:@"showProgressBar"] ?: @(NO) boolValue];
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
      self.isUIHidden = FALSE;
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
    %property (nonatomic, retain) UIButton *hDownloadButton;

    - (void)viewDidLoad {
      %orig;

      if (downloadWithoutWatermark) {
        self.hDownloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.hDownloadButton.titleLabel setFont:[UIFont systemFontOfSize:15]];
        [self.hDownloadButton addTarget:self action:@selector(hDownloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        // [self.hDownloadButton setTitle:@"Download" forState:UIControlStateNormal];
        [self.hDownloadButton setImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/tiktokgod/download.png"] forState:UIControlStateNormal];
        self.hDownloadButton.imageEdgeInsets = UIEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);
        self.hDownloadButton.frame = CGRectMake(self.view.frame.size.width - 30 - 10, 135.0, 30.0, 30.0);
        [self.view addSubview:self.hDownloadButton];
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
    - (void)hDownloadButtonPressed:(UIButton *)sender {
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
      [self.hDownloadButton setHidden:afcVC.isUIHidden];
      // [self.hideUIButton setTitle:afcVC.isUIHidden?@"Show UI":@"Hide UI" forState:UIControlStateNormal];
      [self.hideUIButton setImage:[UIImage imageWithContentsOfFile:afcVC.isUIHidden?@"/Library/Application Support/tiktokgod/showui.png":@"/Library/Application Support/tiktokgod/hideui.png"] forState:UIControlStateNormal];
      if ([self.parentViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
        [afcVC setAccessoriesHidden:afcVC.isUIHidden];
      }

      afcVC.tabControl.hidden = afcVC.isUIHidden;
      afcVC.specialEventEntranceView.hidden = afcVC.isUIHidden;
    }
  %end
%end

%group JailbreakBypass
  %hook AppsFlyerUtils
    + (BOOL)isJailbrokenWithSkipAdvancedJailbreakValidation:(BOOL)arg1 {
      return NO;
    }
  %end

  %hook BDADeviceHelper
    + (BOOL)isJailBroken {
      return NO;
    }
  %end

  %hook BDInstallNetworkUtility
    + (BOOL)isJailBroken {
      return NO;
    }
  %end

  %hook IESLiveDeviceInfo
    + (BOOL)isJailBroken {
      return NO;
    }
  %end

  %hook PIPOStoreKitHelper
    + (BOOL)isJailBroken {
      return NO;
    }
  %end

  %hook TTAdSplashDeviceHelper
    + (BOOL)isJailBroken {
      return NO;
    }
  %end

  %hook TTInstallUtil
    + (BOOL)isJailBroken {
      return NO;
    }
  %end

  %hook PIPOIAPStoreManager
    - (BOOL)_pipo_isJailBrokenDeviceWithProductID:(id)arg1 orderID:(id)arg2 {
      return NO;
    }
  %end

  %hook UIDevice
    + (BOOL)btd_isJailBroken {
      return NO;
    }
  %end
%end

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  %init(CoreLogic);
  %init(JailbreakBypass);
}

