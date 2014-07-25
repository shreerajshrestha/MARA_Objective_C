//
//  ACERecorderWindowViewController.m
//  arc
//
//  Created by Shree Raj Shrestha on 6/20/14.
//  Copyright (c) 2014 Shree Raj Shrestha. All rights reserved.
//

#import "ACERecorderWindowViewController.h"

@interface ACERecorderWindowViewController () {
    AVAudioPlayer *audioPlayer;
}

@end

@implementation ACERecorderWindowViewController {
    CLLocationManager *locationManager;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
    // Do any additional setup after loading the view.
    
    // Creating the temp audio file url
    NSArray *tempFilePathComponents = [NSArray arrayWithObjects:
                                       NSTemporaryDirectory(),
                                       @"tempAudio.m4a",
                                       nil];
    _tempURL = [NSURL fileURLWithPathComponents:tempFilePathComponents];
    
    // Initializing the location manager and
    locationManager = [[CLLocationManager alloc] init];
    _gotLocation = NO;
    
    // Delegating the text fields
    self.saveAsTextField.delegate = self;
    self.tagsTextField.delegate = self;
    self.descriptionTextField.delegate = self;
    
    ACERecorderViewController *recorderDelegate = [[ACERecorderViewController alloc] init];
    recorderDelegate.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)getLocationDataButtonTapped:(UIButton *)sender
{
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager startUpdatingLocation];
}

- (IBAction)saveRecordingButtonTapped:(UIButton *)sender
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Validate required fields
    if ([_saveAsTextField.text  isEqual: @""] || _gotLocation == NO ) {
        
        UIAlertView *alertMessage = [[UIAlertView alloc]
                                     initWithTitle:@"Nothing Saved!"
                                     message:@"Please add media, enter the required fields and update location."
                                     delegate:nil
                                     cancelButtonTitle:@"OK"
                                     otherButtonTitles:nil, nil];
        
        [alertMessage show];
        
    } else {
        
        // Start animation
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinner setCenter:CGPointMake(160,500)];
        [self.view addSubview:spinner];
        [spinner startAnimating];
        
        // Copying file from temp to documents directory
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/MyAudios"];
        
        if (![fileManager fileExistsAtPath:dataPath])
            [fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:nil];
        
        BOOL fileExists = NO;
        NSString *saveName = @"";
        NSURL *saveURL = [[NSURL alloc] init];
        
        do {
            int randomID = arc4random() % 9999999;
            saveName = [NSString stringWithFormat:@"%@%d.m4a",
                                  [_saveAsTextField.text stringByReplacingOccurrencesOfString:@" " withString:@""],
                                  randomID];
            NSArray *saveFilePathComponents = [NSArray arrayWithObjects:
                                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                               @"/MyAudios/",
                                               saveName, nil];
            
            saveURL = [NSURL fileURLWithPathComponents:saveFilePathComponents];
            fileExists = [fileManager fileExistsAtPath:[saveURL path]];
        } while (fileExists == YES);
        
        [fileManager copyItemAtURL:_tempURL toURL:saveURL error:nil];
        
        // Formatting date
        NSDate *now = [[NSDate alloc] init];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MM/dd/yyyy HH:mm"];
        NSString *date = [formatter stringFromDate:now];
        
        // Saving the details to core data
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        NSManagedObjectContext *context = [appDelegate managedObjectContext];
        NSManagedObject *newTagObject;
        newTagObject = [NSEntityDescription
                        insertNewObjectForEntityForName:@"AudioDB"
                        inManagedObjectContext:context];
        
        [newTagObject setValue: _saveAsTextField.text forKey:@"name"];
        [newTagObject setValue: _tagsTextField.text forKey:@"tags"];
        [newTagObject setValue: _descriptionTextField.text forKey:@"descriptor"];
        [newTagObject setValue:[NSNumber numberWithFloat:_latitude] forKey:@"latitude"];
        [newTagObject setValue:[NSNumber numberWithFloat:_longitude] forKey:@"longitude"];
        [newTagObject setValue: date forKey:@"date"];
        [newTagObject setValue: saveName forKey:@"fileName"];
        
        // Save the new TagObject to persistent store
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Save failed with error: %@ %@", error, [error localizedDescription]);
        } else {
            UIAlertView *savedMessage = [[UIAlertView alloc]
                                         initWithTitle:@""
                                         message:@"Successfully saved!"
                                         delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil, nil];
            
            [savedMessage show];
        }
        
        // Deleting the temp file if it exists
        if ([fileManager fileExistsAtPath:[_tempURL path]]) {
            [fileManager removeItemAtPath:[_tempURL path] error:nil];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)cancelButtonTapped:(UIBarButtonItem *)sender
{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Deleting the temp file
    if ([fileManager fileExistsAtPath:[_tempURL path]]) {
        [fileManager removeItemAtPath:[_tempURL path] error:nil];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Enable tags and description fields if Save As field is not empty
    if (textField == _saveAsTextField) {
        if ( [textField.text length] == 0 ) {
            _tagsTextField.enabled = NO;
            _descriptionTextField.enabled = NO;
            _getLocationDataButton.enabled = NO;
        } else {
            _tagsTextField.enabled = YES;
            _descriptionTextField.enabled = YES;
            _getLocationDataButton.enabled = YES;
        }
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.saveAsTextField || textField == self.tagsTextField || textField == self.descriptionTextField) {
        [textField resignFirstResponder];
    }
    
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

-(void) generateWaveform
{
    // Generate Waveform
    NSURL *url = _tempURL;
    self.waveform.delegate = self;
    self.waveform.alpha = 0.0f;
    self.waveform.audioURL = url;
    self.waveform.progressSamples = 0;
    self.waveform.doesAllowScrubbing = NO;
    self.waveform.doesAllowStretchAndScroll = NO;
}

- (void)updateWaveform
{
    // Animating the waveform
    [UIView animateWithDuration:0.01 animations:^{
        float currentPlayTime = audioPlayer.currentTime;
        float progressSample = ( currentPlayTime + 0.10 ) * 44100.00;
        self.waveform.progressSamples = progressSample;
    }];
}

- (IBAction)previewTouched:(UITapGestureRecognizer *)sender {
    
    if (_initplayer) {
        
        // Setting the audioPlayer
        audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_tempURL error:nil];
        [audioPlayer setDelegate:self];
        
        // Setting the timer to update waveform
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(updateWaveform) userInfo:nil repeats:YES];
        _initplayer = NO;
    }
    
    if (!audioPlayer.isPlaying) {
        [audioPlayer play];
    } else if (audioPlayer.isPlaying) {
        [audioPlayer pause];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showRecorder"]) {
        ACERecorderViewController *recorderViewController = segue.destinationViewController;
        recorderViewController.delegate = self;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    // NSLog(@"didFailWithError: %@",error);
    UIAlertView *errorAlert= [[UIAlertView alloc]
                              initWithTitle:@"Error!"
                              message:@"Failed to get your location!"
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil, nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *currentLocation = [locations lastObject];
    
    if (currentLocation != nil) {
        // Updating local latitude and longtitude
        _latitude = currentLocation.coordinate.latitude;
        _longitude = currentLocation.coordinate.longitude;
        
        // Updating latitude and longitude text fields
        _latitudeLabel.text = [NSString stringWithFormat:@"%.8f", _latitude];
        _longitudeLabel.text = [NSString stringWithFormat:@"%.8f", _longitude];
        
        _gotLocation = YES;
    }
    
    [locationManager stopUpdatingLocation];
}

#pragma mark - ACERecorderViewControllerDelegate

- (void)isFileSaved:(BOOL) saved
{
    _saveAsTextField.enabled = saved;
    _initplayer = YES;
    
    [self generateWaveform];
    NSLog(@"calld");
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [_timer invalidate];
    self.waveform.progressSamples = 0;
    _initplayer = YES;
}

#pragma mark - FDWaveformViewDelegate

- (void)waveformViewWillRender:(FDWaveformView *)waveformView
{
}

- (void)waveformViewDidRender:(FDWaveformView *)waveformView
{
    [UIView animateWithDuration:0.25f animations:^{
        waveformView.alpha = 1.0f;
    }];
}

@end