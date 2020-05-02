#include "TTGRootListController.h"

#define PLIST_PATH "/var/mobile/Library/Preferences/com.haoict.tiktokgodpref.plist"
#define PREF_CHANGED_NOTIF "com.haoict.tiktokgodpref/PrefChanged"

@implementation TTGRootListController
- (id)init {
  self = [super init];
  if (self) {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[HaoPSUtil localizedItem:@"APPLY"] style:UIBarButtonItemStylePlain target:self action:@selector(apply)];;
  }
  return self;
}
- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  // set switches color
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  self.view.tintColor = kTintColor;
  keyWindow.tintColor = kTintColor;
  [UISwitch appearanceWhenContainedInInstancesOfClasses:@[self.class]].onTintColor = kTintColor;
  // set navigation bar color
  self.navigationController.navigationController.navigationBar.barTintColor = kTintColor;
  self.navigationController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
  [self.navigationController.navigationController.navigationBar setShadowImage: [UIImage new]];
}
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.navigationController.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
}
- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
  keyWindow.tintColor = nil;
  self.navigationController.navigationController.navigationBar.barTintColor = nil;
  self.navigationController.navigationController.navigationBar.tintColor = nil;
  [self.navigationController.navigationController.navigationBar setShadowImage:nil];
  [self.navigationController.navigationController.navigationBar setTitleTextAttributes:nil];
}

- (NSArray *)specifiers {
  if (!_specifiers) {
    _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
  }

  return _specifiers;
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
  NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@PLIST_PATH] ?: [@{} mutableCopy];
  [settings setObject:value forKey:[[specifier properties] objectForKey:@"key"]];
  [settings writeToFile:@PLIST_PATH atomically:YES];
  notify_post(PREF_CHANGED_NOTIF);
}
- (id)readPreferenceValue:(PSSpecifier *)specifier {
  NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH];
  return settings[[[specifier properties] objectForKey:@"key"]] ?: [[specifier properties] objectForKey:@"default"];
}
- (void)resetSettings:(PSSpecifier *)specifier  {
  [@{} writeToFile:@PLIST_PATH atomically:YES];
  [self reloadSpecifiers];
  notify_post(PREF_CHANGED_NOTIF);
}
- (void)openURL:(PSSpecifier *)specifier  {
  UIApplication *app = [UIApplication sharedApplication];
  NSString *url = [specifier.properties objectForKey:@"url"];
  [app openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
}

/**
 * Apply top right button
 */
-(void)apply {
  UIAlertController *killConfirm = [UIAlertController alertControllerWithTitle:@TWEAK_TITLE message:[HaoPSUtil localizedItem:@"DO_YOU_REALLY_WANT_TO_KILL_TIKTOK"] preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:[HaoPSUtil localizedItem:@"CONFIRM"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
    NSTask *killall = [[NSTask alloc] init];
    [killall setLaunchPath:@"/usr/bin/killall"];
    [killall setArguments:@[@"-9", @"TikTok"]];
    [killall launch];
  }];

  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[HaoPSUtil localizedItem:@"CANCEL"] style:UIAlertActionStyleCancel handler:nil];
  [killConfirm addAction:confirmAction];
  [killConfirm addAction:cancelAction];
  [self presentViewController:killConfirm animated:YES completion:nil];
}

- (void)respring {
  NSTask *killall = [[NSTask alloc] init];
  [killall setLaunchPath:@"/usr/bin/killall"];
  [killall setArguments:[NSArray arrayWithObjects:@"backboardd", nil]];
  [killall launch];
}

@end
