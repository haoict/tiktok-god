#import "HaoPSHeaderImageCellCustom.h"

@implementation HaoPSHeaderImageCellCustom {
  UIView *headerImageViewContainer;
  UIImageView *headerImageView;
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
  self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
  if (self) {
    [self prepareHeaderImage:specifier];
    [self applyHeaderImage];
  }
  return self;
}

- (void)prepareHeaderImage:(PSSpecifier *)specifier {
  int kWidth = [[UIApplication sharedApplication] keyWindow].frame.size.width;
  if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ) {
    kWidth = kWidth / 2;
  }
  headerImageViewContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWidth, 200.0)];
  if(specifier.properties[@"image"]) {
    headerImageView = [[UIImageView alloc] initWithImage:[[UIImage alloc] initWithContentsOfFile:specifier.properties[@"image"]]];
    headerImageView.frame = CGRectMake(0, 0, kWidth, 200.0);
    headerImageView.contentMode = UIViewContentModeScaleAspectFill;
    [headerImageViewContainer addSubview:headerImageView];
  }
}

- (void)applyHeaderImage {
  [self addSubview:headerImageViewContainer];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
  CGFloat prefHeight = 200.0;
  return prefHeight;
}
@end
