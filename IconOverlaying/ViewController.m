//
//  ViewController.m
//  IconOverlaying
//
//  Created by Krzysztof Zabłocki on 07/03/2013.
//  Copyright (c) 2013 pixle. All rights reserved.
//

#import "ViewController.h"
#import "NSBundle+Info.h"

@interface ViewController ()
@property (nonatomic, strong, nullable) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong, nullable) IBOutlet UILabel *buildLabel;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSBundle *bundle = NSBundle.mainBundle;

    self.versionLabel.text = [NSString stringWithFormat:@"Version %@", bundle.version];
    self.buildLabel.text = [NSString stringWithFormat:@"Build %@", bundle.build];
}

@end
