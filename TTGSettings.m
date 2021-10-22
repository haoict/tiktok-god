//
//  TTGSettings.m
//  tiktok-god
//  
//  Created by Tanner Bennett on 2021-10-16
//

#import "TTGSettings.h"

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.tiktokgodpref.plist"

@implementation TTGSettings

+ (TTGSettings *)shared {
    static TTGSettings *singleton = nil;
    if (!singleton) {
        singleton = [self new];
        [singleton reloadPrefs];
    }

    return singleton;
}

- (NSString *)prefsPath {
    return @PLIST_PATH;
}

- (NSDictionary<NSString *,id> *)prefs {
    return [NSDictionary dictionaryWithContentsOfFile:self.prefsPath] ?: @{
        @"noads": @YES,
        @"downloadWithoutWatermark": @YES,
        @"canHideUI": @YES,
    };
}

- (void)reloadPrefs {
    NSDictionary *settings = self.prefs;
    for (NSString *key in settings) {
        [self setValue:settings[key] forKey:key];
    }
}

@end
