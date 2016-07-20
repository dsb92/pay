//
//  ViewController.h
//  ePay Example
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"
#import "AFHTTPClient.h"

@interface WebServiceRequest : NSObject
- (void)cancel;
@end

@interface WebServiceFailure : NSObject
@property (strong, nonatomic) NSError* error;
@property (assign, nonatomic) int reason;
@property (strong, nonatomic) NSString* customMessage;
@end


typedef void (^WSFailureBlock)(WebServiceFailure *error);

@interface ePayParameters : NSObject
- (NSDictionary*)toJSON;
@end

@interface ViewController : UIViewController <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *webViewPlaceholder;
@property (weak, nonatomic) IBOutlet UIButton *startPayment;

-(WebServiceRequest *)requestPaymentWithSavedCardParameters:(ePayParameters*)parameters
                                                    success:(void (^)(NSString *response))success
                                                    failure:(WSFailureBlock)failure;

@end
