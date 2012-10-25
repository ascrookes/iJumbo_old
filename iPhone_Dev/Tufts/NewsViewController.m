//
//  NewsViewController.m
//  Tufts
//
//  Created by Amadou Crookes on 7/13/12.
//  Copyright (c) 2012 Amadou Crookes. All rights reserved.
//

#import "NewsViewController.h"

const int UPDATE_TIME = 300; // 30 is 5 minutes -> seconds
const int IMAGE_SIZE  = 90; // The images are squares

@interface NewsViewController ()

@end

@implementation NewsViewController

@synthesize stories = _stories;
@synthesize rssParser = _rssParser;
@synthesize currentStory = _currentStory;
@synthesize currentKey = _currentKey;
@synthesize storyImages = _storyImages;
@synthesize section = _section;
@synthesize urls = _urls;
@synthesize currentURL = _currentURL;
@synthesize dataSource = _dataSource;
@synthesize imageDataSource = _imageDataSource;
@synthesize webViewBackButton = _webViewBackButton;
@synthesize webViewForwardButton = _webViewForwardButton;
@synthesize currentWebView = _currentWebView;
@synthesize storiesByType = _storiesByType;
@synthesize isLoading = _isLoading;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorColor = [UIColor colorWithRed:72.0/255 green:145.0/255 blue:206.0/255 alpha:1];
    self.tableView.backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"whiteBackground.png"]];
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem = self.section;
    
    if(self.isLoading) {
        [self setActivityIndicator];
    } else if([self.dataSource count] == 0) {
        [self loadData];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)loadData
{
    self.isLoading = YES;
    NSArray* storyToLoad = [self.storiesByType objectForKey:self.section.title];
    if(storyToLoad) {
        self.imageDataSource = [self.storiesByType objectForKey:[self.section.title stringByAppendingString:@" Images"]];
        self.dataSource = storyToLoad;
        [self.tableView reloadData];
        return;
    }
    [self setActivityIndicator];
    [self.rssParser abortParsing];
    dispatch_queue_t queue = dispatch_queue_create("load news data", nil);
    dispatch_async(queue, ^{
        [self parseXMLFileAtCurrentURL];
    });
    dispatch_release(queue);
}
     

- (void)setActivityIndicator
{
    UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    [activityView sizeToFit];
    [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
    [activityView startAnimating];
    UIBarButtonItem *loadingView = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    self.navigationItem.rightBarButtonItem = loadingView;
}

//*********************************************************
//*********************************************************
#pragma mark - Table View Delegate/Data Source
//*********************************************************
//*********************************************************

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.dataSource count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AWESOME NEWS CELL";
    NewsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil) {
        cell = [[NewsCell alloc] init];
    }

    [cell setupCellWithStory:[self.dataSource objectAtIndex:indexPath.row] andImageData:[self.imageDataSource objectAtIndex:indexPath.row]];

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NewsCell* cell = (NewsCell*)[tableView cellForRowAtIndexPath:indexPath];
    cell.webVC.title = @"The Daily";
    [self.navigationController pushViewController:[cell getWebViewController] animated:YES];
}


//*********************************************************
//*********************************************************
#pragma mark - RSS XML Parsing
//*********************************************************
//*********************************************************

- (void)parseXMLFileAtCurrentURL
{ 
    self.stories = [[NSMutableArray alloc] init];
    self.storyImages = [[NSMutableArray alloc] init];
    self.rssParser = [[NSXMLParser alloc] initWithContentsOfURL:self.currentURL];
    [self.rssParser setDelegate:self]; 
    [self.rssParser setShouldProcessNamespaces:NO]; 
    [self.rssParser setShouldReportNamespacePrefixes:NO]; 
    [self.rssParser setShouldResolveExternalEntities:NO]; 
    [self.rssParser parse];
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    self.currentKey = elementName;
    if([self.currentKey isEqualToString:@"media:thumbnail"]) {
        [self.currentStory setObject:[attributeDict objectForKey:@"url"] forKey:@"media:thumbnail"];
    }
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    self.isLoading = YES;
}


- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    self.dataSource = self.stories;
    self.imageDataSource = self.storyImages;
    [self.storiesByType setObject:self.dataSource forKey:self.section.title];
    [self.storiesByType setObject:self.imageDataSource forKey:[self.section.title stringByAppendingString:@" Images"]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self stopLoadingUI];
    });
    self.isLoading = NO;
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // Regex this instead something like -> '^\n\n?$' -> get obj c regex syntax if so
    NSString* strippedText = [string stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    strippedText = [strippedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if([strippedText isEqualToString:@""] && ![self continueWithCurrentKey]) {

        return;
    }
    
    if([self.currentKey isEqualToString:@"item"]) {
        self.currentStory = [NSMutableDictionary dictionaryWithCapacity:4];
    } else if([self.currentKey isEqualToString:@"title"]) {
        //NSLog(@"TITLE: [%@]", string);
        [self.currentStory setObject:string forKey:@"title"];
    } else if([self.currentKey isEqualToString:@"link"]) {
        //NSLog(@"LINK: [%@]", string);
        [self.currentStory setObject:string forKey:@"link"];
    } else if([self.currentKey isEqualToString:@"author"] || [self.currentKey isEqualToString:@"dc:creator"]) {
        //NSLog(@"AUTHOR: [%@]", string);
        [self.currentStory setObject:string forKey:@"author"];
    } else if([self.currentKey isEqualToString:@"media:thumbnail"]) {
        [self.currentStory setObject:string forKey:@"media:thumbnail"];
    } else if([self.currentKey isEqualToString:@"enclosure"] || [self.currentKey isEqualToString:@"slash:comments"]) {
        if(self.currentStory) {
            
            // this sets up the default image to display
            NSString* paperName = self.section.title;
            paperName = (paperName) ? paperName : @"The Daily";
            [self.currentStory setObject:paperName forKey:@"paperName"];
            [self.stories addObject:self.currentStory];
            
            NSData* thumbnailData = [NSData dataWithContentsOfURL:[NSURL URLWithString:[self.currentStory objectForKey:@"media:thumbnail"]]];
            if(!thumbnailData) { thumbnailData = [NSData data]; }
            [self.storyImages addObject:thumbnailData];
            self.currentStory = nil;
        }
    }
}

- (BOOL)continueWithCurrentKey
{
    // Make sure the key is one that we want to capture and it is not already set
    return  ([self.currentKey isEqualToString:@"item"] && ![self.currentStory objectForKey:@"item"])
            || ([self.currentKey isEqualToString:@"title"] && ![self. currentStory objectForKey:@"title"])
            || ([self.currentKey isEqualToString:@"link"] && ![self.currentStory objectForKey:@"link"])
            || (([self.currentKey isEqualToString:@"author"] || [self.currentKey isEqualToString:@"dc:creator"]) && ![self.currentStory objectForKey:@"author"])
            || ([self.currentKey isEqualToString:@"media:thumbnail"] && ![self.currentStory objectForKey:@"media:thumbnail"])
            || (([self.currentKey isEqualToString:@"enclosure"] || [self.currentKey isEqualToString:@"slash:comments"]) && ![self.currentStory objectForKey:@"enclosure"]);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    [self stopLoadingUI];
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{
    [self stopLoadingUI];
}

// Stops the UI that show when the data is loading
// only one line but maybe more UI will be used to show data is loading
// this keeps one place of truth
- (void)stopLoadingUI
{
    self.navigationItem.rightBarButtonItem = self.section;
}


//*********************************************************
//*********************************************************
#pragma mark - Action Sheet Selection
//*********************************************************
//*********************************************************


- (void)changeSection
{
    UIActionSheet* aSheet = [[UIActionSheet alloc] initWithTitle:@"Select A Section" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"The Daily",/*@"The Observer",*/@"Refresh",nil];
    [aSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{

    NSString* selectedTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if([selectedTitle isEqualToString:@"Refresh"]) {
        // clear the data so that it has to load again
        self.imageDataSource = nil;
        self.dataSource = nil;
        self.stories = nil;
        self.storiesByType = nil;
        // reload the table so that it does not try and load data no longer there
        [self.tableView reloadData];
        // fetch the fresh data
        [self loadData];
        return;
    }
    if([selectedTitle isEqualToString:self.section.title] || [selectedTitle isEqualToString:@"Cancel"]) {
        return;
    } else {
        self.section.title = selectedTitle;
    }
    
    self.currentURL = [NSURL URLWithString:[self.urls objectForKey:self.section.title]];
    [self loadData];
}

//*********************************************************
//*********************************************************
#pragma mark - Data Management
//*********************************************************
//*********************************************************

- (void)clearUnnecessary
{
    if(!self.isLoading) {
        self.stories = nil;
        self.rssParser = nil;
        self.currentStory = nil;
        self.currentKey = nil;
        self.storyImages = nil;
        self.urls = nil;
        self.currentURL = nil;
        self.storiesByType = nil;
    }
}


//*********************************************************
//*********************************************************
#pragma mark - Setters/Getters
//*********************************************************
//*********************************************************

- (NSMutableArray*)storyImages
{
    if(!_storyImages) {
        _storyImages = [[NSMutableArray alloc] init];
    }
    return _storyImages;
}

// setups a link between the bar button item to select which newspaper feed to from
- (NSDictionary*)urls
{
    if(!_urls) {
        _urls = [NSDictionary dictionaryWithObjectsAndKeys:
                 @"http://www.tuftsdaily.com/se/tufts-daily-rss-1.445827", @"The Daily",
                 /*@"http://tuftsobserver.org/feed/", @"The Observer",*/
                 nil];
    }
    return _urls;
}

- (NSMutableDictionary*)storiesByType
{
    // If the the stories were loaded an hour ago delete the list 
    // and update again to get newly updated stories if any
    if(_storiesByType && [[_storiesByType objectForKey:@"createdDate"] timeIntervalSinceNow] > UPDATE_TIME) {
        _storiesByType = nil;
    }
    
    if(!_storiesByType) {
        _storiesByType = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          nil,@"The Daily",
                          nil,@"The Observer",
                          nil,@"The Daily Images",
                          nil,@"The Observer Images",
                          [NSDate date],@"createdDate",
                          nil];
    }
    
    return _storiesByType;
}

- (NSURL*)currentURL
{
    if(!_currentURL) {
        _currentURL = [NSURL URLWithString:[self.urls objectForKey:self.section.title]];
    }
    return _currentURL;
}

- (UIBarButtonItem*)section
{
    if(!_section) {
        _section = [[UIBarButtonItem alloc] initWithTitle:@"The Daily" style:UIBarButtonItemStylePlain target:self action:@selector(changeSection)];
    }
    return _section;
}

- (NSMutableArray*)stories
{
    if(!_stories) {
        _stories = [[NSMutableArray alloc] init];
    }
    return _stories;
}

- (void)setDataSource:(NSArray *)dataSource
{
    _dataSource = dataSource;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
    
}

- (UIBarButtonItem*)webViewForwardButton
{
    if(!_webViewForwardButton) {
        _webViewForwardButton = [[UIBarButtonItem alloc] initWithTitle:@"Forward" style:UIBarButtonItemStylePlain target:self.currentWebView action:@selector(goForward)];
    }
    return _webViewForwardButton;
}

- (UIBarButtonItem*)webViewBackButton
{
    if(!_webViewBackButton) {
        _webViewBackButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self.currentWebView action:@selector(goBack)];
    }
    return _webViewBackButton;
}

                                            

@end
