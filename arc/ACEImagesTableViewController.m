//
//  ACEImagesTableViewController.m
//  arc
//
//  Created by Shree Raj Shrestha on 7/7/14.
//  Copyright (c) 2014 Shree Raj Shrestha. All rights reserved.
//

#import "ACEImagesTableViewController.h"
#import "ACEMediaDetailTableViewController.h"

@interface ACEImagesTableViewController ()
<UISearchBarDelegate, UISearchDisplayDelegate>

@end

@implementation ACEImagesTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //Reloading the table data
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ImageDB"];
    self.mediaDetails = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)filterContentForSearchText:(NSString*)searchText scope:(int)scope
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.managedObjectContext)
    {
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        NSString *predicateFormat = @"%K contains[cd] %@";
        NSString *searchAttribute = @"name";
        
        if (scope  == 1)
        {
            searchAttribute = @"tags";
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchAttribute, searchText];
        [_searchFetchRequest setPredicate:predicate];
        
        NSArray *searchResultsStatic = [context executeFetchRequest:self.searchFetchRequest error:nil];
        
        _searchResults = [NSMutableArray arrayWithArray:searchResultsStatic];
    }
}

- (NSFetchRequest *)searchFetchRequest
{
    if (_searchFetchRequest != nil)
    {
        return _searchFetchRequest;
    }
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    
    _searchFetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ImageDB" inManagedObjectContext:context];
    [_searchFetchRequest setEntity:entity];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    [_searchFetchRequest setSortDescriptors:sortDescriptors];
    
    return _searchFetchRequest;
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
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [_searchResults count];
    } else {
        return [_mediaDetails count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ImageCell"
                                                                  forIndexPath:indexPath];
    
    NSManagedObject *mediaDetail = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        mediaDetail = [_searchResults objectAtIndex:indexPath.row];
    } else {
        mediaDetail = [_mediaDetails objectAtIndex:indexPath.row];
    }
    
    // Setting preview image
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pathComponent = [NSString stringWithFormat:@"/MyImages/%@", [mediaDetail valueForKey:@"fileName"]];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:pathComponent];
    
    // Configuring the cell
    UIImageView *thumbView = (UIImageView *)[cell viewWithTag:100];
    UILabel *nameLabel = (UILabel *)[cell viewWithTag:101];
    UILabel *tagsLabel = (UILabel *)[cell viewWithTag:102];
    
    thumbView.image = [UIImage imageWithContentsOfFile:filePath];
    nameLabel.text = [mediaDetail valueForKey:@"name"];
    tagsLabel.text = [mediaDetail valueForKey:@"tags"];
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *currentArray = [[NSMutableArray alloc] init];
    
    // Selecting the current array according to table type
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        currentArray = _searchResults;
    } else {
        currentArray = _mediaDetails;
    }
    
    // Delete file from the documents directory
    NSManagedObject *mediaDetail = [currentArray objectAtIndex:indexPath.row];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pathComponent = [NSString stringWithFormat:@"/MyImages/%@", [mediaDetail valueForKey:@"fileName"]];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:pathComponent];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
    // Delete object from database
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    [context deleteObject:[currentArray objectAtIndex:indexPath.row]];
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Cannot delete %@ %@", error, [error localizedDescription]);
        return;
    }
    
    // Remove device details from the array
    [currentArray removeObjectAtIndex:indexPath.row];
    
    // Remove device details from the corresponding search table
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.searchDisplayController.searchResultsTableView reloadData];
        
        // Reloading the main table data
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"ImageDB"];
        self.mediaDetails = [[context executeFetchRequest:fetchRequest error:nil] mutableCopy];
        [self.tableView reloadData];
        
    } else {
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadData];
    }
}

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    // Checking if the segue is the one to detail view
    if ([segue.identifier isEqualToString:@"showImageDetail"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ACEMediaDetailTableViewController *destViewController = [[segue destinationViewController] topViewController];
        
        // Sending the appropriate media detail for the corresponding sender table
        if([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *currentCell = (UITableViewCell *)sender;
            if (currentCell.superview.superview == self.searchDisplayController.searchResultsTableView) {
                destViewController.mediaDetail = [_searchResults objectAtIndex:indexPath.row];
            } else {
                destViewController.mediaDetail = [_mediaDetails objectAtIndex:indexPath.row];
            }
        }
        
        destViewController.mediaType = 1;
    }
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.rowHeight = 60;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:(int)controller.searchBar.selectedScopeButtonIndex];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    NSString *searchString = controller.searchBar.text;
    [self filterContentForSearchText:searchString scope:(int)searchOption];
    return YES;
}

@end
