//
//  ModalViewController.m
//  AdViewSDK_Sample
//
//  Copyright 2010 www.adview.cn All rights reserved.
//

#import "ModalViewController.h"


@implementation ModalViewController

- (id)init {
  if (self = [super initWithNibName:@"ModalViewController" bundle:nil]) {
    self.title = @"Modal View";
    if ([self respondsToSelector:@selector(setModalTransitionStyle)]) {
      [self setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    }
  }
  return self;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

- (IBAction)dismiss:(id)sender {
#ifdef __IPHONE_6_0
  [self dismissViewControllerAnimated:YES completion:nil];
#else
  [self dismissModalViewControllerAnimated:YES];
#endif
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [super dealloc];
}


@end
