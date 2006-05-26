/*
 
 Permission is hereby granted, free of charge, to any person obtaining a 
 copy of this software and associated documentation files (the "Software"), 
 to deal in the Software without restriction, including without limitation 
 the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 and/or sell copies of the Software, and to permit persons to whom the Software 
 is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in 
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS 
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR 
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
 AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
 WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
Please send fixes to
	<ghulands@framedphotographics.com>
	<ben@scriptsoftware.com>
 */

#import "iMBAbstractParser.h"
#import "UKKQueue.h"
#import "iMBLibraryNode.h"

@implementation iMBAbstractParser

- (id)init
{
	if (self = [super init])
	{
		
	}
	return self;
}

- (id)initWithContentsOfFile:(NSString *)file
{
	if (self = [super init])
	{
		myDatabase = [file copy];
		myFileWatcher = [[UKKQueue alloc] init];
		[myFileWatcher setDelegate:self];
		if (file)
		{
			[myFileWatcher addPath:file];
		}
	}
	return self;
}

- (void)dealloc
{
	[myFileWatcher setDelegate:nil];
	[myFileWatcher release];
	[myDatabase release];
	[myCachedLibrary release];
	[super dealloc];
}

- (iMBLibraryNode *)library
{
	if (!myCachedLibrary)
	{
		myCachedLibrary = [[self parseDatabase] retain];
	}
	return myCachedLibrary;
}

- (iMBLibraryNode *)parseDatabase
{
	// we do nothing, let the subclass do the hard yards.
	return nil;
}

- (void)setBrowser:(id <iMediaBrowser>)browser
{
	myBrowser = browser;
}

- (id <iMediaBrowser>)browser
{
	return myBrowser;
}

- (NSString *)databasePath
{
	return myDatabase;
}

- (void)watchFile:(NSString *)file
{
	[myFileWatcher addPath:file];
}

- (void)stopWatchingFile:(NSString *)file
{
	[myFileWatcher removePath:file];
}

- (NSAttributedString *)name:(NSString *)name withImage:(NSImage *)image
{	
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", name]];
	
    if (image != nil) {
		
        NSFileWrapper *wrapper = nil;
        NSTextAttachment *attachment = nil;
        NSAttributedString *icon = nil;
		
        // need a filewrapper to create an NSTextAttachment
        wrapper = [[NSFileWrapper alloc] init];
		
        // set the icon (this is what'll show up in attributed strings)
        [wrapper setIcon:image];
        
        // you need an attachment to create the attributed string as an RTFd
        attachment = [[NSTextAttachment alloc] initWithFileWrapper:wrapper];
        
        // finally, the attributed string for the icon
        icon = [NSAttributedString attributedStringWithAttachment:attachment];
        [result insertAttributedString:icon atIndex:0];
		
        // cleanup
        [wrapper release];
        [attachment release];	
    }
    
    return [result autorelease];
}

#pragma mark -
#pragma mark UKKQueue Delegate Methods

- (void)kqueue:(UKKQueue *)kq receivedNotification:(NSString *)nm forFile:(NSString *)fpath
{
	[NSThread detachNewThreadSelector:@selector(threadedParseDatabase)
							 toTarget:self
						   withObject:nil];
}

- (void)threadedParseDatabase
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	iMBLibraryNode *newDB = [self parseDatabase];
	
	[myCachedLibrary autorelease];
	myCachedLibrary = [newDB retain];
	
	// need to notify the browser that our data changed so it can refresh the outline view
	[(NSObject *)myBrowser performSelectorOnMainThread:@selector(refresh)
											withObject:nil
										 waitUntilDone:YES];
	
	[pool release];
}

@end
