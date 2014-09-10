//
//  Utilities.m
//  iFrameExtractor
//
//  Created by lajos on 1/10/10.
//
//  Copyright 2010 Lajos Kamocsay
//
//  lajos at codza dot com
//
//  iFrameExtractor is free software; you can redistribute it and/or
//  modify it under the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either
//  version 2.1 of the License, or (at your option) any later version.
// 
//  iFrameExtractor is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  Lesser General Public License for more details.
//

#import "CHWUtilities.h"

@implementation CHWUtilities

+(NSString *)bundlePath:(NSString *)fileName {
	return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
}

+(NSString *)documentsPath:(NSString *)fileName {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+(NSMutableData*)ppmDataFromRgbData:(NSData*)frameData AndWidth:(int)width AndHeight:(int)height
{
    NSAssert( [frameData length] == width * height * 3, @"Fatal error: wrong data" );
    
    // Write ppm header to a temp buffer
    char ppmHeader[30];
    int const headerSize = sprintf( ppmHeader, "P6\n%d %d\n255\n", width, height );
    
    // Write ppm totally
    int const contentSize = height * width * 3; // =aDecodedFrame->linesize[0]
    int const ppmSize = headerSize + contentSize;
    NSAssert( ppmSize != 0, @"ppmSize wrong" );
    
    NSMutableData *result = [[NSMutableData alloc] initWithCapacity:ppmSize];
    [result appendBytes:ppmHeader length:headerSize];
    [result appendBytes:[frameData bytes] length:contentSize];
    
    return result;
}

+(void)savePpmData:(NSData*)data InFilename:(NSString*)filename
{
	// NSString *fileName = [Utilities documentsPath:[NSString stringWithFormat:@"image%04d.ppm",iFrame]];
    // NSLog(@"write image file: %@",fileName);
    // [data writeToFile:fileName atomically:YES];
}

+ (unsigned long long)getFileSizeInBytes:(NSString*)filePath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSAssert( [fm fileExistsAtPath:filePath], @"getFileSizeInBytes fatal error: file not exsits" );
    
    NSError *error = nil;
    NSDictionary *fileDictionary = [fm attributesOfItemAtPath:filePath
                                                        error:&error];
    if (!error && fileDictionary)
    {
        return [fileDictionary fileSize];
    }
    
    NSLog( @"getFileSizeInBytes error" );
    return 0;
}

+ (void)appendData:(NSData*)data ToFile:(NSString*)filename
{
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filename];

    if ( !fileExists )
    {
        [data writeToFile:filename atomically:NO];
        NSLog( @"%@ does not exsits, we create one and write data into it", filename );
    }
    else
    {
        NSLog( @"%@ exsits, we append data (size:%d) to it", filename, [data length] );
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filename];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    }
}

+ (void) purgeFile:(NSString*)filename;
{
    NSData *emptyData = [NSData new];
    [emptyData writeToFile:filename atomically:NO];
    
    NSError *error = nil;
    NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:filename
                                                                                    error:&error];
    NSAssert( error == nil && [fileDictionary fileSize] == 0, @"fatal error" );
}

@end
