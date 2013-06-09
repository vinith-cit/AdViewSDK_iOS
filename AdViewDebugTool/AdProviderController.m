//
//  AdProviderController.m
//  AdViewHello
//
//  Created by the user on 12-7-12.
//  Copyright (c) 2012年 Access China. All rights reserved.
//

#import "AdProviderController.h"
#import "AdViewUtils.h"
#import "SimpleViewController.h"


@implementation AdProviderController

@synthesize adProviders;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.adProviders = [AdViewUtils getAdPlatforms];
        self.title = @"Ad Provider";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)setAllAdProviders:(BOOL)bVal Except:(int)type
{
    NSArray *keyArr = [self.adProviders allKeys];
    
    int     setVal = bVal?1:0;
    int     extVal = bVal?0:1;
    
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:10];
    for (int i = 0; i < [keyArr count]; i++)
    {
        NSNumber *keyNum = [keyArr objectAtIndex:i];
        
        if (nil == keyNum) continue;
        
        int iVal = setVal;
        if (type == [keyNum intValue]) iVal = extVal;
        [dict setObject:[NSNumber numberWithInt:iVal] forKey:keyNum];
    }
    [AdViewUtils setAdPlatformStatus:dict];
    [dict release];
}

- (void)dealloc
{
    [self setAllAdProviders:YES Except:-1000];
    self.adProviders = nil;

    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.adProviders allKeys] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    int row = [indexPath row];
    NSNumber *keyNum = [[self.adProviders allKeys] objectAtIndex:row];
    NSString *strVal = [self.adProviders objectForKey:keyNum];
    
    NSArray *strItems = [strVal componentsSeparatedByString:@","];
    cell.textLabel.text = [strItems objectAtIndex:0];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", row];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    int row = [indexPath row];
    NSNumber *keyNum = [[self.adProviders allKeys] objectAtIndex:row];
    [self setAllAdProviders:NO Except:[keyNum intValue]];
    
    SimpleViewController *simple = [[SimpleViewController alloc] init];
    [self.navigationController pushViewController:simple animated:YES];
    [simple release];
    
}

@end
