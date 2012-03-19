#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

NSData* processMMD(NSURL* url);
NSData* processOPML2MMD(NSURL* url);

BOOL logDebug = NO;


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    if (logDebug)
        NSLog(@"generate preview for content type: %@",contentTypeUTI);
    
    CFDataRef previewData;
    
    if (CFStringCompare(contentTypeUTI, CFSTR("org.opml.opml"), 0) == kCFCompareEqualTo)
    {
        // Preview an OPML file
        
        previewData = (CFDataRef) processOPML2MMD((NSURL*) url);
    } else {
        // Preview a text file
        
        previewData = (CFDataRef) processMMD((NSURL*) url);
    }
    
    if (previewData) {
        if (logDebug)
            NSLog(@"preview generated");
        
        CFDictionaryRef properties = (CFDictionaryRef) [NSDictionary dictionary];
        QLPreviewRequestSetDataRepresentation(preview, previewData, kUTTypeHTML, properties);
    }
    
    return noErr;
}

NSData* processOPML2MMD(NSURL* url)
{
    if (logDebug)
        NSLog(@"create preview for OPML file %@",[url path]);
    
    NSString *path2MMD = [[NSBundle bundleWithIdentifier:@"net.fletcherpenney.quicklook"] pathForResource:@"multimarkdown" ofType:nil];
    
		NSTask* task = [[NSTask alloc] init];
		[task setLaunchPath: [path2MMD stringByExpandingTildeInPath]];
		
    [task setArguments: [NSArray arrayWithObjects: nil]];
		
		NSPipe *writePipe = [NSPipe pipe];
		NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
		[task setStandardInput: writePipe];
		
		NSPipe *readPipe = [NSPipe pipe];
		[task setStandardOutput:readPipe];
		
		[task launch];
		
    
    NSString *theData = [NSString stringWithContentsOfFile:[url path] encoding:NSUTF8StringEncoding error:nil];
    
    NSXMLDocument *opmlDocument = [[NSXMLDocument alloc] initWithXMLString:theData
																																	 options:0
																																		 error:nil];
    NSURL *styleFilePath = [[NSBundle bundleWithIdentifier:@"net.fletcherpenney.quicklook"] URLForResource:@"opml2mmd"
                                                                                             withExtension:@"xslt"];
    
    NSData *mmdContents = [opmlDocument objectByApplyingXSLTAtURL:styleFilePath
																												arguments:nil 
																														error:nil];
    
    [opmlDocument release];
    
		[writeHandle writeData:mmdContents];
    
		[writeHandle closeFile];
		
		
		NSData *mmdData = [[readPipe fileHandleForReading] readDataToEndOfFile];
    
    [task release];
		return mmdData;
}

NSData* processMMD(NSURL* url)
{
    if (logDebug)
        NSLog(@"create preview for MMD file %@",[url path]);
		
    NSString *path2MMD = [[NSBundle bundleWithIdentifier:@"net.fletcherpenney.quicklook"] pathForResource:@"multimarkdown" ofType:nil];
    
		NSTask* task = [[NSTask alloc] init];
		[task setLaunchPath: [path2MMD stringByExpandingTildeInPath]];
		
    [task setArguments: [NSArray arrayWithObjects: nil]];
		
		NSPipe *writePipe = [NSPipe pipe];
		NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
		[task setStandardInput: writePipe];
		
		NSPipe *readPipe = [NSPipe pipe];
		[task setStandardOutput:readPipe];
		
		[task launch];
    
    NSStringEncoding encoding = 0;
		
    // Ensure we used proper encoding - try different options until we get a hit
		//  if (plainText == nil)
    //    plainText = [NSString stringWithContentsOfFile:[url path] usedEncoding:<#(NSStringEncoding *)#> error:<#(NSError **)#> encoding:NSASCIIStringEncoding];
    
		
    NSString *theData = [NSString stringWithContentsOfFile:[url path] usedEncoding:&encoding error:nil];
		NSString *cssDir = @"~/.mdqlstyle.css";
		if ([[NSFileManager defaultManager] fileExistsAtPath:[cssDir stringByExpandingTildeInPath]]) {
				NSString *cssStyle = [NSString stringWithFormat:@"\n<style>body{-webkit-font-smoothing:antialiased;padding:20px;max-width:900px;margin:0 auto;}%@</style>",[NSString stringWithContentsOfFile:[cssDir stringByExpandingTildeInPath] encoding:NSUTF8StringEncoding error:nil]];
				theData = [theData stringByAppendingString:cssStyle];
		} else {
				theData = [theData stringByAppendingString:@"\n<style>body{-webkit-font-smoothing:antialiased;font:normal .8764em/1.5em Arial,Verdana,sans-serif;padding:20px;max-width:900px;margin:0 auto}html>body{font-size:13px}li{font-size:110%}li li{font-size:100%}li p{font-size:100%;margin:.5em 0}h1{color:#000;font-size:2.2857em;line-height:.6563em;margin:.6563em 0}h2{color:#111;font-size:1.7143em;line-height:.875em;margin:.875em 0}h3{color:#111;font-size:1.5em;line-height:1em;margin:1em 0}h4{color:#111;font-size:1.2857em;line-height:1.1667em;margin:1.1667em 0}h5{color:#111;font-size:1.15em;line-height:1.3em;margin:1.3em 0}h6{font-size:1em;line-height:1.5em;margin:1.5em 0}body,p,td,div{color:#111;font-family:\"Helvetica Neue\",Helvetica,Arial,Verdana,sans-serif;word-wrap:break-word}h1,h2,h3,h4,h5,h6{line-height:1.5em}a{-webkit-transition:color .2s ease-in-out;color:#0d6ea1;text-decoration:none}a:hover{color:#3593d9}.footnote{color:#0d6ea1;font-size:.8em;vertical-align:super}#wrapper img{max-width:100%;height:auto}dd{margin-bottom:1em}li>p:first-child{margin:0}ul ul,ul ol{margin-bottom:.4em}caption,col,colgroup,table,tbody,td,tfoot,th,thead,tr{border-spacing:0}table{border:1px solid rgba(0,0,0,0.25);border-collapse:collapse;display:table;empty-cells:hide;margin:-1px 0 23px;padding:0;table-layout:fixed}caption{display:table-caption;font-weight:700}col{display:table-column}colgroup{display:table-column-group}tbody{display:table-row-group}tfoot{display:table-footer-group}thead{display:table-header-group}td,th{display:table-cell}tr{display:table-row}table th,table td{font-size:1.1em;line-height:23px;padding:0 1em}table thead{background:rgba(0,0,0,0.15);border:1px solid rgba(0,0,0,0.15);border-bottom:1px solid rgba(0,0,0,0.2)}table tbody{background:rgba(0,0,0,0.05)}table tfoot{background:rgba(0,0,0,0.15);border:1px solid rgba(0,0,0,0.15);border-top:1px solid rgba(0,0,0,0.2)}figure{display:inline-block;margin-bottom:1.2em;position:relative;margin:1em 0}figcaption{font-style:italic;text-align:center;background:rgba(0,0,0,.9);color:rgba(255,255,255,1);position:absolute;left:0;bottom:-24px;width:98%;padding:1%;-webkit-transition:all .2s ease-in-out}.poetry pre{display:block;font-family:Georgia,Garamond,serif!important;font-size:110%!important;font-style:italic;line-height:1.6em;margin-left:1em}.poetry pre code{font-family:Georgia,Garamond,serif!important}blockquote p{font-size:110%;font-style:italic;line-height:1.6em}sup,sub,a.footnote{font-size:1.4ex;height:0;line-height:1;position:relative;vertical-align:super}sub{vertical-align:sub;top:-1px}p,h5{font-size:1.1429em;line-height:1.3125em;margin:1.3125em 0}dt,th{font-weight:700}table tr:nth-child(odd),table th:nth-child(odd),table td:nth-child(odd){background:rgba(255,255,255,0.06)}table tr:nth-child(even),table td:nth-child(even){background:rgba(0,0,0,0.06)}@media print{body{overflow:auto}img,pre,blockquote,table,figure,p{page-break-inside:avoid}#wrapper{background:#fff;color:#303030;font-size:85%;padding:10px;position:relative;text-indent:0}}@media screen{.inverted #wrapper,.inverted{background:rgba(37,42,42,1)}.inverted hr{border-color:rgba(51,63,64,1)!important}.inverted p,.inverted td,.inverted li,.inverted h1,.inverted h2,.inverted h3,.inverted h4,.inverted h5,.inverted h6,.inverted pre,.inverted code,.inverted th,.inverted .math,.inverted caption,.inverted dd,.inverted dt{color:#eee!important}.inverted table tr:nth-child(odd),.inverted table th:nth-child(odd),.inverted table td:nth-child(odd){background:0}.inverted a{color:rgba(172,209,213,1)}#wrapper{padding:20px}::selection{background:rgba(157,193,200,.5)}h1::selection{background-color:rgba(45,156,208,.3)}h2::selection{background-color:rgba(90,182,224,.3)}h3::selection,h4::selection,h5::selection,h6::selection,li::selection,ol::selection{background-color:rgba(133,201,232,.3)}code::selection{background-color:rgba(0,0,0,.7);color:#eee}code span::selection{background-color:rgba(0,0,0,.7)!important;color:#eee!important}a::selection{background-color:rgba(255,230,102,.2)}.inverted a::selection{background-color:rgba(255,230,102,.6)}td::selection,th::selection,caption::selection{background-color:rgba(180,237,95,.5)}}</style>"];
		}
    
    if (logDebug)
        NSLog(@"Used %lu encoding",(unsigned long) encoding);
    
		[writeHandle writeData:[theData dataUsingEncoding:NSUTF8StringEncoding]];
    
		[writeHandle closeFile];
		
		
		NSData *mmdData = [[readPipe fileHandleForReading] readDataToEndOfFile];
		
    [task release];
		return mmdData;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
