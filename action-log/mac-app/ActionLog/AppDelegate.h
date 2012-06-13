//
//  AppDelegate.h
//  ActionLog
//
//  Created by dstutzman on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActionLogController.h"
#import "ClosableThing.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, ClosableThing>

@property (assign) IBOutlet NSWindow *window;
@property (assign) ActionLogController *viewController;

- (void)closeThing;
- (void)didBecomeActive:(id)sender;
- (void)didBecomeInactive:(id)sender;

@end
