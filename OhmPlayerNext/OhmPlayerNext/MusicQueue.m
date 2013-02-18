/*
 
 MusicQueue.m
 
 DO NOT REMOVE THIS HEADER FROM THIS FILE.
 
 Ohm Labs, Inc. ("Ohm") is herby granted a world-wide, perpetual, royalty-free, non-transferable license to use this source code.
 This license header-comment must be preserved in each source file without modification. This source code may not be redistributed,
 published, or transferred without permission. Permission is herby granted to make this source code available to work-for-hire
 contractors, provided Ohm Labs, Inc. retains all rights and obligations specified by this license.
 
 Copyright 2011 Stormbring.
 
 */

#import "MusicQueue.h"

#import "OhmTargetConditionals.h"
#import "SimulatorMusicQueue.h"
#import "DeviceMusicQueue.h"

// This function returns a music queue implementation.

MusicQueue* musicQueue(void)
{
#if !OHM_TARGET_SIMULATE
	return [DeviceMusicQueue sharedInstance];
#else
	return [SimulatorMusicQueue sharedInstance];
#endif
}
