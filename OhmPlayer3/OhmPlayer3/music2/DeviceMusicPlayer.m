//
//  DeviceMusicPlayer.m
//
//  Copyright (c) 2011 Ohm Labs. All rights reserved.
//

#import "DeviceMusicPlayer.h"

#import <MediaPlayer/MediaPlayer.h>

#import "SongCollection.h"
#import "DeviceSong.h"

@interface DeviceMusicPlayer (ForwardDeclarations)

- (MPMusicPlayerController*) musicPlayer;
- (void) synchToPlaylist;

@end


@implementation DeviceMusicPlayer

#pragma mark Properties - MusicPlayer

- (BOOL) isPlaying
{
	return ([[self musicPlayer] playbackState] == MPMusicPlaybackStatePlaying);
}

- (BOOL) isStopped
{
	return ([[self musicPlayer] playbackState] == MPMusicPlaybackStateStopped);
}

- (NSUInteger) countOfSongsInQueue
{
	return [previousCollectionMediaItems count];
}

- (NSUInteger) indexOfNowPlayingSong
{
	return [self musicPlayer].indexOfNowPlayingItem;
}

- (Song*) nowPlayingSong
{
	MPMediaItem* nowPlayingItem = [self musicPlayer].nowPlayingItem;
	
	if (nowPlayingItem)
	{
		return [[DeviceSong alloc] initWithMediaItem:nowPlayingItem];
	}
	
	return nil;
}

- (void) setNowPlayingSong:(Song*)song
{
	[self musicPlayer].nowPlayingItem = ((DeviceSong*)song).mediaItem;
}

- (MPMusicShuffleMode) shuffleMode
{
    return [self musicPlayer].shuffleMode;
}

- (void) setShuffleMode:(MPMusicShuffleMode)inMode
{
    [self musicPlayer].shuffleMode = inMode;
}

#pragma mark Protected Methods

- (MPMusicPlayerController*) musicPlayer
{	
	if (!player)
	{
		player = [MPMusicPlayerController iPodMusicPlayer];
		
		[player beginGeneratingPlaybackNotifications];
	}
	
	return player;
}

- (NSArray*) mediaItemsFromSongCollection:(NSObject<SongCollection>*)collection
{
	return (collection) ? [[collection songCollection] items] : [NSArray array];
}

- (void) internal_setQueueWithItemCollection:(NSObject<SongCollection>*)collection
{
	currentSongCollection = collection;
	
	// The player remembers collection items so it can later (in synchToPlaylist) detect
	// if the collection has been modified.
	
	MPMediaItemCollection* itemCollection = [collection songCollection];
	
	previousCollectionMediaItems = [[itemCollection items] copy];
	
//    NSLog(@"Setting the music player queue to %@", itemCollection);
//    NSLog(@"Items in queue: %@", [itemCollection items]);
    
	[[self musicPlayer]	setQueueWithItemCollection:itemCollection];

}

- (void) setQueueWithItemCollection:(NSObject<SongCollection>*)collection
{
    // Note: object equality is not sufficient to tell if a collection
    // has been internally reordered.
    
	//if (currentSongCollection != collection)
	{		
		[self internal_setQueueWithItemCollection:collection];

        //    [self synchToPlaylist];
    }
}

- (NSTimeInterval) currentPlaybackTime
{
	return [[self musicPlayer] currentPlaybackTime];
}

- (void) setCurrentPlaybackTime:(NSTimeInterval)currentPlaybackTime
{
	[self musicPlayer].currentPlaybackTime = currentPlaybackTime;
}

- (void) updateMusicQueue
{	
	if (currentSongCollection)
	{
		Song* nowPlayingSong = [self nowPlayingSong];
		
		const NSTimeInterval currentPlaybackTime = [self currentPlaybackTime];
	
		[self internal_setQueueWithItemCollection:currentSongCollection];
		
		[self setNowPlayingSong:nowPlayingSong];
		
		[self setCurrentPlaybackTime:currentPlaybackTime];
		
		[self play];
	}
}

- (void) synchToPlaylist
{	
	NSArray* currentMediaItems = [self mediaItemsFromSongCollection:currentSongCollection];
	
	if (![previousCollectionMediaItems isEqualToArray:currentMediaItems])
	{
		// The current media items have changed since the queue/collection was last set. Update it.
		
		[self updateMusicQueue];
	}

}

#pragma mark Notification - Handlers

- (void) handleNowPlayingItemDidChangeNotification:(NSNotification*)note
{
	[self synchToPlaylist];
}

#pragma mark Notification - Registration

- (void) registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(handleNowPlayingItemDidChangeNotification:)
												 name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
											   object:nil];
}

- (void) unregisterForNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Public Methods

- (BOOL) isPlayingSong:(Song*)aSong
{
	NSNumber* nowPlayingID	= [[self musicPlayer].nowPlayingItem valueForProperty:MPMediaItemPropertyPersistentID];
	NSNumber* songID		= [aSong identifier];
	
	return (nowPlayingID && songID) ? [nowPlayingID isEqualToNumber:songID] : NO;
}

- (void) playSong:(Song*)song inCollection:(NSObject<SongCollection>*)collection
{	
	NSParameterAssert(collection);
	NSParameterAssert(song);
	
	[self setQueueWithItemCollection:collection];
	
	[self setNowPlayingSong:song];
	
	[self play];
}

- (void) playSongCollection:(NSObject<SongCollection>*)collection
{
	[self setQueueWithItemCollection:collection];
		
	[self play];
}

- (void) play
{
    [self synchToPlaylist];
	[[self musicPlayer] play];
}

- (void) pause
{
    [self synchToPlaylist];
	[[self musicPlayer] pause];
}

- (void) stop
{
    [self synchToPlaylist];
	[[self musicPlayer] stop];
}

- (void)skipToNextItem
{
    [self synchToPlaylist];
	[[self musicPlayer] skipToNextItem];
}

- (void)skipToPreviousItem
{
    [self synchToPlaylist];
	[[self musicPlayer] skipToPreviousItem];
}

- (void) shuffle:(MPMusicShuffleMode)mode
{
    [self synchToPlaylist];
	[self musicPlayer].shuffleMode = mode;
}

#pragma mark Object Life Cycle

- (id)init
{
    self = [super init];
    if (self)
	{
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc
{	
    [player endGeneratingPlaybackNotifications], player = nil;

	[self unregisterForNotifications];
}

+ (MusicPlayer*) sharedInstance
{
	static id sharedInstance = nil;
	
    if (sharedInstance) return sharedInstance;
    
	@synchronized (self)
    {
        if (!sharedInstance)
        {
            sharedInstance = (MusicPlayer*)[[DeviceMusicPlayer alloc] init];
        }
    }
    
	return sharedInstance;
}

@end
