/*
 iosutils.m - iOS launch dialog
 Copyright (C) 2016 mittorn
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 */

#include "SDL2/SDL_syswm.h"
#include "SDL2/SDL_metal.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include <Metal/Metal.h>
#include <sys/stat.h>
#include "dlfcn.h"

#ifndef XASH_GAMEDIR
#define XASH_GAMEDIR "valve" // !!! Replace with your default (base) game directory !!!
#endif
#define XASHLIB "@rpath/libxash.dylib"

float g_iOSVer;

__attribute__((visibility("default"))) const char *IOS_GetDocsDir(void)
{
	if (!g_iOSVer)
	{
		float IOS_GetVersion( void );
		IOS_GetVersion();
	}

	if( g_iOSVer >= 8.0 )
	{
	static const char *dir = NULL;
	
	if( dir )
		return dir;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirctory = [paths objectAtIndex:0];
	[[NSFileManager defaultManager] createDirectoryAtPath:documentsDirctory withIntermediateDirectories:YES attributes:nil error:nil];
	
	dir = [documentsDirctory fileSystemRepresentation];
	NSLog(@"IOS_GetDocsDir: %s", dir);
	
	return dir;
	}
	else
	{
		static char dir[1024];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *basePath = paths.firstObject;
		[[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
		strcpy(dir,[basePath UTF8String]);
		mkdir(dir,777);

		NSLog(@"IOS_GetDocsDir: %s", dir);

		return dir;
	}
}

__attribute__((visibility("default"))) const char *IOS_GetExecDir(void)
{
	if (!g_iOSVer)
	{
		float IOS_GetVersion( void );
		IOS_GetVersion();
	}

	if( g_iOSVer >= 8.0 )
	{
	static char *dir = NULL;
	
	if( dir )
		return dir;

	dir = [[[NSBundle mainBundle] bundleURL] fileSystemRepresentation];
	dir = strcat(dir, "/hl2_launcher");
	NSLog(@"IOS_GetExecDir: %s", dir);
	
	return dir;
	}
	else
	{
		static char dir[1024];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *basePath = paths.firstObject;
		[[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:nil];
		strcpy(dir,[basePath UTF8String]);
		mkdir(dir,777);

		NSLog(@"IOS_GetDocsDir: %s", dir);

		return dir;
	}
}



__attribute__((visibility("default"))) float IOS_GetVersion( void )
{
	NSLog(@"System Version is %@",[[UIDevice currentDevice] systemVersion]);
	NSString *ver = [[UIDevice currentDevice] systemVersion];
	g_iOSVer = [ver floatValue];
	return g_iOSVer;
}

__attribute__((visibility("default"))) char *IOS_GetUDID( void )
{
	static char udid[256];
	NSString *id = [[[UIDevice currentDevice]identifierForVendor] UUIDString];
	strncpy( udid, [id UTF8String], 255 );
	[id release];
	return udid;
}

__attribute__((visibility("default"))) void IOS_Log(const char *text)
{
	NSLog(@"Xash: %@", [NSString stringWithUTF8String:text]);
}