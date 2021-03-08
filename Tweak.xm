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

  %hook AWEFeedGuideManager
    - (BOOL)enableAutoplay {
      return autoPlayNextVideo;
    }
  %end

  %hook AWEPlayVideoViewController
    - (void)playerWillLoopPlaying:(id)arg1 {
      // For Tiktok 17.x.x
      if (autoPlayNextVideo) {
        if ([self.parentViewController.parentViewController isKindOfClass:%c(AWEFeedTableViewController)]) {
          [((AWEFeedTableViewController *)self.parentViewController.parentViewController) scrollToNextVideo];
          return;
        }
      }
      %orig;
    }
  %end

  %hook AWEAwemePlayVideoViewController
    - (void)playerWillLoopPlaying:(id)arg1 {
      // For Tiktok 17.x.x
      if (autoPlayNextVideo) {
        if ([self.parentViewController.parentViewController isKindOfClass:%c(AWEFeedTableViewController)]) {
          [((AWEFeedTableViewController *)self.parentViewController.parentViewController) scrollToNextVideo];
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
    %property (nonatomic, retain) NSTimer *sliderTimer;
    %property (nonatomic, retain) UISlider *slider;
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

      if (showProgressBar) {
        // make circle thumb for slider
        CGFloat radius = 16.0;
        UIView *thumbView = [[UIView alloc] initWithFrame:CGRectMake(0, radius / 2, radius, radius)];
        thumbView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        thumbView.layer.borderWidth = 0.4;
        thumbView.layer.borderColor = [UIColor whiteColor].CGColor;
        thumbView.layer.cornerRadius = radius / 2;
        UIGraphicsBeginImageContextWithOptions(thumbView.bounds.size, NO, 0.0);
        [thumbView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *thumbImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        // create slider
        CGRect frame = CGRectMake(0.0, self.view.frame.size.height - ([HCommon isNotch] ? 96.0 : 54.0), self.view.frame.size.width, 10.0);
        self.slider = [[UISlider alloc] initWithFrame:frame];
        [self.slider addTarget:self action:@selector(onSliderValChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
        [self.slider setBackgroundColor:[UIColor clearColor]];
        self.slider.minimumValue = 0.0;
        self.slider.maximumValue = 100.0;
        self.slider.continuous = YES;
        self.slider.value = 0.0;
        self.slider.minimumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        self.slider.maximumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        [self.slider setThumbImage:thumbImg forState:UIControlStateNormal];
        self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:self.slider repeats:TRUE];
        [self.view addSubview:self.slider];
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
    - (void)onSliderValChanged:(UISlider *)slider forEvent:(UIEvent *)event {
      UITouch *touchEvent = [[event allTouches] anyObject];
      switch (touchEvent.phase) {
        case UITouchPhaseBegan: {
          if (self.sliderTimer != nil) {
            [self.sliderTimer invalidate];
            self.sliderTimer = nil;
          }
          break;
        }
        case UITouchPhaseMoved: {
          break;
        }
        case UITouchPhaseEnded: {
          double duration = [self.model.video.duration doubleValue] / 1000.0 - 2.3;
          double seekTime = slider.value / 100.0 * (duration);
          [self.videoDelegate setPlayerSeekTime:seekTime completion:nil];
          if (self.sliderTimer == nil) {
            self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:slider repeats:TRUE];
          }
          break;
        }
        case UITouchPhaseStationary: {
          if (self.sliderTimer == nil) {
            self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:slider repeats:TRUE];
          }
        }
        default:
          break;
      }
    }

    %new
    - (void)timerAction:(NSTimer *)timer {
      UISlider *slider = (UISlider *)timer.userInfo;
      double percent = [self currentPlayerPlaybackTime] / ([self.model.video.duration doubleValue] / 1000.0 - 2.3) * 100.0;
      [slider setValue:percent animated:TRUE];
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
      [self.slider setHidden:afcVC.isUIHidden];
      [self.hDownloadButton setHidden:afcVC.isUIHidden];
      // [self.hideUIButton setTitle:afcVC.isUIHidden?@"Show UI":@"Hide UI" forState:UIControlStateNormal];
      [self.hideUIButton setImage:[UIImage imageWithContentsOfFile:afcVC.isUIHidden?@"/Library/Application Support/tiktokgod/showui.png":@"/Library/Application Support/tiktokgod/hideui.png"] forState:UIControlStateNormal];
      if ([self.parentViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
        [afcVC setAccessoriesHidden:afcVC.isUIHidden];
      }

      afcVC.tabControl.hidden = afcVC.isUIHidden;
      afcVC.specialEventEntranceView.hidden = afcVC.isUIHidden;
    }

    - (void)showDislikeOnVideo {
      if (self.sliderTimer == nil) {
        self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:self.slider repeats:TRUE];
      }
      %orig;
    }
  %end

  %hook AWEAwemePlayInteractionViewController
    %property (nonatomic, retain) NSTimer *sliderTimer;
    %property (nonatomic, retain) UISlider *slider;
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

      if (showProgressBar) {
        // make circle thumb for slider
        CGFloat radius = 16.0;
        UIView *thumbView = [[UIView alloc] initWithFrame:CGRectMake(0, radius / 2, radius, radius)];
        thumbView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
        thumbView.layer.borderWidth = 0.4;
        thumbView.layer.borderColor = [UIColor whiteColor].CGColor;
        thumbView.layer.cornerRadius = radius / 2;
        UIGraphicsBeginImageContextWithOptions(thumbView.bounds.size, NO, 0.0);
        [thumbView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *thumbImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        // create slider
        CGRect frame = CGRectMake(0.0, self.view.frame.size.height - ([HCommon isNotch] ? 96.0 : 54.0), self.view.frame.size.width, 10.0);
        self.slider = [[UISlider alloc] initWithFrame:frame];
        [self.slider addTarget:self action:@selector(onSliderValChanged:forEvent:) forControlEvents:UIControlEventValueChanged];
        [self.slider setBackgroundColor:[UIColor clearColor]];
        self.slider.minimumValue = 0.0;
        self.slider.maximumValue = 100.0;
        self.slider.continuous = YES;
        self.slider.value = 0.0;
        self.slider.minimumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        self.slider.maximumTrackTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2];
        [self.slider setThumbImage:thumbImg forState:UIControlStateNormal];
        self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:self.slider repeats:TRUE];
        [self.view addSubview:self.slider];
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
    - (void)onSliderValChanged:(UISlider *)slider forEvent:(UIEvent *)event {
      UITouch *touchEvent = [[event allTouches] anyObject];
      switch (touchEvent.phase) {
        case UITouchPhaseBegan: {
          if (self.sliderTimer != nil) {
            [self.sliderTimer invalidate];
            self.sliderTimer = nil;
          }
          break;
        }
        case UITouchPhaseMoved: {
          break;
        }
        case UITouchPhaseEnded: {
          double duration = [self.model.video.duration doubleValue] / 1000.0 - 2.3;
          double seekTime = slider.value / 100.0 * (duration);
          [self.videoDelegate setPlayerSeekTime:seekTime completion:nil];
          if (self.sliderTimer == nil) {
            self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:slider repeats:TRUE];
          }
          break;
        }
        case UITouchPhaseStationary: {
          if (self.sliderTimer == nil) {
            self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:slider repeats:TRUE];
          }
        }
        default:
          break;
      }
    }

    %new
    - (void)timerAction:(NSTimer *)timer {
      UISlider *slider = (UISlider *)timer.userInfo;
      double percent = [self currentPlayerPlaybackTime] / ([self.model.video.duration doubleValue] / 1000.0 - 2.3) * 100.0;
      [slider setValue:percent animated:TRUE];
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
      [self.slider setHidden:afcVC.isUIHidden];
      [self.hDownloadButton setHidden:afcVC.isUIHidden];
      // [self.hideUIButton setTitle:afcVC.isUIHidden?@"Show UI":@"Hide UI" forState:UIControlStateNormal];
      [self.hideUIButton setImage:[UIImage imageWithContentsOfFile:afcVC.isUIHidden?@"/Library/Application Support/tiktokgod/showui.png":@"/Library/Application Support/tiktokgod/hideui.png"] forState:UIControlStateNormal];
      if ([self.parentViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
        [afcVC setAccessoriesHidden:afcVC.isUIHidden];
      }

      afcVC.tabControl.hidden = afcVC.isUIHidden;
      afcVC.specialEventEntranceView.hidden = afcVC.isUIHidden;
    }

    - (void)showDislikeOnVideo {
      if (self.sliderTimer == nil) {
        self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:self.slider repeats:TRUE];
      }
      %orig;
    }
  %end

  %hook AWEAwemeBaseViewController
    - (BOOL)gestureRecognizer:(id)arg1 shouldReceiveTouch:(UITouch *)arg2 {
      if (!showProgressBar) {
        return %orig;
      }

      if ([arg2.view isKindOfClass:[UISlider class]]) {
        // prevent recognizing touches on the slider
        // currently not working??
        return NO;
      }
      return YES;
    }
  %end
%end

%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  %init(CoreLogic);
}

