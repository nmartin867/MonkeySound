//
//  MSFirstViewController.m
//  MonkeySound
//
//  Created by Nick Martin on 8/9/14.
//  Copyright (c) 2014 com.buggylist. All rights reserved.
//

#import "MSFirstViewController.h"
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAudioSettings.h>
#import <AVFoundation/AVAudioRecorder.h>
#import <AVFoundation/AVAudioPlayer.h>

@interface MSFirstViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property bool recording;
@property (nonatomic, strong) NSMutableDictionary *recordSetting;
@property (nonatomic, strong) NSString *recorderFilePath;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSMutableDictionary *editedObject;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation MSFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	if(!_editedObject || ![_editedObject valueForKey:@"editedFieldKey"]){
        _playBtn.hidden = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (IBAction)toggleRecording:(id)sender {
    _recording = !_recording;
    if(_recording){
        [self startRecording];
    }else{
        [self stopRecording];
    }
    
}
- (IBAction)playBtn:(id)sender {
    [self playRecording];
}

- (void)startRecording{
    [self.recordBtn setTitle:@"STOP" forState:UIControlStateNormal];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    [audioSession setActive:YES error:&err];
    err = nil;
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        return;
    }
    
    _recordSetting = [NSMutableDictionary new];
    
    [_recordSetting setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [_recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [_recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    [_recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [_recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [_recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    
    
    
    // Create a new dated file
    NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
    NSString *caldate = [now description];
    _recorderFilePath = [NSString stringWithFormat:@"%@/%@.caf", [self applicationDocumentsDirectory], caldate];
    
    NSURL *url = [NSURL fileURLWithPath:_recorderFilePath];
    err = nil;
    _recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:_recordSetting error:&err];
    if(!_recorder){
        NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: [err localizedDescription]
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //prepare to record
    _recorder.delegate = self;
    [_recorder prepareToRecord];
    _recorder.meteringEnabled = YES;
    
    if (!audioSession.inputAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: @"Audio input hardware not available"
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [cantRecordAlert show];
        return;
    }
    
    // start recording
    [_recorder recordForDuration:(NSTimeInterval) 10];
}
- (void)stopRecording{
    [self.recordBtn setTitle:@"RECORD" forState:UIControlStateNormal];
    [_recorder stop];
    NSURL *url = [NSURL fileURLWithPath: _recorderFilePath];
    NSError *err = nil;
    NSData *audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
    if(!audioData){
      NSLog(@"audio data: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
    }
    //Store audio data in memory
    _editedObject = [[NSMutableDictionary alloc]initWithDictionary:@{@"editedFieldKey": audioData}];
    
    //Delete audio file from disk
    NSFileManager *fm = [NSFileManager defaultManager];
    err = nil;
    [fm removeItemAtPath:[url path] error:&err];
    if(err){
        NSLog(@"File Manager: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
    }else{
        _playBtn.hidden = NO;
    }
}

-(void)playRecording{
    if(!_player){
        NSError *err;
        NSLog(@"%@", [_editedObject[@"editedFieldKey"] class]);
        _player = [[AVAudioPlayer alloc]initWithData:_editedObject[@"editedFieldKey"] error:&err];
        _player.delegate = self;
        [_player play];
    }
}

#pragma mark - AVRecorder

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    NSLog(@"Recording complete");
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error{
    NSLog(@"Recorder Error.");
}

#pragma mark - AVAudioPlayer

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    NSLog(@"PLAYER:Decoding Error.");
}
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"Playback complete.");
}
@end
