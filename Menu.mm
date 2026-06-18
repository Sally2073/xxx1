//  Menu.mm
//  ModMenu
#import <Foundation/Foundation.h>
#import "Menu.h"

@interface Menu ()

@property (assign, nonatomic) CGPoint lastMenuLocation;
@property (strong, nonatomic) UILabel *menuTitle;
@property (strong, nonatomic) UIView *header;
@property (strong, nonatomic) UIView *footer;
@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (strong, nonatomic) UISwitch *themeToggle;

@end

@implementation Menu

NSUserDefaults *defaults;
UIScrollView *scrollView;
CGFloat menuWidth;
CGFloat scrollViewX;
NSString *credits;
UIColor *switchOnColor;
NSString *switchTitleFont;
UIColor *switchTitleColor;
UIColor *infoButtonColor;
NSString *menuIconBase64;
NSString *menuButtonBase64;
float scrollViewHeight = 0;
BOOL hasRestoredLastSession = false;
UIButton *menuButton;
BOOL isDarkMode;

const char *frameworkName = NULL;
UIWindow *mainWindow;

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

// Global variables, extern in Macros.h
Menu *menu = [Menu alloc];
Switches *switches = [Switches alloc];

-(id)initWithTitle:(NSString *)title_ titleColor:(UIColor *)titleColor_ titleFont:(NSString *)titleFont_ credits:(NSString *)credits_ headerColor:(UIColor *)headerColor_ switchOffColor:(UIColor *)switchOffColor_ switchOnColor:(UIColor *)switchOnColor_ switchTitleFont:(NSString *)switchTitleFont_ switchTitleColor:(UIColor *)switchTitleColor_ infoButtonColor:(UIColor *)infoButtonColor_ maxVisibleSwitches:(int)maxVisibleSwitches_ menuWidth:(CGFloat)menuWidth_ menuIcon:(NSString *)menuIconBase64_ menuButton:(NSString *)menuButtonBase64_ {
    mainWindow = UIApplication.sharedApplication.windows.firstObject;
    defaults = [NSUserDefaults standardUserDefaults];

    menuWidth = menuWidth_;
    switchOnColor = switchOnColor_;
    credits = credits_;
    switchTitleFont = switchTitleFont_;
    switchTitleColor = switchTitleColor_;
    infoButtonColor = infoButtonColor_;
    menuButtonBase64 = menuButtonBase64_;

    // Load theme preference
    isDarkMode = [defaults boolForKey:@"isDarkMode"];
    if (![defaults objectForKey:@"isDarkMode"]) {
        isDarkMode = YES; // Default to dark mode
        [defaults setBool:YES forKey:@"isDarkMode"];
    }

    // Initialize menu frame
    self = [super initWithFrame:CGRectMake(0, 0, menuWidth_, maxVisibleSwitches_ * 60 + 100)];
    self.center = mainWindow.center;
    self.layer.opacity = 0.0f;

    // Modern styling: rounded corners, shadow
    self.layer.cornerRadius = 24.0;
    self.layer.masksToBounds = NO;
    self.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.25].CGColor;
    self.layer.shadowOpacity = 0.35;
    self.layer.shadowOffset = CGSizeMake(0, 8);
    self.layer.shadowRadius = 14;

    // Enhanced blur effect
    [self updateBlurEffect];
    [self addSubview:self.blurView];

    // Header with modern gradient
    self.header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, menuWidth_, 70)];
    [self updateHeaderGradient];
    [self addSubview:self.header];

    // Menu icon from Base64
    NSData *data = [[NSData alloc] initWithBase64EncodedString:menuIconBase64_ options:0];
    UIImage *menuIconImage = [UIImage imageWithData:data];

    // Circular menu icon button
    UIButton *menuIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    menuIcon.frame = CGRectMake(16, 15, 40, 40);
    menuIcon.layer.cornerRadius = 20;
    menuIcon.clipsToBounds = YES;
    menuIcon.layer.borderColor = [UIColor.whiteColor colorWithAlphaComponent:0.6].CGColor;
    menuIcon.layer.borderWidth = 1.2;
    [menuIcon setImage:menuIconImage forState:UIControlStateNormal];
    [menuIcon setBackgroundColor:[UIColor.whiteColor colorWithAlphaComponent:0.1]];
    menuIcon.showsTouchWhenHighlighted = YES;

    // Smooth scale animation on touch
    [menuIcon addTarget:self action:@selector(menuIconTapped) forControlEvents:UIControlEventTouchDown];
    [UIView animateWithDuration:0.25 animations:^{
        menuIcon.transform = CGAffineTransformMakeScale(0.92, 0.92);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            menuIcon.transform = CGAffineTransformIdentity;
        }];
    }];

    // Subtle shadow for icon
    menuIcon.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.3].CGColor;
    menuIcon.layer.shadowOffset = CGSizeMake(0, 2);
    menuIcon.layer.shadowOpacity = 0.4;
    menuIcon.layer.shadowRadius = 4.0;
    [self.header addSubview:menuIcon];

    // Modernized menu title
    self.menuTitle = [[UILabel alloc] initWithFrame:CGRectMake(64, 15, menuWidth_ - 140, 40)];
    self.menuTitle.text = title_;
    self.menuTitle.textColor = isDarkMode ? titleColor_ : [UIColor.blackColor colorWithAlphaComponent:0.9];
    self.menuTitle.font = [UIFont fontWithName:@"SFProDisplay-Bold" size:22] ?: [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.menuTitle.adjustsFontSizeToFitWidth = YES;
    self.menuTitle.textAlignment = NSTextAlignmentLeft;
    self.menuTitle.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.2].CGColor;
    self.menuTitle.layer.shadowOffset = CGSizeMake(0, 1);
    self.menuTitle.layer.shadowOpacity = 0.5;
    self.menuTitle.layer.shadowRadius = 2.0;
    self.menuTitle.alpha = 0.0;
    [self.header addSubview:self.menuTitle];

    // Title fade-in animation
    [UIView animateWithDuration:0.5 delay:0.2 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.menuTitle.alpha = 1.0;
        self.menuTitle.transform = CGAffineTransformMakeTranslation(0, -5);
    } completion:nil];

    // Theme toggle switch
    self.themeToggle = [[UISwitch alloc] initWithFrame:CGRectMake(menuWidth_ - 60, 20, 50, 30)];
    self.themeToggle.on = isDarkMode;
    [self.themeToggle addTarget:self action:@selector(themeToggled:) forControlEvents:UIControlEventValueChanged];
    self.themeToggle.onTintColor = [UIColor systemIndigoColor];
    [self.header addSubview:self.themeToggle];

    // ScrollView setup
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.header.bounds), menuWidth_, CGRectGetHeight(self.bounds) - CGRectGetHeight(self.header.bounds) - 40)];
    scrollView.backgroundColor = isDarkMode ? [switchOffColor_ colorWithAlphaComponent:0.85] : [UIColor.whiteColor colorWithAlphaComponent:0.9];
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.layer.cornerRadius = 12.0;
    [self addSubview:scrollView];
    scrollViewX = CGRectGetMinX(scrollView.bounds);

    // Footer with gradient and credits
    self.footer = [[UIView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.bounds) - 40, menuWidth_, 40)];
    [self updateFooterGradient];
    [self addSubview:self.footer];

    // Separator line above footer
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, -1, menuWidth_, 1)];
    separator.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.2];
    [self.footer addSubview:separator];

    // Credits label in footer
    UILabel *creditsLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 8, menuWidth_ - 32, 24)];
    creditsLabel.text = credits_.length > 0 ? credits_ : @"ModMenu v2.0";
    creditsLabel.textColor = isDarkMode ? [UIColor.whiteColor colorWithAlphaComponent:0.7] : [UIColor.blackColor colorWithAlphaComponent:0.7];
    creditsLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    creditsLabel.textAlignment = NSTextAlignmentCenter;
    creditsLabel.adjustsFontSizeToFitWidth = YES;
    [self.footer addSubview:creditsLabel];

    // Drag gesture for menu
    UIPanGestureRecognizer *dragMenuRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(menuDragged:)];
    [self.header addGestureRecognizer:dragMenuRecognizer];

    // Tap to hide menu
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideMenu:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.header addGestureRecognizer:tapGestureRecognizer];

    // Add menu to main window
    [mainWindow addSubview:self];

    // Show menu button
    [self showMenuButton];

    return self;
}

- (void)updateBlurEffect {
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:isDarkMode ? UIBlurEffectStyleSystemMaterialDark : UIBlurEffectStyleSystemMaterialLight]];
    self.blurView.frame = self.bounds;
    self.blurView.layer.cornerRadius = 24.0;
    self.blurView.clipsToBounds = YES;
}

- (void)updateHeaderGradient {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.header.bounds;
    gradient.colors = isDarkMode ? @[
        (__bridge id)[UIColor colorWithRed:0.12 green:0.22 blue:0.50 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.22 green:0.40 blue:0.70 alpha:1.0].CGColor
    ] : @[
        (__bridge id)[UIColor colorWithRed:0.95 green:0.95 blue:0.98 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.85 green:0.85 blue:0.90 alpha:1.0].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    [self.header.layer insertSublayer:gradient atIndex:0];

    // Rounded corners for header
    CAShapeLayer *headerMask = [CAShapeLayer layer];
    headerMask.path = [UIBezierPath bezierPathWithRoundedRect:self.header.bounds
                                            byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                  cornerRadii:CGSizeMake(24.0, 24.0)].CGPath;
    self.header.layer.mask = headerMask;
}

- (void)updateFooterGradient {
    CAGradientLayer *footerGradient = [CAGradientLayer layer];
    footerGradient.frame = self.footer.bounds;
    footerGradient.colors = isDarkMode ? @[
        (__bridge id)[UIColor colorWithRed:0.22 green:0.40 blue:0.70 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.12 green:0.22 blue:0.50 alpha:1.0].CGColor
    ] : @[
        (__bridge id)[UIColor colorWithRed:0.85 green:0.85 blue:0.90 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.95 green:0.95 blue:0.98 alpha:1.0].CGColor
    ];
    footerGradient.startPoint = CGPointMake(0, 0);
    footerGradient.endPoint = CGPointMake(1, 1);
    [self.footer.layer insertSublayer:footerGradient atIndex:0];

    // Rounded corners for footer
    CAShapeLayer *footerLayer = [CAShapeLayer layer];
    footerLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.footer.bounds
                                             byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight
                                                   cornerRadii:CGSizeMake(24.0, 24.0)].CGPath;
    self.footer.layer.mask = footerLayer;
}

- (void)themeToggled:(UISwitch *)sender {
    isDarkMode = sender.on;
    [defaults setBool:isDarkMode forKey:@"isDarkMode"];

    // Update blur effect
    [self.blurView removeFromSuperview];
    [self updateBlurEffect];
    [self insertSubview:self.blurView atIndex:0];

    // Update header and footer gradients
    [self.header.layer.sublayers[0] removeFromSuperlayer];
    [self updateHeaderGradient];
    [self.footer.layer.sublayers[0] removeFromSuperlayer];
    [self updateFooterGradient];

    // Update text colors
    self.menuTitle.textColor = isDarkMode ? switchTitleColor : [UIColor.blackColor colorWithAlphaComponent:0.9];
    for (UIView *subview in self.footer.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            ((UILabel *)subview).textColor = isDarkMode ? [UIColor.whiteColor colorWithAlphaComponent:0.7] : [UIColor.blackColor colorWithAlphaComponent:0.7];
        }
    }

    // Update scroll view and switch backgrounds
    scrollView.backgroundColor = isDarkMode ? [UIColor.blackColor colorWithAlphaComponent:0.85] : [UIColor.whiteColor colorWithAlphaComponent:0.9];
    for (id switch_ in scrollView.subviews) {
        if ([switch_ isKindOfClass:[OffsetSwitch class]] || [switch_ isKindOfClass:[TextFieldSwitch class]] || [switch_ isKindOfClass:[SliderSwitch class]]) {
            BOOL isOn = [defaults boolForKey:[switch_ getPreferencesKey]];
            ((UIView *)switch_).backgroundColor = isOn ? switchOnColor : [UIColor.clearColor colorWithAlphaComponent:0.85];
        }
    }

    // Animate the transition
    [UIView animateWithDuration:0.3 animations:^{
        self.layer.opacity = 1.0f;
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.lastMenuLocation = CGPointMake(CGRectGetMinX(self.frame), CGRectGetMinY(self.frame));
    [super touchesBegan:touches withEvent:event];
}

- (void)menuDragged:(UIPanGestureRecognizer *)pan {
    CGPoint newLocation = [pan translationInView:self.superview];
    self.frame = CGRectMake(self.lastMenuLocation.x + newLocation.x, self.lastMenuLocation.y + newLocation.y, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
}

- (void)hideMenu:(UITapGestureRecognizer *)tap {
    if (tap.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.alpha = 0.0f;
            menuButton.alpha = 1.0f;
        } completion:^(BOOL finished) {
            // Subtle scale animation for button
            [UIView animateWithDuration:0.3 animations:^{
                menuButton.transform = CGAffineTransformMakeScale(1.1, 1.1);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3 animations:^{
                    menuButton.transform = CGAffineTransformIdentity;
                }];
            }];

            // Move button to edge after delay
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.4 animations:^{
                    menuButton.frame = CGRectMake(10, menuButton.frame.origin.y, menuButton.frame.size.width, menuButton.frame.size.height);
                    menuButton.transform = CGAffineTransformMakeScale(0.9, 0.9);
                    menuButton.layer.cornerRadius = 20.0f;
                    menuButton.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.25].CGColor;
                    menuButton.layer.shadowOffset = CGSizeMake(0, 2);
                    menuButton.layer.shadowOpacity = 0.4;
                    menuButton.layer.shadowRadius = 4.0;
                }];
            });
        }];
    }
}

-(void)showMenu:(UITapGestureRecognizer *)tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [menuButton.layer removeAllAnimations];
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.alpha = 1.0f;
            menuButton.alpha = 0.0f;
        } completion:nil];
    }
    if (!hasRestoredLastSession) {
        restoreLastSession();
        hasRestoredLastSession = true;
    }
}

void restoreLastSession() {
    UIColor *clearColor = [UIColor clearColor];
    BOOL isOn = false;

    for (id switch_ in scrollView.subviews) {
        if ([switch_ isKindOfClass:[OffsetSwitch class]]) {
            isOn = [defaults boolForKey:[switch_ getPreferencesKey]];
            std::vector<MemoryPatch> memoryPatches = [switch_ getMemoryPatches];
            for (int i = 0; i < memoryPatches.size(); i++) {
                if (isOn) {
                    memoryPatches[i].Modify();
                } else {
                    memoryPatches[i].Restore();
                }
            }
            ((OffsetSwitch*)switch_).backgroundColor = isOn ? switchOnColor : clearColor;
        }
        if ([switch_ isKindOfClass:[TextFieldSwitch class]]) {
            isOn = [defaults boolForKey:[switch_ getPreferencesKey]];
            ((TextFieldSwitch*)switch_).backgroundColor = isOn ? switchOnColor : clearColor;
        }
        if ([switch_ isKindOfClass:[SliderSwitch class]]) {
            isOn = [defaults boolForKey:[switch_ getPreferencesKey]];
            ((SliderSwitch*)switch_).backgroundColor = isOn ? switchOnColor : clearColor;
        }
    }
}

-(void)showMenuButton {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:menuButtonBase64 options:0];
    UIImage *menuButtonImage = [UIImage imageWithData:data];

    menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
    menuButton.frame = CGRectMake((mainWindow.frame.size.width - 60) / 2, (mainWindow.frame.size.height - 60) / 2, 60, 60);
    menuButton.backgroundColor = isDarkMode ? [UIColor.clearColor colorWithAlphaComponent:0.7] : [UIColor.whiteColor colorWithAlphaComponent:0.7];
    menuButton.layer.cornerRadius = 30;
    menuButton.clipsToBounds = YES;
    [menuButton setBackgroundImage:menuButtonImage forState:UIControlStateNormal];
    menuButton.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.25].CGColor;
    menuButton.layer.shadowOffset = CGSizeMake(0, 3);
    menuButton.layer.shadowOpacity = 0.4;
    menuButton.layer.shadowRadius = 5.0;

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
    [menuButton addGestureRecognizer:tapGestureRecognizer];
    [menuButton addTarget:self action:@selector(buttonDragged:withEvent:) forControlEvents:UIControlEventTouchDragInside];
    [mainWindow addSubview:menuButton];
}

- (void)buttonDragged:(UIButton *)button withEvent:(UIEvent *)event {
    UITouch *touch = [[event touchesForView:button] anyObject];
    CGPoint previousLocation = [touch previousLocationInView:button];
    CGPoint location = [touch locationInView:button];
    CGFloat delta_x = location.x - previousLocation.x;
    CGFloat delta_y = location.y - previousLocation.y;
    button.center = CGPointMake(button.center.x + delta_x, button.center.y + delta_y);
}

-(void)menuIconTapped {
    [self showPopup:self.menuTitle.text description:credits];
    self.layer.opacity = 0.0f;
}

-(void)showPopup:(NSString *)title_ description:(NSString *)description_ {
    SCLAlertView *alert = [[SCLAlertView alloc] initWithNewWindow];
    alert.shouldDismissOnTapOutside = YES;
    alert.customViewColor = isDarkMode ? [UIColor systemIndigoColor] : [UIColor systemBlueColor];
    alert.showAnimationType = SCLAlertViewShowAnimationSlideInFromTop;
    [alert addButton:@"OK" actionBlock:^{
        [UIView animateWithDuration:0.3 animations:^{
            self.layer.opacity = 1.0f;
        }];
    }];
    [alert showInfo:title_ subTitle:description_ closeButtonTitle:nil duration:0.0f];
}

- (void)addSwitchToMenu:(id)switch_ {
    [switch_ addTarget:self action:@selector(switchClicked:) forControlEvents:UIControlEventTouchDown];
    scrollViewHeight += 60;
    scrollView.contentSize = CGSizeMake(menuWidth, scrollViewHeight);
    [scrollView addSubview:switch_];
    // Update switch background based on theme
    BOOL isOn = [defaults boolForKey:[switch_ getPreferencesKey]];
    ((UIView *)switch_).backgroundColor = isOn ? switchOnColor : [UIColor.clearColor colorWithAlphaComponent:0.85];
}

- (void)changeSwitchBackground:(id)switch_ isSwitchOn:(BOOL)isSwitchOn_ {
    UIColor *clearColor = [UIColor clearColor];
    [UIView animateWithDuration:0.3 animations:^{
        if ([switch_ isKindOfClass:[TextFieldSwitch class]]) {
            ((TextFieldSwitch*)switch_).backgroundColor = isSwitchOn_ ? clearColor : switchOnColor;
        }
        if ([switch_ isKindOfClass:[SliderSwitch class]]) {
            ((SliderSwitch*)switch_).backgroundColor = isSwitchOn_ ? clearColor : switchOnColor;
        }
        if ([switch_ isKindOfClass:[OffsetSwitch class]]) {
            ((OffsetSwitch*)switch_).backgroundColor = isSwitchOn_ ? clearColor : switchOnColor;
        }
    }];
    [defaults setBool:!isSwitchOn_ forKey:[switch_ getPreferencesKey]];
}

-(void)switchClicked:(id)switch_ {
    BOOL isOn = [defaults boolForKey:[switch_ getPreferencesKey]];
    if ([switch_ isKindOfClass:[OffsetSwitch class]]) {
        std::vector<MemoryPatch> memoryPatches = [switch_ getMemoryPatches];
        for (int i = 0; i < memoryPatches.size(); i++) {
            if (!isOn) {
                memoryPatches[i].Modify();
            } else {
                memoryPatches[i].Restore();
            }
        }
    }
    [self changeSwitchBackground:switch_ isSwitchOn:isOn];
}

-(void)setFrameworkName:(const char *)name_ {
    frameworkName = name_;
}

-(const char *)getFrameworkName {
    return frameworkName;
}

@end

@implementation OffsetSwitch {
    std::vector<MemoryPatch> memoryPatches;
}

- (id)initHackNamed:(NSString *)hackName_ description:(NSString *)description_ offsets:(std::vector<uint64_t>)offsets_ bytes:(std::vector<std::string>)bytes_ {
    description = description_;
    preferencesKey = hackName_;

    if (offsets_.size() != bytes_.size()) {
        [menu showPopup:@"Invalid input count" description:[NSString stringWithFormat:@"Offsets array input count (%d) is not equal to the bytes array input count (%d)", (int)offsets_.size(), (int)bytes_.size()]];
    } else {
        for (int i = 0; i < offsets_.size(); i++) {
            MemoryPatch patch = MemoryPatch::createWithHex([menu getFrameworkName], offsets_[i], bytes_[i]);
            if (patch.isValid()) {
                memoryPatches.push_back(patch);
            } else {
                [menu showPopup:@"Invalid patch" description:[NSString stringWithFormat:@"Failing offset: 0x%llx, please re-check the hex you entered.", offsets_[i]]];
            }
        }
    }

    self = [super initWithFrame:CGRectMake(0, scrollViewX + scrollViewHeight, menuWidth, 60)];
    self.backgroundColor = [defaults boolForKey:@"isDarkMode"] ? [UIColor.clearColor colorWithAlphaComponent:0.85] : [UIColor.whiteColor colorWithAlphaComponent:0.85];
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [UIColor.whiteColor colorWithAlphaComponent:0.15].CGColor;
    self.layer.cornerRadius = 10.0;

    switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, menuWidth - 80, 40)];
    switchLabel.text = hackName_;
    switchLabel.textColor = switchTitleColor;
    switchLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    switchLabel.adjustsFontSizeToFitWidth = YES;
    switchLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:switchLabel];

    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    infoButton.frame = CGRectMake(menuWidth - 40, 20, 30, 30);
    infoButton.tintColor = infoButtonColor;
    [infoButton addTarget:self action:@selector(showInfo:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:infoButton];

    return self;
}

-(void)showInfo:(id)sender {
    [menu showPopup:[self getPreferencesKey] description:[self getDescription]];
    menu.layer.opacity = 0.0f;
}

-(NSString *)getPreferencesKey {
    return preferencesKey;
}

-(NSString *)getDescription {
    return description;
}

- (std::vector<MemoryPatch>)getMemoryPatches {
    return memoryPatches;
}

@end

@implementation TextFieldSwitch {
    UITextField *textfieldValue;
}

- (id)initTextfieldNamed:(NSString *)hackName_ description:(NSString *)description_ inputBorderColor:(UIColor *)inputBorderColor_ {
    preferencesKey = hackName_;
    switchValueKey = [hackName_ stringByApplyingTransform:NSStringTransformLatinToCyrillic reverse:false];
    description = description_;

    self = [super initWithFrame:CGRectMake(0, scrollViewX + scrollViewHeight, menuWidth, 60)];
    self.backgroundColor = [defaults boolForKey:@"isDarkMode"] ? [UIColor.clearColor colorWithAlphaComponent:0.85] : [UIColor.whiteColor colorWithAlphaComponent:0.85];
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [UIColor.whiteColor colorWithAlphaComponent:0.15].CGColor;
    self.layer.cornerRadius = 10.0;

    switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, menuWidth - 80, 30)];
    switchLabel.text = hackName_;
    switchLabel.textColor = switchTitleColor;
    switchLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    switchLabel.adjustsFontSizeToFitWidth = YES;
    switchLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:switchLabel];

    textfieldValue = [[UITextField alloc] initWithFrame:CGRectMake(20, 35, menuWidth - 80, 20)];
    textfieldValue.layer.borderWidth = 1.2f;
    textfieldValue.layer.borderColor = [inputBorderColor_ colorWithAlphaComponent:0.7].CGColor;
    textfieldValue.layer.cornerRadius = 8.0;
    textfieldValue.textColor = switchTitleColor;
    textfieldValue.textAlignment = NSTextAlignmentCenter;
    textfieldValue.delegate = self;
    textfieldValue.backgroundColor = [defaults boolForKey:@"isDarkMode"] ? [UIColor.whiteColor colorWithAlphaComponent:0.08] : [UIColor.blackColor colorWithAlphaComponent:0.08];
    textfieldValue.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter value" attributes:@{NSForegroundColorAttributeName: [switchTitleColor colorWithAlphaComponent:0.4]}];

    if ([defaults objectForKey:switchValueKey] != nil) {
        textfieldValue.text = [defaults objectForKey:switchValueKey];
    }

    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    infoButton.frame = CGRectMake(menuWidth - 40, 15, 30, 30);
    infoButton.tintColor = infoButtonColor;
    [infoButton addTarget:self action:@selector(showInfo:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:infoButton];
    [self addSubview:textfieldValue];

    return self;
}

-(BOOL)textFieldShouldReturn:(UITextField*)textfieldValue_ {
    switchValueKey = [[self getPreferencesKey] stringByApplyingTransform:NSStringTransformLatinToCyrillic reverse:false];
    [defaults setObject:textfieldValue_.text forKey:[self getSwitchValueKey]];
    [textfieldValue_ resignFirstResponder];
    return YES;
}

-(NSString *)getSwitchValueKey {
    return switchValueKey;
}

@end

@implementation SliderSwitch {
    UISlider *sliderValue;
    float valueOfSlider;
}

- (id)initSliderNamed:(NSString *)hackName_ description:(NSString *)description_ minimumValue:(float)minimumValue_ maximumValue:(float)maximumValue_ sliderColor:(UIColor *)sliderColor_ {
    preferencesKey = hackName_;
    switchValueKey = [hackName_ stringByApplyingTransform:NSStringTransformLatinToCyrillic reverse:false];
    description = description_;

    self = [super initWithFrame:CGRectMake(0, scrollViewX + scrollViewHeight, menuWidth, 60)];
    self.backgroundColor = [defaults boolForKey:@"isDarkMode"] ? [UIColor.clearColor colorWithAlphaComponent:0.85] : [UIColor.whiteColor colorWithAlphaComponent:0.85];
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [UIColor.whiteColor colorWithAlphaComponent:0.15].CGColor;
    self.layer.cornerRadius = 10.0;

    switchLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 5, menuWidth - 80, 30)];
    switchLabel.text = [NSString stringWithFormat:@"%@ %.2f", hackName_, valueOfSlider];
    switchLabel.textColor = switchTitleColor;
    switchLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    switchLabel.adjustsFontSizeToFitWidth = YES;
    switchLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:switchLabel];

    sliderValue = [[UISlider alloc] initWithFrame:CGRectMake(20, 35, menuWidth - 80, 20)];
    sliderValue.thumbTintColor = sliderColor_;
    sliderValue.minimumTrackTintColor = [sliderColor_ colorWithAlphaComponent:0.7];
    sliderValue.maximumTrackTintColor = [sliderColor_ colorWithAlphaComponent:0.2];
    sliderValue.minimumValue = minimumValue_;
    sliderValue.maximumValue = maximumValue_;
    sliderValue.continuous = YES;
    [sliderValue addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    valueOfSlider = sliderValue.value;

    if ([defaults floatForKey:switchValueKey]) {
        sliderValue.value = [defaults floatForKey:switchValueKey];
        switchLabel.text = [NSString stringWithFormat:@"%@ %.2f", hackName_, sliderValue.value];
    }

    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    infoButton.frame = CGRectMake(menuWidth - 40, 15, 30, 30);
    infoButton.tintColor = infoButtonColor;
    [infoButton addTarget:self action:@selector(showInfo:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:infoButton];
    [self addSubview:sliderValue];

    return self;
}

-(void)sliderValueChanged:(UISlider *)slider_ {
    switchValueKey = [[self getPreferencesKey] stringByApplyingTransform:NSStringTransformLatinToCyrillic reverse:false];
    switchLabel.text = [NSString stringWithFormat:@"%@ %.2f", [self getPreferencesKey], slider_.value];
    [defaults setFloat:slider_.value forKey:[self getSwitchValueKey]];
}

@end

@implementation Switches

-(void)addSwitch:(NSString *)hackName_ description:(NSString *)description_ {
    OffsetSwitch *offsetPatch = [[OffsetSwitch alloc] initHackNamed:hackName_ description:description_ offsets:std::vector<uint64_t>{} bytes:std::vector<std::string>{}];
    [menu addSwitchToMenu:offsetPatch];
}

- (void)addOffsetSwitch:(NSString *)hackName_ description:(NSString *)description_ offsets:(std::initializer_list<uint64_t>)offsets_ bytes:(std::initializer_list<std::string>)bytes_ {
    std::vector<uint64_t> offsetVector(offsets_);
    std::vector<std::string> bytesVector(bytes_);
    OffsetSwitch *offsetPatch = [[OffsetSwitch alloc] initHackNamed:hackName_ description:description_ offsets:offsetVector bytes:bytesVector];
    [menu addSwitchToMenu:offsetPatch];
}

- (void)addTextfieldSwitch:(NSString *)hackName_ description:(NSString *)description_ inputBorderColor:(UIColor *)inputBorderColor_ {
    TextFieldSwitch *textfieldSwitch = [[TextFieldSwitch alloc] initTextfieldNamed:hackName_ description:description_ inputBorderColor:inputBorderColor_];
    [menu addSwitchToMenu:textfieldSwitch];
}

- (void)addSliderSwitch:(NSString *)hackName_ description:(NSString *)description_ minimumValue:(float)minimumValue_ maximumValue:(float)maximumValue_ sliderColor:(UIColor *)sliderColor_ {
    SliderSwitch *sliderSwitch = [[SliderSwitch alloc] initSliderNamed:hackName_ description:description_ minimumValue:minimumValue_ maximumValue:maximumValue_ sliderColor:sliderColor_];
    [menu addSwitchToMenu:sliderSwitch];
}

- (NSString *)getValueFromSwitch:(NSString *)name {
    NSString *correctKey = [name stringByApplyingTransform:NSStringTransformLatinToCyrillic reverse:false];
    if ([defaults objectForKey:correctKey]) {
        return [defaults objectForKey:correctKey];
    } else if ([defaults floatForKey:correctKey]) {
        return [NSString stringWithFormat:@"%f", [defaults floatForKey:correctKey]];
    }
    return nil;
}

-(bool)isSwitchOn:(NSString *)switchName {
    return [defaults boolForKey:switchName];
}

@end