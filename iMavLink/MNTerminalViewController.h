//
//  MNFirstViewController.h
//  iMavLink
//
//  Created by James Adams on 5/5/14.
//  Copyright (c) 2014 James Adams. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCDAsyncSocket;

@interface MNTerminalViewController : UIViewController <UITextViewDelegate>

@property(strong, nonatomic) IBOutlet UITextView *terminalTextView;
@property(strong, nonatomic) IBOutlet UIButton *connectDisconnectButton;
@property(strong, nonatomic) IBOutlet UILabel *statusLabel;
@property(strong, nonatomic) IBOutlet UIButton *clearButton;

@property(strong, nonatomic) GCDAsyncSocket *socket;
@property(assign, nonatomic) BOOL connected;

- (IBAction)connectDisconnectButtonPress:(id)sender;
- (IBAction)clearButtonPress:(id)sender;

@end
