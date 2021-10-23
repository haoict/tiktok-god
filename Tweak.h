#include <dlfcn.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <libhdev/HUtilities/HDownloadMediaWithProgress.h>
#import "TTGSettings.h"

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

@interface AWEFeedCellViewController : UIViewController
@end

@interface AWEPlayVideoPlayerController : NSObject
@property(nonatomic) AWEFeedCellViewController *container;
- (void)setPlayerSeekTime:(double)arg1 completion:(id)arg2;
@end

@interface AWEAwemePlayVideoPlayerController : NSObject
@property(nonatomic) AWEFeedCellViewController *container;
- (void)setPlayerSeekTime:(double)arg1 completion:(id)arg2;
@end

@interface AWEFeedContainerViewController : UIViewController
@property(retain, nonatomic) UIView *tabControl;
@property(retain, nonatomic) UIView *specialEventEntranceView;
@property(nonatomic) BOOL isUIHidden; // new property
- (void)setAccessoriesHidden:(BOOL)arg1;
+ (AWEFeedContainerViewController *)sharedInstance; // new
@end

@interface AWEPlayInteractionBaseElement : NSObject
@end

@interface AWEPlayInteractionElementContainer : NSObject
@property (readonly) NSArray<__kindof AWEPlayInteractionBaseElement *> *elementArray;
@property (readonly) UIStackView *containerView;
@end

@interface AWEPlayInteractionViewController : UIViewController
@property AWEAwemeModel *model;
@property UIStackView *ttgButtonStack; // new property
@property UIButton *hideUIButton; // new property
@property UIButton *downloadButton; // new property

@property (readonly) AWEPlayInteractionElementContainer *rightContainer;

- (void)setHide:(BOOL)arg1;
- (void)updateShowOrHideUI; // new
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
