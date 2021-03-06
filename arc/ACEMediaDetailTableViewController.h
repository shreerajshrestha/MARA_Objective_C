//
//  ACEMediaDetailTableViewController.h
//  arc
//
//  Created by Shree Raj Shrestha on 7/30/14.
//  Copyright (c) 2014 Shree Raj Shrestha. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "FDWaveformView.h"
#import "AppDelegate.h"

@interface ACEMediaDetailTableViewController : UITableViewController
<AVAudioPlayerDelegate, FDWaveformViewDelegate>

@property (strong, nonatomic) IBOutlet FDWaveformView *preview;
@property (strong, nonatomic) IBOutlet UIImageView *imagePreview;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) IBOutlet UITextView *tagsTextView;
@property (strong, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizer;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *uploadButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *publishButton;

@property (strong, nonatomic) NSManagedObject *mediaDetail;
@property (strong, nonatomic) NSTimer *timer;
@property int mediaType;
@property BOOL initplayer;
@property BOOL uploadSuccess;

- (IBAction)previewTouched:(UITapGestureRecognizer *)sender;
- (IBAction)backButtonTapped:(UIBarButtonItem *)sender;
- (IBAction)editButtonTapped:(UIBarButtonItem *)sender;
- (IBAction)uploadButtonTapped:(UIBarButtonItem *)sender;
- (IBAction)publishButtonTapped:(UIBarButtonItem *)sender;

@end
