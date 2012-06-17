//
//  AppDelegate.m
//  ActionLog
//
//  Created by dstutzman on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import <Carbon/Carbon.h>
#import "ActionLogController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize alarmWindow = _alarmWindow;
@synthesize alarmTimer = _alarmTimer;

BOOL doesWindowHaveFocus = NO;

- (void)dealloc {
    [super dealloc];
}

static OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    AppDelegate* me = (AppDelegate*)userData;
    
    if ([me.window isVisible] && doesWindowHaveFocus) { 
        [me.window orderOut:me]; 
    } else { 
        [me.window makeKeyAndOrderFront:me]; 
        [NSApp activateIgnoringOtherApps:YES];
        [((ActionLogController*)me.viewController) loadThePage];
    }
    
    return noErr;
}

- (void)registerHotKey {
    EventHotKeyRef gMyHotKeyRef;
    EventHotKeyID gMyHotKeyID;
    EventTypeSpec eventType;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    InstallApplicationEventHandler(&MyHotKeyHandler,1,&eventType,self,NULL);
    gMyHotKeyID.signature='htk1';
    gMyHotKeyID.id=1;
    int aKey = 0; // 0 means the A key
    RegisterEventHotKey(aKey, controlKey + shiftKey, gMyHotKeyID,
        GetApplicationEventTarget(), 0, &gMyHotKeyRef);
}

- (void)noticeActiveInactiveChange {
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(didBecomeActive:) 
        name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector(didBecomeInactive:) 
        name:NSApplicationDidResignActiveNotification object:nil];
}

- (void)timerFireMethod:(NSTimer*)theTimer {
    NSLog(@"timerFireMethod");
    [self.alarmWindow orderFront:self];
}

- (void)scheduleAlarms {
    NSDateComponents *nowComponents = [[NSCalendar currentCalendar] components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit fromDate:[NSDate date]];
    NSDateComponents *thenComponents = [[NSDateComponents alloc] init];
    thenComponents.year = nowComponents.year;
    thenComponents.month = nowComponents.month;
    thenComponents.day = nowComponents.day;
    thenComponents.hour = 17;
    thenComponents.minute = 0;
    thenComponents.second = 0;
    NSDate* date = [[NSCalendar currentCalendar] dateFromComponents:thenComponents];
    if ([date compare:[NSDate date]] == NSOrderedAscending) {
        date = [date dateByAddingTimeInterval:(24 * 60 * 60)];
    }

    NSTimeInterval everyDay = 24 * 60 * 60;
    self.alarmTimer = [[NSTimer alloc] initWithFireDate:date interval:everyDay target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.alarmTimer forMode:NSDefaultRunLoopMode];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.viewController = [[ActionLogController alloc] initWithNibName:@"ActionLogController" bundle:nil];
    self.viewController.appDelegate = self;
    self.window.contentView = self.viewController.view;
	[self.alarmWindow setReleasedWhenClosed:FALSE];
    
    [self registerHotKey];
    [self noticeActiveInactiveChange];
    [self scheduleAlarms];
}

- (void)didBecomeActive:(id)sender {
    NSLog(@"didBecomeActive");
    doesWindowHaveFocus = YES;
}

- (void)didBecomeInactive:(id)sender {
    NSLog(@"didBecomeInactive");
    doesWindowHaveFocus = NO;
}

-(void)closeThing {
    [self.window orderOut:self];
}

@end
