#import "HaoPSSwitchCellCustom.h"

@implementation HaoPSSwitchCellCustom
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
  self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];
  if (self) {
    self.textLabel.textColor = [HaoPSUtil colorFromHex:@"#333333"];

    NSString *subTitleValue = [specifier.properties objectForKey:@"subtitle"];
    self.detailTextLabel.text = [HaoPSUtil localizedItem:subTitleValue];
    self.detailTextLabel.textColor = [HaoPSUtil colorFromHex:@"#828282"];
  }
  return self;
}

- (void)setSeparatorStyle:(UITableViewCellSeparatorStyle)style {
  [super setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}
@end
