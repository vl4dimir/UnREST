//
//  UnREST.h
//  UnREST
//

#define kUnRESTBoundary @"----UnR3ST"

#define kUnRESTMultipartName @"name"
#define kUnRESTMultipartType @"type"
#define kUnRESTMultipartContent @"content"
#define kUnRESTMultipartFilename @"filename"

#define kUnRESTContentTypePlain @"text/plain"
#define kUnRESTContentTypeImageJPEG @"image/jpeg"

#define kUnRESTJPEGQuality 0.8

@protocol UnRESTDelegate;

@interface UnREST : NSObject {
	NSString* urlString;
	NSURLConnection* connection;
	NSMutableData* responseData;
	
	NSMutableArray* multiparts;
	
	id<UnRESTDelegate> delegate;
}

@property (nonatomic, retain) NSString* urlString;
@property (nonatomic, assign) id<UnRESTDelegate> delegate;

- (id) initWithURLString:(NSString*)urlString delegate:(id<UnRESTDelegate>)delegate;
- (void) pull;
- (void) pushString:(NSString *)string;
- (void) pushMultipart:(NSArray*)parts;

- (void) addTextPart:(NSString*)text name:(NSString*)name;
- (void) addImagePart:(UIImage*)image name:(NSString*)name;
- (void) pushParts;

@end

@protocol UnRESTDelegate

- (void) unrest:(UnREST*)unrest didFinishWithResponse:(NSData*)response;
- (void) unrest:(UnREST*)unrest didFailWithError:(NSError*)error;

@end