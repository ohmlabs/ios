//
//	ABSTRACT:
//	Demonstrates how to use the ZtxRetune API to do pitch correction on a vocal file
//
//
//  iPhoneTestAppDelegate.m
//  iPhoneTest
//

#include "ZTX.h"
#include <stdio.h>
#include <sys/time.h>

#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "iPhoneTestAppDelegate.h"
#import "EAFRead.h"
#import "EAFWrite.h"
#import "Utilities.h"

double gExecTimeTotal = 0.;


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


@implementation iPhoneTestAppDelegate 

@synthesize window;
@synthesize reader;

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-(void)playOnMainThread:(id)param
{
	NSError *error = nil;
	[text setText:@"Now Playing..."];
	player = [[AVAudioPlayer alloc] initWithContentsOfURL:outUrl error:&error];
	if (error)
		NSLog(@"AVAudioPlayer error %@, %@", error, [error userInfo]);
	
	player.delegate = self;
	[player play];
}

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-(void)updateBarOnMainThread:(id)param
{
	[progressView setProgress:(percent/100.f)];
}


//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-(void)processThread:(id)param
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[text setText:@"Processing..."];
	[version setText:[NSString stringWithFormat:@"ZtxRetune Example\nZTX Version: %s", ZtxVersion()]];
    [window makeKeyAndVisible];

	long numChannels = 1;		// ZtxRetune allows mono only

	// open input file
	[reader openFileForRead:inUrl sr:44100. channels:numChannels];
	
	// create output file (overwrite if exists)
	[writer openFileForWrite:outUrl sr:44100. channels:numChannels wordLength:16 type:kAudioFileAIFFType];	
	
	// First we set up a retune instance at 44.1kHz
	void *ztxRetune = ZtxRetuneCreate(kZtxQualityBest, 44100., 440.);
	if (!ztxRetune) {
		printf("!! ERROR !!\n\n\tCould not create ZtxRetune instance\n\tCheck sample rate!\n");
		exit(-1);
	}
	
	ZtxRetuneSetProperties(100.	/* correctionAmountPercent */, 
							 0		/* correctionCaptureCent*/, 
							 100	/* correctionAutoBypassThreshold */, 
							 .2		/* correctionAmbienceThreshold */, 
							 ztxRetune);
	
	
	NSLog(@"Running ZTX version %s\nStarting processing", ZtxVersion());
	
	// Get the number of frames from the file to display our simplistic progress bar
	SInt64 numf = [reader fileNumFrames];
	SInt64 outframes = 0;
	long lastPercent = -1;
	percent = 0;
	
	// This is an arbitrary number of frames per call. Change as you see fit
	long numFrames = 8192;
	
	// Allocate buffers
	AUDIO **audioIn = AllocateAudioBufferSInt16(numChannels, numFrames);
	AUDIO **audioOut = AllocateAudioBufferSInt16(numChannels, numFrames);

	double bavg = 0;
	
	// MAIN PROCESSING LOOP STARTS HERE
	for(;;) {
		
		// Display ASCII style "progress bar"
		percent = 100.f*(double)outframes / (double)numf;
		long ipercent = percent;
		if (lastPercent != percent) {
			[self performSelectorOnMainThread:@selector(updateBarOnMainThread:) withObject:self waitUntilDone:NO];
			printf("\rProgress: %3i%% [%-40s] ", ipercent, &"||||||||||||||||||||||||||||||||||||||||"[40 - ((ipercent>100)?40:(2*ipercent/5))] );
			lastPercent = ipercent;
			fflush(stdout);
		}
		
#ifdef REQUIRES_AUDIO_CONVERSION
		long ret = [reader readSInt16Consecutive:numFrames intoArray:audioIn];
#else
		long ret = [reader readFloatsConsecutive:numFrames intoArray:audioIn];
#endif
		
		ZtxStartClock();								// ............................. start timer ..........................................
		
		ZtxRetuneProcess(audioIn[0], audioOut[0], numFrames, ztxRetune);
		bavg += (numFrames/44100.);
		gExecTimeTotal += ZtxClockTimeSeconds();		// ............................. stop timer ..........................................
		
		printf("x realtime: %3.3f : 1\n", bavg/gExecTimeTotal);
		printf("\t\t\tDetected pitch = %3.3f Hz\n", ZtxRetuneGetPitchHz(ztxRetune));
		
		// Process only as many frames as needed
		long framesToWrite = numFrames;
		unsigned long nextWrite = outframes + numFrames;
		if (nextWrite > numf) framesToWrite = numFrames - nextWrite + numf;
		if (framesToWrite < 0) framesToWrite = 0;
		
		// Write the data to the output file
#ifdef REQUIRES_AUDIO_CONVERSION
		[writer writeShorts:framesToWrite fromArray:audioOut];
#else
		[writer writeFloats:framesToWrite fromArray:audioOut];
#endif
		// Increase our counter for the progress bar
		outframes += numFrames;
		
		// As soon as we've written enough frames we exit the main loop
		if (ret <= 0) break;
	}
	
	percent = 100;
	[self performSelectorOnMainThread:@selector(updateBarOnMainThread:) withObject:self waitUntilDone:NO];

	
	// Free buffer for output
	DeallocateAudioBuffer(audioIn, numChannels);	
	DeallocateAudioBuffer(audioOut, numChannels);	
	
	// destroy ZTX instance
	ZtxRetuneDestroy( ztxRetune );
	
	// Done!
	NSLog(@"\nDone!");
	
	[reader release];
	[writer release]; // important - flushes data to file
	
	// start playback on main thread
	[self performSelectorOnMainThread:@selector(playOnMainThread:) withObject:self waitUntilDone:NO];
	
	[pool release];
}

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// done playing? exit
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
	exit(0);
}
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{    
	NSString *inputSound  = [[NSBundle mainBundle] pathForResource:  @"voice" ofType: @"aif"];
	NSString *outputSound = [[NSHomeDirectory() stringByAppendingString:@"/Documents/"] stringByAppendingString:@"out.aif"];
	inUrl = [[NSURL fileURLWithPath:inputSound] retain];
	outUrl = [[NSURL fileURLWithPath:outputSound] retain];
	reader = [[EAFRead alloc] init];
	writer = [[EAFWrite alloc] init];

	// this thread does the processing
	[NSThread detachNewThreadSelector:@selector(processThread:) toTarget:self withObject:nil];
}

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- (void)dealloc 
{
	[player release];
    [window release];
	[inUrl release];
	[outUrl release];

    [super dealloc];
}

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

@end
