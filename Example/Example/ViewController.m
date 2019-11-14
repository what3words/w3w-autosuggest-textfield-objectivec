//
//  ViewController.m
//  Example
//
//  Created by Lshiva on 09/08/2019.
//  Copyright © 2019 what3words. All rights reserved.
//

#import "ViewController.h"
#import "W3wTextField.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet W3wTextField *suggestion;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.suggestion setAPIKey:@"<Secret API Key>"];
    
    [self.suggestion didSelect:^(NSString *selectedText) {
      NSLog(@"Three word address: %@", selectedText);
    }];
    
}


@end
