#import <Foundation/Foundation.h>
#import <libhdev/HUtilities/HDownloadMedia.h>
#import <libhdev/HUtilities/HDownloadMediaWithProgress.h>

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.tiktokgodpref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.tiktokgodpref/PrefChanged"

@interface AWEURLModel : NSObject
@property(retain, nonatomic) NSArray* originURLList;
@end

@interface AWEVideoModel : NSObject
@property(readonly, nonatomic) AWEURLModel* playURL;
@property(readonly, nonatomic) AWEURLModel* downloadURL;
@property(readonly, nonatomic) NSNumber *duration;
@end

@interface AWEAwemeModel : NSObject
@property(nonatomic) BOOL isAds;
@property(retain, nonatomic) AWEVideoModel* video;
@end

@interface AWEAwemeDislikeNewReasonModel : NSObject
@property(retain, nonatomic) NSString *title;
@property(nonatomic) long long dislikeType;
@end

@interface AWEAwemeDislikeNewReasonTableViewCell : NSObject
@property(retain, nonatomic) AWEAwemeDislikeNewReasonModel *model;
@property(retain, nonatomic) UILabel *titleLabel;
@end

@interface AWEAwemePlayDislikeViewController : UIViewController
@property(retain, nonatomic) AWEAwemeModel *model;
- (AWEAwemeDislikeNewReasonTableViewCell *)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)dismissActionsWithExecutingBlock;
@end

@interface TIKTOKAwemePlayDislikeViewController : UIViewController
@property(retain, nonatomic) AWEAwemeModel *model;
- (AWEAwemeDislikeNewReasonTableViewCell *)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)dismissActionsWithExecutingBlock;
@end

@interface AWEPlayVideoViewController : UIViewController
- (void)setPlayerSeekTime:(double)arg1 completion:(id)arg2;
@end

@interface AWEAwemePlayVideoViewController : AWEPlayVideoViewController
@end

@interface AWEFeedContainerViewController : UIViewController
@property(nonatomic) BOOL isUIHidden; // new property
- (void)setAccessoriesHidden:(BOOL)arg1;
+ (AWEFeedContainerViewController *)sharedInstance; // new
@end

@interface AWEAwemePlayInteractionViewController : UIViewController
@property(retain, nonatomic) AWEAwemeModel *model;
@property(nonatomic) AWEAwemePlayVideoViewController *videoDelegate;
@property(nonatomic, retain) UISlider *slider; // new property
@property(nonatomic, retain) NSTimer *sliderTimer; // new property
@property(nonatomic, retain) UIButton *hideUIButton; // new property
@property(nonatomic, retain) UIButton *hDownloadButton; // new property
- (double)currentPlayerPlaybackTime;
- (void)setHide:(BOOL)arg1;
- (void)onSliderValChanged:(UISlider *)slider forEvent:(UIEvent *)event; // new
- (void)timerAction:(NSTimer *)timer; // new
- (void)hideUIButtonPressed; // new
- (void)updateShowOrHideUI; // new
- (void)hDownloadButtonPressed; // new
@end

@interface AWEAwemePlayInteractionPresenter : NSObject
@property(retain, nonatomic) AWEAwemeModel *model;
@property(nonatomic) AWEAwemePlayInteractionViewController *viewController; 
@end

@interface AWEMediaDownloadOptions : NSObject
@property(retain, nonatomic) AWEAwemeModel *awemeModel;
@end

@interface AWEDownloadShareChannel : NSObject
@property(retain, nonatomic) AWEMediaDownloadOptions *downloadOptions;
@end

@interface AWEFeedTableViewController : UIViewController
- (void)scrollToNextVideo;
@end
