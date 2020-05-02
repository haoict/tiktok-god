
#define TWEAK_TITLE "TikTok God"
#define PREF_BUNDLE_PATH "/Library/PreferenceBundles/TTGPref.bundle"
#define kTintColor [UIColor colorWithRed:0.00 green:0.00 blue:0.00 alpha:1.00];

@interface NSTask : NSObject
@property (copy) NSArray *arguments;
@property (copy) NSString *currentDirectoryPath;
@property (copy) NSDictionary *environment;
@property (copy) NSString *launchPath;
@property (readonly) int processIdentifier;
@property (retain) id standardError;
@property (retain) id standardInput;
@property (retain) id standardOutput;
+ (id)currentTaskDictionary;
+ (id)launchedTaskWithDictionary:(id)arg1;
+ (id)launchedTaskWithLaunchPath:(id)arg1 arguments:(id)arg2;
- (id)init;
- (void)interrupt;
- (bool)isRunning;
- (void)launch;
- (bool)resume;
- (bool)suspend;
- (void)terminate;
@end

@interface HaoPSUtil : NSObject
+ (NSString *)localizedItem:(NSString *)key;
+ (UIColor *)colorFromHex:(NSString *)hexString;
@end