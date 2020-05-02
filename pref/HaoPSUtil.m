#import "HaoPSUtil.h"

@implementation HaoPSUtil
+ (NSString *)localizedItem:(NSString *)key {
  NSBundle *tweakBundle = [NSBundle bundleWithPath:@PREF_BUNDLE_PATH];
  return [tweakBundle localizedStringForKey:key value:@"" table:@"Root"] ?: @"";
}

+ (UIColor *)colorFromHex:(NSString *)hexString {
  unsigned rgbValue = 0;
  if ([hexString hasPrefix:@"#"]) hexString = [hexString substringFromIndex:1];
  if (hexString) {
  NSScanner *scanner = [NSScanner scannerWithString:hexString];
  [scanner setScanLocation:0]; // bypass '#' character
  [scanner scanHexInt:&rgbValue];
  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
  }
  else return [UIColor grayColor];
}
@end