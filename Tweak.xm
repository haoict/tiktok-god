#include "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;
BOOL unlimitedDownload;
BOOL downloadWithoutWatermark;
BOOL autoPlayNextVideo;
BOOL changeRegion;
BOOL showProgressBar;
NSDictionary *region;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  unlimitedDownload = [[settings objectForKey:@"unlimitedDownload"] ?: @(YES) boolValue];
  downloadWithoutWatermark = [[settings objectForKey:@"downloadWithoutWatermark"] ?: @(YES) boolValue];
  autoPlayNextVideo = [[settings objectForKey:@"autoPlayNextVideo"] ?: @(NO) boolValue];
  changeRegion = [[settings objectForKey:@"changeRegion"] ?: @(NO) boolValue];
  region = [settings objectForKey:@"region"] ?: [@{} mutableCopy];
  showProgressBar = [[settings objectForKey:@"showProgressBar"] ?: @(NO) boolValue];
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

    - (BOOL)preventDownload {
      return unlimitedDownload ? FALSE : %orig;
    }

    - (BOOL)disableDownload {
      return unlimitedDownload ? FALSE : %orig;
    }
  %end

  %hook AWEAwemePlayDislikeViewController
    - (BOOL)shouldShowDownload:(id)arg1 {
      return unlimitedDownload ? TRUE : %orig;
    }

    - (AWEAwemeDislikeNewReasonTableViewCell *)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
      AWEAwemeDislikeNewReasonTableViewCell *orig = %orig;
      if (downloadWithoutWatermark && orig.model.dislikeType == 1) {
        orig.titleLabel.text = [NSString stringWithFormat:@"%@%@", orig.titleLabel.text, @" - No Watermark"];
      }
      return orig;
    }

    - (void)tableView:(id)arg1 didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
      AWEAwemeDislikeNewReasonTableViewCell *cell = [self tableView:arg1 cellForRowAtIndexPath:indexPath];
      if (downloadWithoutWatermark && cell.model.dislikeType == 1) {
        [HDownloadMedia checkPermissionToPhotosAndDownload:self.model.video.playURL.originURLList.firstObject appendExtension:@"mp4" mediaType:Video toAlbum:@"TikTok"];
        [self dismissActionsWithExecutingBlock];
        return;
      }
      %orig;
    }
  %end

  // Thanks chenxk-j for this
  // https://github.com/chenxk-j/hookTikTok/blob/master/hooktiktok/hooktiktok.xm#L23
  %hook CTCarrier
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
%end

%group ShowProgressBar
  %hook AWEAwemePlayInteractionViewController
    %property (nonatomic, retain) NSTimer *sliderTimer;
    %property (nonatomic, retain) UISlider *slider;

    - (void)viewDidLoad {
      %orig;

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
      CGRect frame = CGRectMake(0.0, self.view.frame.size.height - 54, self.view.frame.size.width, 10.0);
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

    - (void)showDislikeOnVideo {
      if (self.sliderTimer == nil) {
        self.sliderTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerAction:) userInfo:self.slider repeats:TRUE];
      }
      %orig;
    }
  %end

  %hook AWEAwemeBaseViewController
    - (BOOL)gestureRecognizer:(id)arg1 shouldReceiveTouch:(UITouch *)arg2 {
      if ([arg2.view isKindOfClass:[UISlider class]]) {
        // prevent recognizing touches on the slider
        // currently not working??
        return NO;
      }
      return YES;
    }
  %end
%end


/**
 * Constructor
 */
%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  %init(CoreLogic);

  if (showProgressBar) {
    %init(ShowProgressBar);
  }
}

