//
//  TTGSettings.h
//  tiktok-god
//  
//  Created by Tanner Bennett on 2021-10-16
//

#import <Foundation/Foundation.h>

@interface TTGSettings : NSObject

@property (nonatomic, readonly, class) TTGSettings *shared;
@property (nonatomic, readonly) NSString *prefsPath;
@property (nonatomic, readonly) NSDictionary *prefs;

@property (nonatomic, readonly) BOOL noads;
@property (nonatomic, readonly) BOOL downloadWithoutWatermark;
@property (nonatomic, readonly) BOOL autoPlayNextVideo;
@property (nonatomic, readonly) BOOL changeRegion;
@property (nonatomic, readonly) BOOL showProgressBar;
@property (nonatomic, readonly) BOOL canHideUI;
@property (nonatomic, readonly) BOOL enableFavoritesCollections;
@property (nonatomic, readonly) BOOL showAdditionalDownloadButton;
@property (nonatomic, readonly) NSDictionary *region;

- (void)reloadPrefs;

@end
