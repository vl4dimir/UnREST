//
//  UnREST.m
//  UnREST
//

#import "UnREST.h"

#pragma mark -
#pragma mark Private declarations

@interface UnREST ()

@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSMutableData* responseData;
@property (nonatomic, retain) NSMutableArray* multiparts;

@end


#pragma mark -
#pragma mark Implementation

@implementation UnREST

@synthesize urlString;
@synthesize connection;
@synthesize responseData;
@synthesize delegate;
@synthesize multiparts;


#pragma mark -
#pragma mark Initialization

- (id) initWithURLString:(NSString*)urlStr delegate:(id<UnRESTDelegate>)del
{
	if (self = [super init]) {
		self.urlString = urlStr;
		self.delegate = del;
	}
	
	return self;
}


#pragma mark -
#pragma mark Networking

/**
 * Performs an HTTP GET request.
 */
- (void) pull
{
	self.responseData = [NSMutableData data];
	
	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[connection start];
}

/**
 * Performs an HTTP POST request, using string as payload.
 * 
 * @param string POST request payload.
 */
- (void) pushString:(NSString *)string
{
	// Construct the URL request object
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Create our response placeholder
	self.responseData = [NSMutableData data];
	
	// Go
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[connection start];
}

/**
 * Performs an HTTP POST multipart request. The parts array holds values that are to be
 * inserted into the request as POST multipart sections. Each part in the parts array
 * must be an NSDictionary, or the class explodes.
 *
 * Each part dictionary must have the following key->value mappings:
 * 
 * - kUnRESTMultipartName -> the name for this multipart section. This is written to the
 *   "name" field in the "Content-Disposition" POST header, and is used by the server to
 *   differentiate the parts.
 *
 * - kUnRESTMultipartType -> a string to be put in the "Content-Type" POST header.
 *   @"text/plain" for strings, @"image/jpeg" for images, etc.
 * 
 * - kUnRESTMultipartContent -> the actual content of this multipart section. The value for
 *   this key has to be an NSData object.
 * 
 * - kUnRESTMultipartFilename (OPTIONAL) -> the filename to be put in the "Content-Disposition"
 *   POST header.
 * 
 * @param parts An array holding data for the POST multipart request
 */
- (void) pushMultipart:(NSArray*)parts
{
	// Construct the URL request object
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
	[request setHTTPMethod:@"POST"];
	
	// This is our boundary string
	NSData* fullBoundary = [[NSString stringWithFormat:@"\r\n--%@\r\n", kUnRESTBoundary] dataUsingEncoding:NSUTF8StringEncoding];
	
	// Set the Content-type to multipart/form-data
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data, boundary=%@", kUnRESTBoundary];
	[request setValue:contentType forHTTPHeaderField:@"Content-type"];
	
	// Start creating our POST body
	NSMutableData* postBody = [NSMutableData data];
	[postBody appendData:fullBoundary];
	
	for (NSDictionary* part in parts) {
		NSString* name     = [part objectForKey:kUnRESTMultipartName];
		NSString* type     = [part objectForKey:kUnRESTMultipartType];
		NSData*   content  = [part objectForKey:kUnRESTMultipartContent];
		NSString* filename = [part objectForKey:kUnRESTMultipartFilename];
		
		// Set the "Content-Disposition" header
		NSString* contentDisposition;
		if (filename) {
			contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", name, filename];
		}
		else {
			contentDisposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", name];
		}
		[postBody appendData:[contentDisposition dataUsingEncoding:NSUTF8StringEncoding]];
		
		// Set content type
		NSString* contentType = [NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", type];
		[postBody appendData:[contentType dataUsingEncoding:NSUTF8StringEncoding]];
		
		// Set the actual content
		[postBody appendData:content];
		
		// On to the next one
		[postBody appendData:fullBoundary];
	}
	
	// Set the body
	[request setHTTPBody:postBody];
	
	// Create our response placeholder
	self.responseData = [NSMutableData data];
	
	// Go
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[connection start];
}


#pragma mark -
#pragma mark Multipart packing methods

- (void) addTextPart:(NSString*)text name:(NSString*)name
{
	if (!multiparts) self.multiparts = [NSMutableArray array];
	
	NSDictionary* part = [NSDictionary dictionaryWithObjectsAndKeys:
						  name, kUnRESTMultipartName,
						  [text dataUsingEncoding:NSUTF8StringEncoding], kUnRESTMultipartContent,
						  kUnRESTContentTypePlain, kUnRESTMultipartType,
						  nil];
	
	[multiparts addObject:part];
}

- (void) addImagePart:(UIImage*)image name:(NSString*)name
{
	if (!multiparts) self.multiparts = [NSMutableArray array];
	
	NSData* jpegImage = UIImageJPEGRepresentation(image, kUnRESTJPEGQuality);
	
	NSString* filename = [NSString stringWithFormat:@"%@.jpg", name];
	NSDictionary* part = [NSDictionary dictionaryWithObjectsAndKeys:
						  name, kUnRESTMultipartName,
						  jpegImage, kUnRESTMultipartContent,
						  kUnRESTContentTypeImageJPEG, kUnRESTMultipartType,
						  filename, kUnRESTMultipartFilename,
						  nil];
	
	[multiparts addObject:part];
}

- (void) pushParts
{
	[self pushMultipart:multiparts];
}


#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	self.connection = nil;
	
	[delegate unrest:self didFinishWithResponse:responseData];
	
	self.responseData = nil;
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	self.responseData = nil;
	self.connection = nil;
	
	[delegate unrest:self didFailWithError:error];
}


#pragma mark -
#pragma mark Memory management

- (void) dealloc
{
	self.urlString = nil;
	self.multiparts = nil;
	
	[super dealloc];
}

@end
