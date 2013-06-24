//
//  TestsViewController.h
//  CocoaLibSpotify iOS Library
//
//  Created by Daniel Kennett on 02/10/2012.
//
//

#import <UIKit/UIKit.h>
#import "TestRunner.h"

@interface TestsViewController : UITableViewController <TestRunnerDelegate>

@property (nonatomic, readwrite, copy) NSArray *tests;

@end
