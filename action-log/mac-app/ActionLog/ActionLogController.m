//
//  ActionLogController.m
//  ActionLog
//
//  Created by dstutzman on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ActionLogController.h"
#import <WebKit/WebView.h>
#import <WebKit/WebKit.h>


@implementation ActionLogController

@synthesize appDelegate = _appDelegate;
@synthesize webView = _webView;
@synthesize reloadButton = _reloadButton;
@synthesize progressIndicator = _progressIndicator;

- (void)loadThePage
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:2999/"]];
    WebFrame* frame = [self.webView mainFrame];
    [frame loadRequest:request];
    [self.progressIndicator startAnimation:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.webView.frameLoadDelegate = self;
    [self.webView setUIDelegate: self];
    [self.webView setResourceLoadDelegate: self];

    [self.progressIndicator setDisplayedWhenStopped:NO];
    [self loadThePage];
   
}

- (IBAction) reloadButtonClicked:(id)sender {
    [self loadThePage];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:frame {
    [self.progressIndicator stopAnimation:self];

    NSScrollView* scrollView = [[[[self.webView mainFrame] frameView] documentView] enclosingScrollView];
    [[scrollView documentView] scrollPoint:NSMakePoint(0, 99999)];
}

- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
//    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    [windowScriptObject setValue:self forKey:@"ActionLogController"];    
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
    return NO;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
    return NO;
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message {
    NSLog(@"%@ received %@ with '%@'", self, NSStringFromSelector(_cmd), message);
}

- (void)hideWindow {
    [self.appDelegate closeThing];
}

@end
