//
//  SearchResultsTableViewDataSource.h
//  OhmPlayer3
//
//  Copyright (c) 2012 Ohm Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MusicLibrary.h"

@interface SearchResultsTableViewDataSource : NSObject<UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>
{    
    NSMutableDictionary*    searchResults;
	NSMutableDictionary*    imageCache;
}

- (Artist*) artistResultForIndexPath:(NSIndexPath*)indexPath;
- (Album*) albumResultForIndexPath:(NSIndexPath*)indexPath;
- (MusicLibrarySong*) songResultForIndexPath:(NSIndexPath*)indexPath;
- (NSString*) sectionNameForIndexPath:(NSIndexPath*)indexPath;

extern NSString* const SEARCH_RESULTS_CELL_REUSE_ID_ARTISTS;
extern NSString* const SEARCH_RESULTS_CELL_REUSE_ID_ALBUMS;
extern NSString* const SEARCH_RESULTS_CELL_REUSE_ID_SONGS;
extern NSString* const SEARCH_RESULTS_KEY_ARTISTS;
extern NSString* const SEARCH_RESULTS_KEY_ALBUMS;
extern NSString* const SEARCH_RESULTS_KEY_SONGS;

@end
