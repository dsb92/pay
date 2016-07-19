//
//  ViewController.m
//  ePay Example
//

#import "ViewController.h"
#import "ePayLib.h"
#import "ePayParameter.h"
#import "AFNetworking.h"

typedef void (^AFFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON);
typedef void (^AFSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON);
typedef void (^WSInternalSuccessBlock)(id JSON);
typedef void (^WSInternalRetryBlock)(int retries);

@interface WebServiceRequest()
@property (weak, nonatomic) AFHTTPRequestOperation *request;
@property (strong, nonatomic) NSMutableArray *childRequests;
@end

@implementation WebServiceRequest

- (id)init {
    if ((self = [super init])) {
        _childRequests = [NSMutableArray array];
    }
    return self;
}

- (void)cancel {
    [self.request cancel];
    for (WebServiceRequest *request in _childRequests) {
        [request cancel];
    }
}

@end


@implementation WebServiceFailure
- (id)initWithError:(NSError*)error {
    if ((self = [super init])) {
        self.error = error;
    }
    return self;
}

- (NSString*)description {
    return self.error.description;
}
@end

@implementation ePayParameters

- (NSDictionary*)toJSON {
    
    // Declare your unique OrderId
    NSString *orderId = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
    
    NSMutableDictionary *JSON = [NSMutableDictionary dictionary];
    JSON[@"merchantnumber"] = @"99999999";
    JSON[@"orderid"] = orderId;
    JSON[@"amount"] = @"100";
    JSON[@"currency"] = @"DKK";
    JSON[@"paymenttype"] = @"1";
    JSON[@"cssurl"] = @"https://raw.github.com/ePay/paymentwindow-cssurl-example/master/style.css";
    
    return JSON;
}

@end

@interface ViewController ()
{
    ePayLib* epaylib;
    
}

@property (strong, nonatomic) UIWebView *webView;

@end

@implementation ViewController

@synthesize activityIndicatorView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Listen to ePay Lib notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(event:) name:PaymentAcceptedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(event:) name:PaymentLoadingAcceptPageNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(event:) name:PaymentWindowCancelledNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(event:) name:PaymentWindowLoadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(event:) name:PaymentWindowLoadingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(event:) name:ErrorOccurredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(event:) name:NetworkActivityNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(event:) name:NetworkNoActivityNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction)goToPaymentClick:(id)sender {
    [self initPayment];
}

- (void)initPayment {
    // Declare your unique OrderId
    NSString *orderId = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
    
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    epaylib = [[ePayLib alloc]init];
    epaylib.parameters = [[NSMutableArray alloc]init];
    
    // Add parameters to the array
    [epaylib.parameters addObject:[ePayParameter key:@"merchantnumber" value:@"8025117"]];          //http://tech.epay.dk/en/specification#258
    [epaylib.parameters addObject:[ePayParameter key:@"currency" value:@"DKK"]];                    //http://tech.epay.dk/en/specification#259
    [epaylib.parameters addObject:[ePayParameter key:@"amount" value:@"100"]];                      //http://tech.epay.dk/en/specification#260
    [epaylib.parameters addObject:[ePayParameter key:@"orderid" value:orderId]];                    //http://tech.epay.dk/en/specification#261
    [epaylib.parameters addObject:[ePayParameter key:@"paymenttype" value:@"1,3,4,7"]];                      //http://tech.epay.dk/en/specification#265
    [epaylib.parameters addObject:[ePayParameter key:@"mobile" value:@"0"]];
        [epaylib.parameters addObject:[ePayParameter key:@"language" value:@"1"]];
            [epaylib.parameters addObject:[ePayParameter key:@"windowstate" value:@"3"]];
                //[epaylib.parameters addObject:[ePayParameter key:@"paymentcollection" value:@"1"]];

    
    // Alernativ way
    NSString *body = @"";
    for(ePayParameter *parameter in epaylib.parameters){
        NSString *keyValuePair = [NSString stringWithFormat:@"%@=%@&", parameter.key, parameter.value];
        
        body = [body stringByAppendingString:keyValuePair];
    }
    
    body = [body substringToIndex:[body length]-1]; // Remove the last &
    
    NSString *urlString = @"https://ssl.ditonlinebetalingssystem.dk/integration/ewindow/Default.aspx";
    urlString = [urlString stringByAppendingString:[NSString stringWithFormat:@"?%@", body]];
    NSURL *url = [NSURL URLWithString: urlString];
    NSLog(@"%@", urlString);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:url];
    
    [_webView loadRequest:request];
    [self.view addSubview:_webView];
    
    //    // Show/hide the Cancel button
    //    [epaylib setDisplayCancelButton:YES];
    
    _webView.delegate = self;
    //    // Load the payment window
    //    [epaylib loadPaymentWindow];
    
}

//-(void)initPayment {
//    NSString *orderId = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
//
//    // Init the ePay Lib with parameters and the view to add it to.
//    epaylib = [[ePayLib alloc] init];
//    epaylib.parameters = [[NSMutableArray alloc]init];
//
//    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
//
//    // Add parameters to the array
//    [epaylib.parameters addObject:[ePayParameter key:@"merchantnumber" value:@"8025117"]];          //http://tech.epay.dk/en/specification#258
//    [epaylib.parameters addObject:[ePayParameter key:@"currency" value:@"DKK"]];                    //http://tech.epay.dk/en/specification#259
//    [epaylib.parameters addObject:[ePayParameter key:@"amount" value:@"100"]];                      //http://tech.epay.dk/en/specification#260
//    [epaylib.parameters addObject:[ePayParameter key:@"orderid" value:orderId]];                    //http://tech.epay.dk/en/specification#261
//    [epaylib.parameters addObject:[ePayParameter key:@"paymenttype" value:@"1,3,4,7"]];                      //http://tech.epay.dk/en/specification#265
//
//    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"epaywindow" ofType:@"html"];
//    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
//    [_webView loadHTMLString:htmlString baseURL: [[NSBundle mainBundle] bundleURL]];
//
//    self.webView.delegate = self;
//    [self.view addSubview:_webView];
//}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    NSLog(@"webViewDidStartLoad");
}

// If we want to manipulate ePay's webview...
-(void)webViewDidFinishLoad:(UIWebView *)webView{
    NSLog(@"webViewDidFinishLoad");
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Custom_Theme" ofType:@"css"];
    
    NSString *cssString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    cssString = [cssString stringByReplacingOccurrencesOfString:@"\n" withString:@" "]; // js dom inject doesn't accept line breaks, so remove them
    NSString *createStyle = @"var style = document.createElement('style');";
    NSString *insertCss = [NSString stringWithFormat:@"style.innerHTML = \"%@\";", cssString];
    NSString *getHeader = @"var head = document.getElementsByTagName('head')[0];";
    NSString *appendChild = @"head.appendChild(style);";

    [webView stringByEvaluatingJavaScriptFromString:createStyle];
    [webView stringByEvaluatingJavaScriptFromString:insertCss];
    [webView stringByEvaluatingJavaScriptFromString:getHeader];
    [webView stringByEvaluatingJavaScriptFromString:appendChild];
    
    NSLog(@"%@\n%@\n%@\n%@", createStyle, insertCss, getHeader, appendChild);
}

- (void)event:(NSNotification*)notification {
    // Here we handle all events sent from the ePay Lib
    
    if ([[notification name] isEqualToString:PaymentAcceptedNotification]) {
        NSLog(@"EVENT: PaymentAcceptedNotification");
        
        for (ePayParameter *item in [notification object]) {
            NSLog(@"Data: %@ = %@", item.key, item.value);
        }
    }
    else if ([[notification name] isEqualToString:PaymentLoadingAcceptPageNotification]) {
        NSLog(@"EVENT: PaymentLoadingAcceptPageNotification");
    }
    else if ([[notification name] isEqualToString:PaymentWindowCancelledNotification]) {
        NSLog(@"EVENT: PaymentWindowCancelledNotification");
    }
    else if ([[notification name] isEqualToString:PaymentWindowLoadingNotification]) {
        NSLog(@"EVENT: PaymentWindowLoadingNotification");
        
        // Display a loading indicator while loading the payment window
        [activityIndicatorView startAnimating];
    }
    else if ([[notification name] isEqualToString:PaymentWindowLoadedNotification]) {
        NSLog(@"EVENT: PaymentWindowLoadedNotification");
        
        // Stop our loading indicator when the payment window is loaded
        [activityIndicatorView stopAnimating];
    }
    else if ([[notification name] isEqualToString:ErrorOccurredNotification]) {
        // Display error object if we get a error notification
        NSLog(@"EVENT: ErrorOccurredNotification - %@", [notification object]);
    }
    else if ([[notification name] isEqualToString:NetworkActivityNotification]) {
        // Display network indicator in the statusbar
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
    else if ([[notification name] isEqualToString:NetworkNoActivityNotification]) {
        // Hide network indicator in the statusbar
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

- (WebServiceRequest *)requestPaymentWithSavedCardParameters:(ePayParameters*)parameters
                                                     success:(void (^)(NSString *response))success
                                                     failure:(WSFailureBlock)failure
{
    WebServiceRequest *request = [[WebServiceRequest alloc]init];
    [self requestPaymentWithSavedCardParameters:parameters success:success failure:failure wsRequest:request retries:3];
    return request;
}

-(void)requestPaymentWithSavedCardParameters:(ePayParameters*)parameters
                                     success:(void (^)(NSString *response))success
                                     failure:(WSFailureBlock)failure
                                   wsRequest:(WebServiceRequest *)wsRequest
                                     retries:(int)retries
{
    NSString *path = @"https://ssl.ditonlinebetalingssystem.dk/integration/ewindow/Default.aspx";
    AFHTTPClient *httpClient = [[AFHTTPClient alloc]initWithBaseURL:[NSURL URLWithString:path]];
    [httpClient setDefaultHeader:@"Accept" value:@"text/html"];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:parameters.toJSON];
    
    NSLog(@"requestPaymentWithSavedCardParameters REQUEST PATH: %@\nJSON: %@", path, parameters.toJSON);
    
    request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    AFFailureBlock failureBlock = [ViewController
                                   failureBlockWithRequest:wsRequest
                                   internalRetryBlock:^(int retries) {
                                       
                                       NSLog(@"FAILED REQUEST requestPaymentWithSavedCardParameters");
                                       if (retries > 0){
                                           [self requestPaymentWithSavedCardParameters:parameters
                                                                               success:success
                                                                               failure:failure
                                                                             wsRequest:wsRequest
                                                                               retries:retries-1];
                                       }
                                       else{
                                           WebServiceFailure *fail = [[WebServiceFailure alloc] initWithError:nil];
                                           failure(fail);
                                       }
                                       
                                   }
                                   failureBlock:failure
                                   retries:retries];
    
    AFSuccessBlock successBlock = [ViewController
                                   successBlockWithRequest:wsRequest
                                   internalSuccessBlock:^(id JSON) {
                                       
                                       NSLog(@"requestPaymentWithSavedCardParameters RESPONSE PATH: %@\nJSON: %@", path, JSON);
                                       // Don't send anything back for now...
                                       success(nil);
                                       
                                   } failureBlock:failureBlock];
    
    wsRequest.request = [AFJSONRequestOperation
                         JSONRequestOperationWithRequest:request
                         success:successBlock
                         failure:failureBlock];
    [wsRequest.request start];
    
}

+ (AFSuccessBlock)successBlockWithRequest:(WebServiceRequest *)wsRequest
                     internalSuccessBlock:(WSInternalSuccessBlock)successBlock
                             failureBlock:(AFFailureBlock)failureBlock {
    AFSuccessBlock block = ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (wsRequest.request.isCancelled) {
            return;
        }
        if (!JSON) {
            failureBlock(request, response, nil, nil);
            return;
        }
        successBlock(JSON);
    };
    return block;
}


+ (AFFailureBlock)failureBlockWithRequest:(WebServiceRequest*)wsRequest internalRetryBlock:(WSInternalRetryBlock)retryBlock failureBlock:(WSFailureBlock)failureBlock  retries:(int)retries {
    AFFailureBlock block = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@"WebServiceFailure: %@", error);
        
        if (wsRequest.request.isCancelled) {
            return;
        }
        if (retries > 0) {
            retryBlock(retries);
            return;
        }
        
        
        if (failureBlock)
        {
            WebServiceFailure *fail = [[WebServiceFailure alloc] initWithError:error];
            failureBlock(fail);
        }
    };
    
    return block;
}


@end