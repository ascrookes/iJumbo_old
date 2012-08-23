//
//  MenuTableViewController.m
//  Tufts
//
//  Created by Amadou Crookes on 4/17/12.
//  Copyright (c) 2012 Amadou Crookes. All rights reserved.
//

#import "MenuTableViewController.h"
#import "AppDelegate.h"

const int SECTION_HEIGHT = 45;
const int HEIGHT_OF_HELPER_VIEWS_IN_MEALS = 186;

@interface MenuTableViewController ()

@end

@implementation MenuTableViewController

@synthesize dataSource = _dataSource;
@synthesize masterDict = _masterDict;
@synthesize isLoading = _isLoading;
@synthesize lastUpdate = _lastUpdate;
@synthesize loadingView = _loadingView;
@synthesize noFood = _noFood;

//*********************************************************
//*********************************************************
#pragma mark - Standard Stuff
//*********************************************************
//*********************************************************

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
    [self addBarInfo];
    if(!self.isLoading) {
        [self.tableView reloadData];
    }
    if(!self.masterDict || [self.masterDict count] == 0) {
        [self loadData];
    }
    [self loadDataBasedOnDate];
}

- (void)addBarInfo
{
    UIBarButtonItem* halls = [[UIBarButtonItem alloc] initWithTitle:@"Carmichael" style:UIBarButtonItemStylePlain target:self action:@selector(changeHall)];
    self.navigationItem.rightBarButtonItem = halls;
    
    UISegmentedControl* segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Break",@"Lunch",@"Dinner",nil]];
    segment.selectedSegmentIndex = 0;
    [segment addTarget:self action:@selector(setDataSourceFromMaster) forControlEvents:UIControlEventValueChanged];
    [segment setSegmentedControlStyle:UISegmentedControlStyleBar];
    segment.selectedSegmentIndex = 0;
    self.navigationItem.titleView = segment;
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



//*********************************************************
//*********************************************************
#pragma mark - Segments and Action Sheets
//*********************************************************
//*********************************************************

- (void)changeHall
{
    UIActionSheet* sheet = [[UIActionSheet alloc] initWithTitle:@"Select Dining Hall"
                                delegate:self
                       cancelButtonTitle:@"Cancel"
                  destructiveButtonTitle:nil
                       otherButtonTitles:@"Dewick", @"Hodgdon", @"Carmichael", nil];
    
    // Show the sheet
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString* diningHall = [actionSheet buttonTitleAtIndex:buttonIndex];
    if([self.navigationItem.rightBarButtonItem.title isEqualToString:diningHall] || 
       [[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Cancel"]    ) {
        return;
    }
    self.navigationItem.rightBarButtonItem.title = diningHall;
    [self setDataSourceFromMaster];
}


- (void)setDataSourceFromMaster
{
    if(!self.masterDict) {
        [self loadData];
    }
    int segIndex = ((UISegmentedControl*)self.navigationItem.titleView).selectedSegmentIndex;
    NSString* mealKey = (segIndex == 0) ? @"Breakfast" : (segIndex == 1) ? @"Lunch" : @"Dinner";
    NSString* hallName = self.navigationItem.rightBarButtonItem.title;
    if(!hallName) {
        hallName = @"Carmichael";
    }
    NSDictionary* hall = [self.masterDict objectForKey:hallName];
    
    if([hall containsKey:mealKey]) {
        self.dataSource = [[hall objectForKey:mealKey] objectForKey:@"sections"];
    }
    [self.tableView reloadData];
}


//*********************************************************
//*********************************************************
#pragma mark - JSON loading
//*********************************************************
//*********************************************************


- (void)loadData
{
    NSURL *url = [NSURL URLWithString:@"http://www.eecs.tufts.edu/~acrook01/files/meals.json"];
    self.isLoading = YES;
    self.loadingView.hidden = NO;
    self.noFood.hidden = YES;
    // Set up a concurrent queue
    dispatch_queue_t queue = dispatch_queue_create("Menu Table Load", nil);
    dispatch_async(queue, ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        [self parseData:data];
    });
    dispatch_release(queue);
}

- (void)parseData:(NSData *)responseData
{
    if(responseData == nil) {
        AppDelegate* del = [[UIApplication sharedApplication] delegate];
        [del pingServer];
        self.loadingView.hidden = YES;
        return;
    }
    NSError* error;
    
    self.masterDict = [NSJSONSerialization JSONObjectWithData:responseData
                                                    options:0
                                                      error:&error];
    [self setDataSourceFromMaster];
        
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        self.lastUpdate = [NSDate date];
        self.isLoading = NO;
        self.loadingView.hidden = YES;
    });
}






//*********************************************************
//*********************************************************
#pragma mark - Table View Delegate/Data Source
//*********************************************************
//*********************************************************


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    self.noFood.hidden = !([self.dataSource count] == 0 && !self.isLoading);
    return [self.dataSource count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[self.dataSource objectAtIndex:section] objectForKey:@"foods"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Menu Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.text = [[[[self.dataSource objectAtIndex:indexPath.section] objectForKey:@"foods"] objectAtIndex:indexPath.row] objectForKey:@"FoodName"];
    return cell;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self.dataSource objectAtIndex:section] objectForKey:@"SectionName"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FoodViewController* fvc = [self.storyboard instantiateViewControllerWithIdentifier:@"Food View"];
    [fvc setFood:[[[self.dataSource objectAtIndex:indexPath.section] objectForKey:@"foods"] objectAtIndex:indexPath.row]];
    [fvc setTitle:[fvc.food objectForKey:@"FoodName"]];
    fvc.view.backgroundColor = self.tableView.backgroundColor;
    [self.navigationController pushViewController:fvc animated:YES];
}


- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 320, SECTION_HEIGHT)];
    label.backgroundColor = self.tableView.backgroundColor;
    label.text = [[self.dataSource objectAtIndex:section] objectForKey:@"SectionName"];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:16];
    label.numberOfLines = 2;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumFontSize = 14;
    UIView* header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, SECTION_HEIGHT)];
    [header addSubview:label];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTION_HEIGHT;
}

//*********************************************************
//*********************************************************
#pragma mark - Other
//*********************************************************
//*********************************************************

// If it is after the meal scrape time(2:00) and the last update 
// was before 2:00 then load the data again.
// To be safe it checks if it is after 3
// compares the dates with ints (yyyymmddhh)
- (void)loadDataBasedOnDate
{
    if(!self.lastUpdate || !self.dataSource) {
        [self loadData];
        return;
    }
    int now = [MenuTableViewController getNumericalDate:[NSDate date]];
    int updated = [MenuTableViewController getNumericalDate:self.lastUpdate];
    // the script updates at 2 so we will update at 3
    int todaysUpdate = ((now / 100) * 100) + 3;
    if(now > todaysUpdate && todaysUpdate > updated) {
        [self loadData];
    }
}
 
+ (int)getNumericalDate:(NSDate*)date
{
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMddhh"];
    NSString* dateString = [dateFormat stringFromDate:date];

    return [dateString intValue];
}

//*********************************************************
//*********************************************************
#pragma mark - Data Management
//*********************************************************
//*********************************************************

- (void)clearUnnecessary
{
    [self setNoFood:nil];
    [self setLoadingView:nil];
}

- (UIView*)loadingView
{
    
    if(!_loadingView) {
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, HEIGHT_OF_HELPER_VIEWS_IN_MEALS)];
        _loadingView.backgroundColor = [UIColor clearColor];
        UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, HEIGHT_OF_HELPER_VIEWS_IN_MEALS)];
        label.text = @"LOADING";
        label.textColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentRight;
        label.backgroundColor = [UIColor clearColor];
        [_loadingView addSubview:label];
        UIActivityIndicatorView* activiyIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(180, 0, 40, HEIGHT_OF_HELPER_VIEWS_IN_MEALS)];
        activiyIndicator.backgroundColor = [UIColor clearColor];
        [activiyIndicator startAnimating];
        [_loadingView addSubview:activiyIndicator];
        [self.tableView addSubview:_loadingView];
    }
    return _loadingView;
}

- (UIView*)noFood
{
    if(!_noFood) {
        _noFood = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 186)];
        _noFood.backgroundColor = [UIColor clearColor];
        UILabel* label = [[UILabel alloc] initWithFrame:_noFood.frame];
        label.text = @"Meal Not Available";
        label.textColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        [_noFood addSubview:label];
        [self.tableView addSubview:_noFood];
    }
    return _noFood;
}

@end
