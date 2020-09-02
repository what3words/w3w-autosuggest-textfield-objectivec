//
//  W3wTextField.m
//
//
//  Created by Lshiva on 28/06/2019.
//

#import "W3wTextField.h"
#import "W3wGeocoder.h"
#import <CoreLocation/CoreLocation.h>

static NSString *CellIdentifier = @"CellIdentifier";
static int rows = 16;
static int const cols = 16;
static int const width = 64;
static int const height = 48;
static int const margin = 15.0f;

struct Coordinates {
    double latitude;
    double longitude;
};


@implementation UIColor (UIColor_Constants)
+(UIColor *) W3wTextColor {
    return [UIColor colorWithRed:0.04f green:0.19f blue:0.29f alpha:1.0f];
}

+(UIColor *) w3wLocationColor {
    return [UIColor colorWithRed:0.64f green:0.64f blue:0.64f alpha:1.0f];
}

+(UIColor *) w3wLogoColor {
    return [UIColor colorWithRed:0.88f green:0.12f blue:0.15f alpha:1.0f];
}

@end


@interface W3wTextField () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate> {
    CGPoint      pointToParent;
    CGFloat      listHeight;
    CGFloat      tableHeightX;
    NSArray     *countries;
    NSString    *cellIdentifier;
    int          rowHeight;
    int          selectedIndex;
    NSString    *selectedW3wText;
    
    
}

@property (strong, nonatomic) UITableView *table; // DropDown Table
@property (nonatomic, strong) UIView *backgroundView; // Set background view
@property (nonatomic, strong) UIViewController* parentController; // parent view controller
@property (nonatomic, strong) UIViewController* parentViewController; // parent view controller
@property (nonatomic, strong) W3wGeocoder *instance; //what3words geocoder
@property (nonatomic, strong) NSMutableArray *dataArray; // W3w Suggestion array
@property (nonatomic, strong) UIView *checkMarkView; // W3w Suggestion array
@property (nonatomic, copy) didSelectCompletion completionBlock;
@property (nonatomic, strong) NSMutableArray   *autoSuggestionOptions;
@property (nonatomic) BOOL    isDebugMode;
@property(strong) dispatch_source_t debounceTimer;

@end

@implementation W3wTextField

@synthesize isSearchEnable;

- (void)drawRect:(CGRect)rect
{
    //[self setupUI];
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaultIBProperties];
        [self setupUI];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setDefaultIBProperties];
        [self setupUI];
        
    }
    return self;
}

-(void)setAPIKey:(NSString *)apiKey {
  
  NSDictionary *customHeaders = @{
    @"X-W3W-AS-Component" : [NSString stringWithFormat:@"%@ %@", @"what3words-ObjC/1.2.0 ", [self figureOutVersions]]
  };
  
  _instance = [[W3wGeocoder alloc] initWithApiKey:apiKey customHeaders: customHeaders];
}



// Establish the various version numbers in order to set an HTTP header for the URL session
-(NSString *)figureOutVersions
{
#if TARGET_OS_IPHONE
  NSString *os_name = [[UIDevice currentDevice] systemName];
#else
  NSString *os_name = @"Mac";
#endif
  
  NSOperatingSystemVersion os_version   = [[NSProcessInfo processInfo] operatingSystemVersion];
  int                      objc_version = OBJC_API_VERSION;
  //NSString                 *api_version = [NSBundle bundleForClass:[W3wGeocoder class]].infoDictionary[@"CFBundleShortVersionString"];
  NSBundle *bundle = [NSBundle bundleForClass:[W3wGeocoder class]];
  NSDictionary *dictionary = bundle.infoDictionary;
  
  return [NSString stringWithFormat:@"(ObjC %d; %@; %ld.%ld.%ld)",
    objc_version,
    os_name,
    (long)os_version.majorVersion,
    (long)os_version.minorVersion,
    (long)os_version.patchVersion
    ];
}


- (void)setDefaultIBProperties {
    self.autoSuggestionOptions = [[NSMutableArray alloc]init];
    // W3wSuggestionField custom UI properties
    self.fieldCornerRadius = 0.0;
    self.fieldBorderColor = [UIColor clearColor];
    self.fieldBorderWidth = 0.5;
    // W3wSuggestionField custom autosuggest properties
    self.listHeigh = 350;
    self.isDebugMode = true;
}

- (void)setFieldBorderColor:(UIColor *)fieldBorderColor {
    if (fieldBorderColor != _fieldBorderColor) {
        _fieldBorderColor = fieldBorderColor;
        self.layer.borderColor = self.fieldBorderColor.CGColor;
    }
}

- (void)setFieldCornerRadius:(CGFloat)fieldCornerRadius {
    if (fieldCornerRadius != _fieldCornerRadius) {
        _fieldCornerRadius = fieldCornerRadius;
        self.layer.cornerRadius = self.fieldCornerRadius;
    }
}

- (void)setFieldBorderWidth:(CGFloat)fieldBorderWidth {
    if (fieldBorderWidth != _fieldBorderWidth) {
        _fieldBorderWidth = fieldBorderWidth;
        self.layer.borderWidth = self.fieldBorderWidth;
    }
}

// set number of results to return
- (void)setNResults:(int)nResults {
    if (nResults != _nResults) {
        _nResults = nResults;
        AutoSuggestOption *nresults = [[AutoSuggestOption alloc]initAsNumberResults:self.nResults];
        [self.autoSuggestionOptions addObject:nresults];
    }
}

// comma separated lat/lng of point to focus on
- (void)setAutoFocus:(NSString*)autoFocus {
    if (autoFocus != _autoFocus) {
        _autoFocus = autoFocus;
        Coordinates *coordina = [[Coordinates alloc] initWithCoordinates:self.autoFocus];
        AutoSuggestOption *focus = [[AutoSuggestOption alloc]initAsFocus:CLLocationCoordinate2DMake(coordina.latitude, coordina.longitude)];
        [self.autoSuggestionOptions addObject:focus];
    }
}

// set the number of results within what is returned to apply the focus to
- (void)setnFocusResults:(int)nFocusResults {
    if (nFocusResults != _nFocusResults) {
        _nFocusResults = nFocusResults;
        AutoSuggestOption *nfocusresults = [[AutoSuggestOption alloc]initAsNumberFocusResults:self.nFocusResults];
        [self.autoSuggestionOptions addObject:nfocusresults];
    }
}

// confine results to a given country or comma separated list of countries
- (void)setClipToCountry:(NSString *)clipToCountry {
    if (clipToCountry != _clipToCountry) {
        _clipToCountry = clipToCountry;
        AutoSuggestOption *clip = [[AutoSuggestOption alloc]initAsClipToCountry:self.clipToCountry];
        [self.autoSuggestionOptions addObject:clip];
    }
}

// Parse comma seperated polygon
- (void)setClipToPolygon:(NSString *)clipToPolygon {
    if (clipToPolygon != _clipToPolygon) {
        _clipToPolygon = clipToPolygon;
        Clip *coordinates = [[Clip alloc]initWithPolygon:clipToPolygon];
        AutoSuggestOption *clipFocus = [[AutoSuggestOption alloc]initAsClipToPolygon:coordinates.polygonCoordinates];
        [self.autoSuggestionOptions addObject:clipFocus];
    }
}

// Parse comma seperated boundingbox
- (void)setClipToBoundingBox:(NSString *)clipToBoundingBox {
    if (clipToBoundingBox != _clipToBoundingBox) {
        _clipToBoundingBox = clipToBoundingBox;
        Clip *coordinates = [[Clip alloc]initWithBoundingBox:clipToBoundingBox];
        CLLocation *sw = coordinates.coordinates.firstObject;
        CLLocation *ne = coordinates.coordinates.lastObject;
        AutoSuggestOption *clip = [[AutoSuggestOption alloc]initAsBoundingBox:sw.coordinate.latitude west_lng:sw.coordinate.longitude north_lat:ne.coordinate.latitude east_lng:ne.coordinate.longitude];
        [self.autoSuggestionOptions addObject:clip];
    }
}

// Parse comma seperated Circle
- (void)setClipToCircle:(NSString *)clipToCircle {
    if (clipToCircle != _clipToCircle) {
        _clipToCircle = clipToCircle;
        Clip *coords = [[Clip alloc]initWithCircle:clipToCircle];
        CLLocation *circleLocation = coords.circleCoordinates;
        
        AutoSuggestOption *clip = [[AutoSuggestOption alloc]initAsClipToCircle:CLLocationCoordinate2DMake(circleLocation.coordinate.latitude, circleLocation.coordinate.longitude) radius:coords.kiloMeters];
        [self.autoSuggestionOptions addObject:clip];
    }
}

// set debug mode
- (void)setDebug:(bool)debug {
    if (debug != _debug) {
        _debug = debug;
        self.isDebugMode = self.debug;
    }
}

-(void)setupUI {
    //
    //initial value poin to parent
    listHeight = 350.0;
    tableHeightX = 350.0;
    cellIdentifier  = @"DropDownCell";
    selectedIndex = 0;
    rowHeight = 72;
    
    [self setupCountries];
    
    self.backgroundView = [[UIView alloc] init];
    self.backgroundView.backgroundColor = UIColor .clearColor;
    
    self.delegate = self;
    isSearchEnable = true;
    self.dataArray = [NSMutableArray array]; // initialise
    
    /*textfield*/
    self.placeholder = @"e.g. lock.spout.radar";
    self.borderStyle = UITextBorderStyleNone;
    self.layer.masksToBounds = false;
    self.layer.backgroundColor = UIColor .whiteColor.CGColor;
    self.layer.shadowColor = UIColor .blackColor.CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 0);
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowRadius = 2.0;
    self.layer.sublayerTransform = CATransform3DMakeTranslation(15.0, 0.0, 0.0);
    self.keyboardType = UIKeyboardTypeEmailAddress;
    self.font = [UIFont systemFontOfSize:20.0f];
    self.textColor = [UIColor W3wTextColor];
    /* set up the text handler */
    self.leftView = [self texthandler];
    self.leftViewMode = UITextFieldViewModeAlways;
    /* se up checkmark view */
    UIImageView *rightViewImage = [[UIImageView alloc]initWithFrame:CGRectMake(-10, 0, 23, 23)];
    NSBundle *bundle = [NSBundle bundleForClass:[W3wTextField class]];
    UIImage *rightImage = [UIImage imageNamed:@"checkmark" inBundle:bundle compatibleWithTraitCollection:nil];
    rightViewImage.image = rightImage;
    self.checkMarkView = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height /2, 30, 30)];
    [self.checkMarkView addSubview:rightViewImage];
    [self.checkMarkView setHidden:YES];
    self.rightView = self.checkMarkView;
    self.rightViewMode = UITextFieldViewModeAlways;
    //TODO: set up keyboard height
}

-(UIView *)checkMarkIconView {
    return  _checkMarkView;
}

- (UILabel *)texthandler {
    UILabel * textHandler = [[UILabel alloc]initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y, 23, self.frame.size.height)];
    textHandler.text = @"///";
    textHandler.textColor = [UIColor w3wLogoColor];
    textHandler.contentMode = UIViewContentModeScaleAspectFit;
    textHandler.font = [UIFont fontWithName:textHandler.font.fontName size:23];
    return textHandler;
}

- (UIViewController *)viewController {
    UIResponder *responder = self;
    while (![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
        if (nil == responder) {
            break;
        }
    }
    return (UIViewController *)responder;
}

- (void)setNeedsLayout {
    [super setNeedsLayout];
    [self setNeedsDisplay];
}


- (void) touchAction {
    self.isSelected ? [self hideList] : [self showList];
}

// convert CGPoint from superview to target view
- (CGPoint)getConvertedPoint:(UIView *)targetView baseView:(UIView*)baseView {
    CGPoint pnt = targetView.frame.origin;
    
    if ([targetView.superview isEqual:nil]) {
            return pnt;
    }
    
    UIView* superView = targetView.superview;
    while (superView != baseView) {
        pnt = [superView convertPoint:pnt toView:superView.superview];
        if (superView.superview != nil) {
            break;
        } else {
            superView = superView.superview;
        }
    }
    
    CGPoint superviewPnt = [superView convertPoint:pnt toView:baseView];
    return superviewPnt;
}

- (void)reSizeTable {
    if ( listHeight > (int)rowHeight * (CGFloat) self.dataArray.count) {
        tableHeightX = (int)rowHeight * (CGFloat) self.dataArray.count;
    } else {
      tableHeightX = listHeight;
    }
    double y = pointToParent.y + self.frame.size.height + 5;
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.table.frame = CGRectMake(self->pointToParent.x, y, self.frame.size.width, self->tableHeightX);
    } completion:^(BOOL finished) {
        [self layoutIfNeeded];
    }];
}

- (void) showList {
    if (self.parentController == nil) {
        self.parentController = [self viewController];
        if (self.parentController == nil) {
            self.backgroundView.frame =  self.parentController.view.frame;
        } else {
            self.backgroundView.frame = self.backgroundView.frame;
        }
        pointToParent = [self getConvertedPoint:self baseView:self.parentController.view];
    }
    
    [self.parentController.view insertSubview:self.backgroundView aboveSubview:self];
    if ( listHeight > ((int)rowHeight * (CGFloat) self.dataArray.count)) {
        tableHeightX = (int)rowHeight * (CGFloat) self.dataArray.count;
    } else {
        tableHeightX = listHeight;
    }
    /* set up tableview */
    self.table = [[UITableView alloc]initWithFrame:CGRectMake(pointToParent.x, pointToParent.y + self.frame.size.height, self.frame.size.width, self.frame.size.height)];
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.alpha = 1.0;
    self.table.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.table.layer.cornerRadius = 0.0;
    self.table.backgroundColor = [UIColor clearColor];
    
    [self.parentController.view addSubview:self.table];
    [self.table registerClass:[SuggestionTableViewCell class] forCellReuseIdentifier:cellIdentifier];
    
    self.selected = YES;
    double y = pointToParent.y + self.frame.size.height + 5;
    
    [UIView animateWithDuration:0.9 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.table.frame = CGRectMake(self->pointToParent.x, y, self.frame.size.width, self->tableHeightX);
        self.table.alpha = 1.0;
    } completion:^(BOOL finished) {
        [self layoutIfNeeded];
    }];
}

-(void) hideList {
    [UIView animateWithDuration:1.0 delay:0.4 usingSpringWithDamping:0.9 initialSpringVelocity:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.table.frame = CGRectMake(self->pointToParent.x, self->pointToParent.y+self.frame.size.height, self.frame.size.width, 0);
    } completion:^(BOOL finished) {
        [self.table removeFromSuperview];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.backgroundView removeFromSuperview];
        });
        //[self listSubviewsOfView:self.parentController.view];
        self.selected = NO;
    }];
}

/* textfield delegate */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //[self touchAction];
    [textField resignFirstResponder];
    //self.selected = NO;
    //[self.backgroundView setHidden:true];
    return true;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    ///[self.dataArray removeAllObjects];
    [self touchAction];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return isSearchEnable;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    [self.backgroundView setHidden:false];
    
    if (![string  isEqual: @""]) {
        NSString *trimSpace = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [self setSearchText:[NSString stringWithFormat:@"%@%@", trimSpace, string]];
        
    } else {
        [self setSearchText:[self.text substringToIndex:self.text.length-1]];
    }
    if (!self.selected) {
        [self hideList];
    }
    /* hide show checkmark view */
    [self.instance convertToCoordinates:[NSString stringWithFormat:@"%@%@", textField.text, string] completion:^(W3wPlace * _Nonnull place, W3wError * _Nonnull error) {
        if ( place.coordinates.latitude != 0 && place.coordinates.longitude != 0 ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.checkMarkView setHidden:NO];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.checkMarkView setHidden:YES];
            });
        }
    }];
    return true;
}

/* table data source */
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

 - (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
        return 78.0;
 }

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {

    SuggestionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[SuggestionTableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    
    W3wSuggestion *suggestion = [self.dataArray objectAtIndex:indexPath.row];
        NSString *three_word_address = [NSString stringWithFormat:@"%@ %@", [self texthandler].text, suggestion.words];
        NSRange range = [three_word_address rangeOfString:@"///"];
        NSDictionary *attribs = @{ };
        NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc]initWithString:three_word_address attributes:attribs];
        [attributedString setAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:206.0/255.0 green:55.0/255.0 blue:50/255.0 alpha:1.0]} range:range];
        cell.three_word_address.text = [NSString stringWithFormat:@"///%@", suggestion.words];
        cell.nearest_place.text = suggestion.nearestPlace;
        cell.country_flag.image = [self countryFlagCrop: (int)[countries indexOfObject:suggestion.country.lowercaseString]];

        [cell setNeedsUpdateConstraints];
        [cell updateConstraintsIfNeeded];
    return cell;
}

-(UIImage *)countryFlagCrop:(int)countryIndex {
    int row = countryIndex % cols;
    int col = countryIndex / rows;
    int x = row * width;
    int y = col *height;
    NSBundle *bundle = [NSBundle bundleForClass:[W3wTextField class]];
    UIImage *flag_image = [UIImage imageNamed:@"flags" inBundle:bundle compatibleWithTraitCollection:nil];
    CGImageRef imageRef = CGImageCreateWithImageInRect(flag_image.CGImage, CGRectMake(x, y, width, height));
    UIImage *cropped_flag_image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropped_flag_image;
}

/*table view delegate */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        selectedIndex = (int) indexPath.row;
        W3wSuggestion *selectedText = [self.dataArray objectAtIndex:selectedIndex];
        NSString *w3w = selectedText.words;
        if (self.completionBlock != NULL) {
            self.completionBlock(w3w);
        }
        
        [tableView cellForRowAtIndexPath:indexPath].alpha = 0;
        [UIView animateWithDuration:0.5 animations:^{
            [tableView cellForRowAtIndexPath:indexPath].alpha = 1.0;
            [tableView cellForRowAtIndexPath:indexPath].backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            self.text = selectedText.words;
            [self.table reloadData];
        }];
        [self touchAction];
        [self.table removeFromSuperview];
        //[self.backgroundView removeFromSuperview];
        [self endEditing:YES];
    /* hide show checkmark view */
    [self.instance convertToCoordinates:selectedText.words completion:^(W3wPlace * _Nonnull place, W3wError * _Nonnull error) {
        if ( place.coordinates.latitude != 0 && place.coordinates.longitude != 0 ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.checkMarkView setHidden:NO];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.checkMarkView setHidden:YES];
            });
        }
    }];
}

- (void)didSelect:(didSelectCompletion)completion
{
    self.completionBlock = completion; // copy semantics
}

- (void)setSearchText:(NSString *)searchText {
    
    if (self.debounceTimer != nil) {
        dispatch_source_cancel(self.debounceTimer);
        self.debounceTimer = nil;
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    double secondsToThrottle = 0.2f;
    self.debounceTimer = CreateDebounceDispatchTimer(secondsToThrottle, queue, ^{
        if (![searchText isEqualToString:@""]) {
            [self->_instance autosuggest:searchText parameters:self.autoSuggestionOptions completion:^(NSArray *suggestions, W3wError *error)
            {
                if (error) {
                  NSLog(@"%@", error.message);
                }
                
                if ([suggestions count]) {
                 dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.dataArray removeAllObjects];
                });
                for (W3wSuggestion *suggestion in suggestions) {
                    [self.dataArray addObject:suggestion];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if ((self.dataArray.count) > 0) {
                             [self.table reloadData];
                        }
                    });
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.table reloadData];
                });
                }
            }];
        }
    });

    selectedIndex = 0;
    [self reSizeTable];
    //[self.table reloadData];
}

// TEST: result from w3w suggestion
- (void)setSuggestionArray:(W3wSuggestion*)suggestion {
    for (W3wSuggestion *suggestion in self.dataArray) {
        NSLog(@"dataArray:%@", suggestion.words);
    }
}

// TEST: print all subviews
- (void)listSubviewsOfView:(UIView *)view {

    // Get the subviews of the view
    NSArray *subviews = [view subviews];

    // Return if there are no subviews
    if ([subviews count] == 0) return; // COUNT CHECK LINE

    for (UIView *subview in subviews) {

        // Do what you want to do with the subview
        if ([subview isKindOfClass:[UIView class]]) {
            //NSLog(@"%@", subview.class);
        }

        // List the subviews of subview
        [self listSubviewsOfView:subview];
    }
}
- (void)setupCountries {
    countries = [[NSArray alloc]initWithObjects:@"ad", @"ae", @"af", @"ag", @"ai", @"al", @"am", @"ao", @"aq", @"ar", @"as", @"at", @"au", @"aw", @"ax", @"az", @"ba", @"bb", @"bd", @"be", @"bf", @"bg", @"bh", @"bi", @"bj", @"bl", @"bm", @"bn", @"bo", @"bq", @"br", @"bs", @"bt", @"bv", @"bw", @"by", @"bz", @"ca", @"cc", @"cd", @"cf", @"cg", @"ch", @"ci", @"ck", @"cl", @"cm", @"cn", @"co", @"cr", @"cu", @"cv", @"cw", @"cx", @"cy", @"cz", @"de", @"dj", @"dk", @"dm", @"do", @"dz", @"ec", @"ee", @"eg", @"eh", @"er", @"es", @"et", @"eu", @"fi", @"fj", @"fk", @"fm", @"fo", @"fr", @"ga", @"gb-eng", @"gb-nir", @"gb-sct", @"gb-wls", @"gb", @"gd", @"ge", @"gf", @"gg", @"gh", @"gi", @"gl", @"gm", @"gn", @"gp", @"gq", @"gr", @"gs", @"gt", @"gu", @"gw", @"gy", @"hk", @"hm", @"hn", @"hr", @"ht", @"hu", @"id", @"ie", @"il", @"im", @"in", @"io", @"iq", @"ir", @"is", @"it", @"je", @"jm", @"jo", @"jp", @"ke", @"kg", @"kh", @"ki", @"km", @"kn", @"kp", @"kr", @"kw", @"ky", @"kz", @"la", @"lb", @"lc", @"li", @"lk", @"lr", @"ls", @"lt", @"lu", @"lv", @"ly", @"ma", @"mc", @"md", @"me", @"mf", @"mg", @"mh", @"mk", @"ml", @"mm", @"mn", @"mo", @"mp", @"mq", @"mr", @"ms", @"mt", @"mu", @"mv", @"mw", @"mx", @"my", @"mz", @"na", @"nc", @"ne", @"nf", @"ng", @"ni", @"nl", @"no", @"np", @"nr", @"nu", @"nz", @"om", @"pa", @"pe", @"pf", @"pg", @"ph", @"pk", @"pl", @"pm", @"pn", @"pr", @"ps", @"pt", @"pw", @"py", @"qa", @"re", @"ro", @"rs", @"ru", @"rw", @"sa", @"sb", @"sc", @"sd", @"se", @"sg", @"sh", @"si", @"sj", @"sk", @"sl", @"sm", @"sn", @"so", @"sr", @"ss", @"st", @"sv", @"sx", @"sy", @"sz", @"tc", @"td", @"tf", @"tg", @"th", @"tj", @"tk", @"tl", @"tm", @"tn", @"to", @"tr", @"tt", @"tv", @"tw", @"tz", @"ua", @"ug", @"um", @"un", @"us", @"uy", @"uz", @"va", @"vc", @"ve", @"vg", @"vi", @"vn", @"vu", @"wf", @"ws", @"ye", @"yt", @"za", @"zm", @"zw", @"zz", nil];
}


dispatch_source_t CreateDebounceDispatchTimer(double debounceTime, dispatch_queue_t queue, dispatch_block_t block) {
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, debounceTime * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, (1ull * NSEC_PER_SEC) / 10);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    
    return timer;
}

@end

@implementation SuggestionTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // set up cell
        self.layer.borderColor = [UIColor colorWithRed:229.0/255.0 green:229.0/255.0 blue:229.0/255.0 alpha:1.0].CGColor;
        self.layer.borderWidth = 0.5;
   
        // Container view
        self.containerView = [UIView new];
        self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
        // Three word address label
        self.three_word_address = [UILabel new];
        self.three_word_address.translatesAutoresizingMaskIntoConstraints = NO;
        [self.three_word_address setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.three_word_address setTextAlignment:NSTextAlignmentLeft];
        self.three_word_address.textColor = [UIColor W3wTextColor];
        self.three_word_address.font = [UIFont systemFontOfSize:20.0f];
        // Nearest place
        [self.nearest_place setTextColor:[UIColor blackColor]];
        self.nearest_place = [UILabel new];
        self.nearest_place.translatesAutoresizingMaskIntoConstraints = NO;
        [self.nearest_place setLineBreakMode:NSLineBreakByTruncatingTail];
        [self.nearest_place setTextAlignment:NSTextAlignmentLeft];
        [self.nearest_place setTextColor:[UIColor blackColor]];
        self.nearest_place.textColor = [UIColor w3wLocationColor];
        self.nearest_place.font = [UIFont systemFontOfSize:12.0f];

        // country flag
        self.country_flag = [UIImageView new];
        self.country_flag.translatesAutoresizingMaskIntoConstraints = NO;
        
        // Set up views, labels
        [self.containerView addSubview:self.three_word_address];
        [self.containerView addSubview:self.nearest_place];
        [self.containerView addSubview:self.country_flag];
        [self.contentView addSubview:self.containerView];
    }
    return self;
}

-(void)updateConstraints {
    [super updateConstraints];
    
    // Container view
    NSLayoutConstraint *containerViewTop = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]; //Top
    
    NSLayoutConstraint *containerViewLeading = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:margin]; //Left
    
    NSLayoutConstraint *containerViewTrailing = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:-margin]; //Trailing
    
    NSLayoutConstraint *containerViewHeight = [NSLayoutConstraint constraintWithItem:self.containerView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeHeight multiplier:1.0f constant:0.0f]; //Height
    // Three word address
    NSLayoutConstraint *threeWordAddressTop = [NSLayoutConstraint constraintWithItem:self.three_word_address attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]; //Top
    
    NSLayoutConstraint *threeWordAddressLeft = [NSLayoutConstraint constraintWithItem:self.three_word_address attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f]; //Left
    
    NSLayoutConstraint *threeWordAddressWidth = [NSLayoutConstraint constraintWithItem:self.three_word_address attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.0f]; //Width
    
    NSLayoutConstraint *threeWordAddressHeight = [NSLayoutConstraint constraintWithItem:self.three_word_address attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeHeight multiplier:0.5f constant:0.0f]; //Height
   // Nearest place
    NSLayoutConstraint *nearestPlaceTop = [NSLayoutConstraint constraintWithItem:self.nearest_place attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.three_word_address attribute:NSLayoutAttributeBottom multiplier:1.3f constant:0.0f]; //Top
    NSLayoutConstraint *nearestPlaceLeading = [NSLayoutConstraint constraintWithItem:self.nearest_place attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.country_flag attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:5.0f]; //Leading
    // Flags
    NSLayoutConstraint *countryFlagLeading = [NSLayoutConstraint constraintWithItem:self.country_flag attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.three_word_address attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.0f]; //Leading
    NSLayoutConstraint *countryFlagCenter = [NSLayoutConstraint constraintWithItem:self.country_flag attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.nearest_place attribute:NSLayoutAttributeCenterY multiplier:1.0f constant:0.0f]; //center
    NSLayoutConstraint *countryFlagWidth = [NSLayoutConstraint constraintWithItem:self.country_flag attribute: NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute: NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:self.frame.size.height / 2.0]; //Width
    NSLayoutConstraint *countryFlagHeight = [NSLayoutConstraint constraintWithItem:self.country_flag attribute: NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute: NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:self.frame.size.height / 2.0 / 1.3]; //Height
    
    [self.contentView addConstraint:containerViewTop];
    [self.contentView addConstraint:containerViewLeading];
    [self.contentView addConstraint:containerViewTrailing];
    [self.contentView addConstraint:containerViewHeight];
    [self.containerView addConstraint:threeWordAddressTop];
    [self.containerView addConstraint:threeWordAddressLeft];
    [self.containerView addConstraint:threeWordAddressWidth];
    [self.containerView addConstraint:threeWordAddressHeight];
    [self.containerView addConstraint:nearestPlaceTop];
    [self.containerView addConstraint:nearestPlaceLeading];
    [self.containerView addConstraint:countryFlagLeading];
    [self.containerView addConstraint:countryFlagCenter];
    [self.containerView addConstraint:countryFlagWidth];
    [self.containerView addConstraint:countryFlagHeight];
}
@end

@implementation Coordinates : NSObject { }
@synthesize latitude;
@synthesize longitude;

-(id)initWithCoordinates:(NSString *)string {
    if (self = [super init])
    {
        NSArray *crdSplit = [string componentsSeparatedByString:@","];
        latitude = [[crdSplit firstObject] doubleValue];
        longitude = [[crdSplit lastObject] doubleValue];
    }
    return self;
}

@end


@implementation Clip : NSObject { }

@synthesize coordinates;
@synthesize kiloMeters;
@synthesize centreCoordinates;

- (id)initWithPolygon:(NSString *)string {
    if (self = [super init])
    {
        coordinates = [[NSMutableArray alloc]init];
        NSArray *crdSplit = [string componentsSeparatedByString:@","];
        NSUInteger index = 0;
        for(NSString *string __attribute__((unused)) in crdSplit)
        {
            if (index % 2 && index > 0) { //odd
                Coordinates *coordinate = [[Coordinates alloc]initWithCoordinates:[NSString stringWithFormat:@"%@,%@", [crdSplit objectAtIndex:index-1], [crdSplit objectAtIndex:index]]];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
                [self.coordinates addObject:location];
           }
           index ++;
        }
    }
    return self;
}

- (id)initWithBoundingBox:(NSString *)string {
    if (self = [super init])
    {
        coordinates = [[NSMutableArray alloc]init];
        NSArray *crdSplit = [string componentsSeparatedByString:@","];
        NSUInteger index = 0;
        for(NSString *string __attribute__((unused)) in crdSplit)
        {
            if (index % 2 && index > 0) { //odd
                Coordinates *coordinate = [[Coordinates alloc]initWithCoordinates:[NSString stringWithFormat:@"%@,%@", [crdSplit objectAtIndex:index-1], [crdSplit objectAtIndex:index]]];
                CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
                [self.coordinates addObject:location];
           }
           index ++;
        }
    }
    return self;
}

- (id)initWithCircle:(NSString *)string {
    if (self = [super init])
    {
        centreCoordinates = [[CLLocation alloc]init];
        NSArray *crdSplit = [string componentsSeparatedByString:@","];
        kiloMeters = [[crdSplit lastObject] doubleValue];
        NSUInteger index = 0;
        for(NSString *string __attribute__((unused)) in crdSplit)
        {
            if (index > 0) { //odd
                Coordinates *coordinate = [[Coordinates alloc]initWithCoordinates:[NSString stringWithFormat:@"%@,%@", [crdSplit objectAtIndex:index-1], [crdSplit objectAtIndex:index]]];
                centreCoordinates = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
                break;
           }
           index ++;
        }
    }
    return self;
}

- (NSMutableArray *)polygonCoordinates {
    return self.coordinates;
}

-(NSMutableArray *)boundingBoxCoordinates {
    return coordinates;
}

-(CLLocation *)circleCoordinates {
    return centreCoordinates;
}

@end
