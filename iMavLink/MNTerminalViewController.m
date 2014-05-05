//
//  MNFirstViewController.m
//  iMavLink
//
//  Created by James Adams on 5/5/14.
//  Copyright (c) 2014 James Adams. All rights reserved.
//

#import "MNTerminalViewController.h"
#import "GCDAsyncSocket.h"

#define HOST @"198.18.0.1"
#define HOST_PORT 2000

@interface MNTerminalViewController ()

- (void)connectTo3DRRadio;
- (void)updateConnectButton;
- (void)scrollTerminalTextViewToBottom;

@end


@implementation MNTerminalViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
	self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions

- (IBAction)connectDisconnectButtonPress:(id)sender
{
    if(self.connected)
    {
        [self.socket disconnect];
    }
    else
    {
        [self connectTo3DRRadio];
    }
}

#pragma mark - Private Methods

- (void)connectTo3DRRadio
{
    NSString *host = HOST;
    uint16_t hostPort = HOST_PORT;
    
    NSLog(@"Connecting to \"%@\" on port %hu...", host, hostPort);
    self.statusLabel.text = @"Connecting...";
    [self.connectDisconnectButton setTitle:@"Stop" forState:UIControlStateNormal];
    NSError *error = nil;
    if (![self.socket connectToHost:host onPort:hostPort error:&error])
    {
        NSLog(@"Error connecting: %@", error);
        self.statusLabel.text = @"Oops";
        self.connected = NO;
    }
    else
    {
        [self.socket readDataWithTimeout:-1 tag:0];
        self.connected = YES;
    }
}

- (void)updateConnectButton
{
    if(self.connected)
    {
        [self.connectDisconnectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    }
    else
    {
        [self.connectDisconnectButton setTitle:@"Connect" forState:UIControlStateNormal];
    }
}

- (void)scrollTerminalTextViewToBottom
{
    // Scroll to the bottom
    if(self.terminalTextView.text.length > 0 )
    {
        [self.terminalTextView scrollRangeToVisible:NSMakeRange(self.terminalTextView.text.length, 0)];
        // This is a hack for iOS 7
        [self.terminalTextView setScrollEnabled:NO];
        [self.terminalTextView setScrollEnabled:YES];
    }
}

// Defaults to black
- (void)writeStringToConsole:(NSString *)string color:(UIColor *)color
{
    if(color == nil)
    {
        color = [UIColor blackColor];
    }
    
    // Print the string to the 'console'
    NSRange endOfLineRange = [string rangeOfString:@"\n"];
    //each message appears on new line
    NSString *appendString = (endOfLineRange.location == NSNotFound ? @"\n" : @"");
    NSAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", string, appendString] attributes: @{NSForegroundColorAttributeName : color}];
    NSMutableAttributedString *newASCIIText = [[NSMutableAttributedString alloc] initWithAttributedString:self.terminalTextView.attributedText];
    [newASCIIText appendAttributedString:attrString];
    self.terminalTextView.attributedText = newASCIIText;
    
    // Scroll the textView
    [self scrollTerminalTextViewToBottom];
}

#pragma mark - Socket Delegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"didConnectToHost:%@ port:%hu", host, port);
	self.statusLabel.text = @"Connected";
    self.connected = YES;
    [self updateConnectButton];
}

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    NSLog(@"didAcceptNewSocket:%@", newSocket);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	//NSLog(@"didWriteDataWithTag:%ld", tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	//NSLog(@"didReadData:%@ withTag:%ld", [data description], tag);
    
    /*
     // MAVLink packeet description
     message length = 17 (6 bytes header + 9 bytes payload + 2 bytes checksum)
     ￼￼
     6 bytes header
     
     0. message header, always 0xFE
     1. message length (9)
     2. sequence number -- rolls around from 255 to 0 (0x4e, previous was 0x4d)
     3. System ID - what system is sending this message (1)
     4. Component ID- what component of the system is sending the message (1)
     5. Message ID (e.g. 0 = heartbeat and many more! Don’t be shy, you can add too..)
     
     Variable Sized Payload (specified in octet 1, range 0..255) ** Payload (the actual data we are interested in)
     
     Checksum: For error detection.*/
    
    NSUInteger dataLength = [data length];
    NSMutableString *string = [NSMutableString stringWithCapacity:dataLength*2];
    const unsigned char *dataBytes = [data bytes];
    for (NSInteger idx = 0; idx < dataLength; ++idx)
    {
        [string appendFormat:@"0x%02x ", dataBytes[idx]];
    }
    [string appendString:@"\n\n"];
    NSLog(@"Response:%@", string);
    
    [self writeStringToConsole:string color:nil];
    
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    NSLog(@"didReadPartialData:withTag:%ld", tag);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	NSLog(@"DidDisconnectWithError: %@", err);
    self.statusLabel.text = @"Disconnected";
    self.connected = NO;
    [self updateConnectButton];
}

@end