#include "Tweak.h"

/**
 * Load Preferences
 */
BOOL noads;
BOOL unlimitedDownload;

static void reloadPrefs() {
  NSDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH];

  noads = [[settings objectForKey:@"noads"] ?: @(YES) boolValue];
  unlimitedDownload = [[settings objectForKey:@"unlimitedDownload"] ?: @(YES) boolValue];
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

    // - (BOOL)allowDownloadWithoutWatermark {
    //   return TRUE;
    // }

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

