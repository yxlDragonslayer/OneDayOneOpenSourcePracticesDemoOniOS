/*
 
 Erica Sadun, http://ericasadun.com
 iOS 7 Cookbook
 Use at your own risk. Do no harm.
 
 */

#import "XMLParser.h"

@implementation XMLParser
{
	NSMutableArray		*stack;
}

static XMLParser *sharedInstance = nil;

// Use just one parser instance at any time
+(XMLParser *)sharedInstance
{
    if(!sharedInstance)
		sharedInstance = [[self alloc] init];
    return sharedInstance;
}

// Parser returns the tree root. Go down one node to the real results
- (TreeNode *)parse:(NSXMLParser *)parser
{
	stack = [NSMutableArray array];
	TreeNode *root = [TreeNode treeNode];
	[stack addObject:root];

	[parser setDelegate:self];
	[parser parse];

	// pop down to real root
	TreeNode *realroot = [[root children] lastObject];

    // Remove any connections
	root.children = nil;
	root.leafvalue = nil;
	root.key = nil;
	realroot.parent = nil;
	
    // Return the true root
	return realroot;
}

- (TreeNode *)parseXMLFromURL:(NSURL *)url
{	
	TreeNode *results = nil;
    @autoreleasepool {
        NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:url];
        results = [self parse:parser];
    }
	return results;
}

- (TreeNode *)parseXMLFromData:(NSData *)data
{	
	TreeNode *results = nil;
    @autoreleasepool {
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        results = [self parse:parser];
    }
    return results;
}

// Descend to a new element
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) elementName = qName;
	
	TreeNode *leaf = [TreeNode treeNode];
	leaf.parent = [stack lastObject];
	[(NSMutableArray *)[[stack lastObject] children] addObject:leaf];
	
	leaf.key = [NSString stringWithString:elementName];
	leaf.leafvalue = nil;
	leaf.children = [NSMutableArray array];
	
	[stack addObject:leaf];
}

// Pop after finishing element
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	[stack removeLastObject];
}

// Reached a leaf
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if (![[stack lastObject] leafvalue])
	{
		[[stack lastObject] setLeafvalue:[NSString stringWithString:string]];
		return;
	}
	[[stack lastObject] setLeafvalue:[NSString stringWithFormat:@"%@%@", [[stack lastObject] leafvalue], string]];
}

@end



