//
//  ActionLogController.h
//  ActionLog
//
//  Created by dstutzman on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebView.h>
#import "ClosableThing.h"

@interface ActionLogController : NSViewController

@property (assign) id<ClosableThing> appDelegate;
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSButton *reloadButton;
@property (assign) IBOutlet NSProgressIndicator* progressIndicator;

- (IBAction) reloadButtonClicked:(id)sender;
- (void)loadThePage;
- (void)hideWindow;

@end
