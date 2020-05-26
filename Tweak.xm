#include "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;
BOOL unlimitedDownload;
BOOL downloadWithoutWatermark;
BOOL autoPlayNextVideo;
BOOL changeRegion;
NSDictionary *region;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  unlimitedDownload = [[settings objectForKey:@"unlimitedDownload"] ?: @(YES) boolValue];
  downloadWithoutWatermark = [[settings objectForKey:@"downloadWithoutWatermark"] ?: @(YES) boolValue];
  autoPlayNextVideo = [[settings objectForKey:@"autoPlayNextVideo"] ?: @(NO) boolValue];
  changeRegion = [[settings objectForKey:@"changeRegion"] ?: @(NO) boolValue];
  region = [settings objectForKey:@"region"] ?: [@{} mutableCopy];
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


/**
 * Constructor
 */
%ctor {
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) reloadPrefs, CFSTR(PREF_CHANGED_NOTIF), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
  reloadPrefs();

  %init(CoreLogic);
}

