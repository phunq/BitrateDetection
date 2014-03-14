//
//  MainVC.m
//  BitrateDetection
//
//  Created by Phu Nguyen on 3/13/14.
//  Copyright (c) 2014 Phu Nguyen. All rights reserved.
//

#import "MainVC.h"

@interface MainVC () {
    IBOutlet UILabel *_lblStatus;
    IBOutlet UIButton *_btnRefresh;
    
    float _duration;
}

@property (nonatomic, strong) NSURLConnection *connection; // we'll use presence or existence of this connection to determine if download is done
@property (nonatomic) NSUInteger length;                   // the numbers of bytes downloaded from the server thus far
@property (nonatomic, strong) NSDate *startTime;           // when did the download start

- (IBAction)refresh:(id)sender;

@end

static CGFloat const kMinimumMegabytesPerSecond = 20;
static CGFloat const kMaximumElapsedTime = 100.0;

@implementation MainVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self testDownloadSpeed];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // I actually want my download speed to factor out latency, so I'll reset the
    // starting timer when the download commences
    
    self.startTime = [NSDate date];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.connection)
    {
        self.connection = nil;
        [self useOffline];
    }
    _btnRefresh.enabled = YES;
//    _btnRefresh.titleLabel.text = @"Refresh";
    [_btnRefresh setTitle:@"Refresh" forState:UIControlStateNormal];
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.connection = nil;
    
    if ([self determineMegabytesPerSecond] >= kMinimumMegabytesPerSecond)
        [self useOnline];
    else
        [self useOffline];
    _btnRefresh.enabled = YES;
    [_btnRefresh setTitle:@"Refresh" forState:UIControlStateNormal];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // you don't need to do anything with the downloaded data;
    // just keep track of # of bytes
    
    self.length += [data length];
}

#pragma mark - Private methods

- (void)testDownloadSpeed
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    NSURL *url = [NSURL URLWithString:@"http://cdn.business2community.com/wp-content/uploads/2013/08/zvkPNzK1.jpg"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    self.startTime = [NSDate date];
    self.length = 0;
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
    double delayInSeconds = kMaximumElapsedTime;
    
//    _btnRefresh.titleLabel.text = @"Downloading...";
    [_btnRefresh setTitle:@"Downloading..." forState:UIControlStateNormal];
    _btnRefresh.enabled = NO;
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.connection)
        {
            [self.connection cancel];
            self.connection = nil;
            [self useOffline];
        }
    });
}

- (CGFloat)determineMegabytesPerSecond
{
    NSTimeInterval elapsed;
    
    if (self.startTime)
    {
        elapsed = [[NSDate date] timeIntervalSinceDate:self.startTime];
        NSLog(@"seconds: %f", elapsed);
        _duration = elapsed;
        return self.length / elapsed / 1024 / 1024;    // Mbps
    }
    
    return -1;
}

- (void)useOnline
{
    // use your MKMapView; I'm just updating a text field with the status
    _lblStatus.text = [NSString stringWithFormat:@"Speed:\t     %.4f Mbps\nDuration:\t  %f seconds", [self determineMegabytesPerSecond], _duration];
    NSLog(@"%@",[NSString stringWithFormat:@"successful %.4f Mbps", [self determineMegabytesPerSecond]]);
}

- (void)useOffline
{
    // use your offline maps; I'm just updating a text field with the status
    _lblStatus.text = [NSString stringWithFormat:@"Speed:\t     %.4f Mbps\nDuration:\t  %f seconds", [self determineMegabytesPerSecond], _duration];
    NSLog(@"%@",[NSString stringWithFormat:@"unsuccessful %.4f Mbps", [self determineMegabytesPerSecond]]);
}

#pragma mark - Actions

- (IBAction)refresh:(id)sender {
    [self testDownloadSpeed];
}

@end
