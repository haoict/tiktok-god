#include "TTGRootListController.h"

#define TWEAK_TITLE "TikTok God"
#define TINT_COLOR "#000000"
#define BUNDLE_NAME "TTGPref"

@implementation TTGRootListController
- (id)init {
  self = [super init];
  if (self) {
    self.tintColorHex = @TINT_COLOR;
    self.bundlePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle", @BUNDLE_NAME];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[self localizedItem:@"APPLY"] style:UIBarButtonItemStylePlain target:self action:@selector(apply)];;
  }
  return self;
}

- (void)apply {
  [HCommon killProcess:@"TikTok" viewController:self alertTitle:@TWEAK_TITLE message:[self localizedItem:@"DO_YOU_REALLY_WANT_TO_KILL_TIKTOK"] confirmActionLabel:[self localizedItem:@"CONFIRM"] cancelActionLabel:[self localizedItem:@"CANCEL"]];
}

@end
