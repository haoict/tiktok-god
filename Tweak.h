#import <Foundation/Foundation.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.tiktokgodpref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.tiktokgodpref/PrefChanged"

@interface AWEAwemeModel : NSObject
// @property(nonatomic) BOOL allowDownloadWithoutWatermark;
@property(nonatomic) BOOL isAds;
@end