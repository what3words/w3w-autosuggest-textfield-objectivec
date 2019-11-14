//
//  W3wTextField.h
//
//
//  Created by Lshiva on 28/06/2019.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

typedef void (^didSelectCompletion)(NSString*selectedText);


IB_DESIGNABLE
@interface W3wTextField : UITextField

// W3wSuggestionField custom UI properties
@property (nonatomic, assign) IBInspectable CGFloat fieldCornerRadius;
@property (nonatomic, assign) IBInspectable UIColor *fieldBorderColor;
@property (nonatomic, assign) IBInspectable CGFloat fieldBorderWidth;

// W3wSuggestionField custom autosuggest properties
@property (nonatomic, assign) IBInspectable int nResults;
@property (nonatomic, assign) IBInspectable NSString *autoFocus;
@property (nonatomic, assign) IBInspectable int nFocusResults;
@property (nonatomic, assign) IBInspectable NSString *clipToCountry;
@property (nonatomic, assign) IBInspectable NSString *clipToBoundingBox;
@property (nonatomic, assign) IBInspectable NSString *clipToCircle;
@property (nonatomic, assign) IBInspectable NSString *clipToPolygon;

// addtional properties
@property (nonatomic, assign) IBInspectable BOOL debug;
@property (nonatomic, assign) IBInspectable CGFloat listHeigh;


@property(nonatomic) bool isSearchEnable;

- (void)setAPIKey:(NSString *)apiKey;
- (void)didSelect:(didSelectCompletion)completion;

@end

@interface SuggestionTableViewCell : UITableViewCell
    @property(nonatomic, strong) IBOutlet UIView *containerView;
    @property(nonatomic, strong) IBOutlet UILabel *three_word_address;
    @property(nonatomic, strong) IBOutlet UILabel *nearest_place;
    @property(nonatomic, strong) IBOutlet UIImageView *country_flag;

@end

@interface Coordinates : NSObject
    @property(nonatomic) double latitude;
    @property(nonatomic) double longitude;

-(id)initWithCoordinates:(NSString*)string;

@end

@interface Clip : NSObject
    @property(nonatomic) NSMutableArray *coordinates;
    @property(nonatomic) CLLocation *centreCoordinates;
    @property(nonatomic) double kiloMeters;

- (id)initWithPolygon:(NSString *)string;
- (id)initWithBoundingBox:(NSString *)string;
- (id)initWithCircle:(NSString *)string;

- (NSMutableArray *) polygonCoordinates;
- (NSMutableArray *) boundingBoxCoordinates;
- (CLLocation *) circleCoordinates;

@end
