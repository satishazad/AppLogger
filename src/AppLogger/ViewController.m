//
//  ViewController.m
//  AppLogger
//
//  Created by Satish K Azad on 22/12/15.
//  Copyright © 2015 Satish K Azad. All rights reserved.
//

#import "ViewController.h"
#import "AppLogger.h"



@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	NSArray *arr = @[@"first object", @"Second Object"];

	[[AppLogger sharedLogger] logObjects:arr, nil];
	
	[[AppLogger sharedLogger] logMessage:arr.firstObject];
	
	//NSString *obj = arr[4];
	
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}





@end
