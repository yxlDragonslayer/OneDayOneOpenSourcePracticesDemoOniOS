//
//  main.m
//  pushutil
//
//  Created by Erica Sadun on 9/19/11.
//  Copyright (c) 2011 Up To No Good, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APNSHelper.h"
void usage(void);
NSString *workingDir(void);
NSString *deviceFile(void);
NSString *cert(void);
NSData *apnsCert(void);
void checkCert(void);

void usage()
{
	//      12345678901234567890123456789012345678901234567890123456789012345678901234567890
	printf("Usage: pushutil options\n");
	printf("-help				Print this usage message\n");
	printf("-cwd				Use the current directory\n");
	printf("-pwd				Print the active directory\n");
	printf("-devices			List the available devices\n");
	printf("-add name			Add a device name (one per execution)\n");
	printf("-token devicetoken		Use with -add for device token\n");
	printf("-remove name			Remove a device\n");
	printf("-use name			Set this device as default\n");
	printf("-badge number			Badge the application\n");
	printf("-sound soundfile		Play this sound\n");
	printf("-msg message			Set the alert message\n");
	printf("-okay				Use one OK button on the alert\n");
	printf("-button text			Use custom button text\n");
	printf("-feedback			Request feedback report\n");
	printf("-sandbox			Use the sandbox (not the production) server\n");
	printf("Note: This utility does not support custom payload entries at this time\n");
}

// Return the current working directory for the utility.
// This dir stores the .cer and .devices files. It need not be the folder
// from which this utility is run
NSString *workingDir()
{
	return [[NSUserDefaults standardUserDefaults] objectForKey:@"cwd"];
}

// Attempt to retrieve the device file path from the cwd.
// If one does not exist, it creates one.
NSString *deviceFile()
{
	NSString *cwd = workingDir();
	if (!cwd) return nil;
	
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cwd error:nil];
    if (!contents) return nil;

	NSArray *dfiles = [contents pathsMatchingExtensions:@[@"devices"]];
	
	if (![dfiles count])
	{
		NSDictionary *dict = @{};
		NSString *path = [cwd stringByAppendingPathComponent:@"apns.devices"];
		[dict writeToFile:path atomically:YES];
		return path;
	}
	
	return [cwd stringByAppendingPathComponent:[dfiles lastObject]];
}

// Return the file name (without path) for the certificate
NSString *cert()
{
	NSString *cwd = workingDir();
	if (!cwd) return nil;
    
	NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cwd error:nil];
    if (!contents) return nil;

	NSArray *certs = [contents pathsMatchingExtensions:@[@"cer"]];
	if (!certs.count) return nil;

	return [certs lastObject];
}

// Return the apns certificate data, which must be stored in the working directory
NSData *apnsCert()
{
	NSString *dcert = cert();
	if (!dcert) return nil;
	
	NSString *path = [workingDir() stringByAppendingPathComponent:dcert];
	return [NSData dataWithContentsOfFile:path];
}

// Check whether a .cer file is located in the working directory or not
void checkCert()
{
	NSString *cer = cert();
	if (!cer)
		printf("Warning: No certificates found in the working directory\n");
	else
		printf("The default certificate is %s\n", [cer UTF8String]);
}

int main (int argc, const char * argv[])
{
    if (argc == 1)
    {
        usage();
        exit(1);
    }

    @autoreleasepool {
        // Gather command line arguments
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF beginswith '-'"];
        NSArray *dashedArgs = [args filteredArrayUsingPredicate:pred];
        
        // Prepare the main, payload, and alert dictionaries
        NSMutableDictionary *mainDict = [NSMutableDictionary dictionary];
        NSMutableDictionary *payloadDict = [NSMutableDictionary dictionary];
        NSMutableDictionary *alertDict = [NSMutableDictionary dictionary];
        payloadDict[@"alert"] = alertDict;
        mainDict[@"aps"] = payloadDict;
        
        // Scan for device adds
        NSString *deviceName = nil;
        NSString *token = nil;
        
        for (NSString *darg in dashedArgs)
        {
            if (([darg caseInsensitiveCompare:@"-help"] == NSOrderedSame) ||
                ([darg caseInsensitiveCompare:@"-usage"] == NSOrderedSame))
            {
                usage();
                exit(1);
            }
            
            if ([darg caseInsensitiveCompare:@"-badge"] == NSOrderedSame) 
            {
                NSString *badge = [[NSUserDefaults standardUserDefaults] objectForKey:@"badge"];
                if (!badge)
                {
                    fprintf(stderr, "Error: Supply badge number with -badge\n");
                    continue;
                }
                payloadDict[@"badge"] = @([badge intValue]);
                continue;
            }
            
            if (([darg caseInsensitiveCompare:@"-sound"] == NSOrderedSame) ||
                ([darg caseInsensitiveCompare:@"-snd"] == NSOrderedSame))
            {
                NSString *sound = [[NSUserDefaults standardUserDefaults] objectForKey:@"sound"];
                if (!sound) sound = [[NSUserDefaults standardUserDefaults] objectForKey:@"snd"];
                if (!sound)
                {
                    fprintf(stderr, "Error: Supply file name with -sound\n");
                    continue;
                }
                payloadDict[@"sound"] = sound;
                continue;
            }
            
            if (([darg caseInsensitiveCompare:@"-okay"] == NSOrderedSame) ||
                ([darg caseInsensitiveCompare:@"-ok"] == NSOrderedSame))
            {
                alertDict[@"action-loc-key"] = [NSNull null];
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-button"] == NSOrderedSame) 
            {
                NSString *button = [[NSUserDefaults standardUserDefaults] objectForKey:@"button"];
                if (!button)
                {
                    fprintf(stderr, "Error: Supply text with -button\n");
                    continue;
                }
                
                alertDict[@"action-loc-key"] = button;
                continue;
            }
            
            if (([darg caseInsensitiveCompare:@"-msg"] == NSOrderedSame) ||
                ([darg caseInsensitiveCompare:@"-message"] == NSOrderedSame))
            {
                NSString *msg = [[NSUserDefaults standardUserDefaults] objectForKey:@"msg"];
                if (!msg) msg = [[NSUserDefaults standardUserDefaults] objectForKey:@"message"];
                if (!msg)
                {
                    fprintf(stderr, "Error: Supply text with -msg\n");
                    continue;
                }
                alertDict[@"body"] = msg;
                continue;
            }
            
            if (([darg caseInsensitiveCompare:@"-add"] == NSOrderedSame) ||
                ([darg caseInsensitiveCompare:@"-device"] == NSOrderedSame))
            {
                deviceName = [[NSUserDefaults standardUserDefaults] objectForKey:@"add"];
                if (!deviceName) deviceName = [[NSUserDefaults standardUserDefaults] objectForKey:@"device"];
                if (!deviceName)
                {
                    fprintf(stderr, "Error: Supply device name with -add\n");
                    continue;
                }
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-token"] == NSOrderedSame) 
            {
                token = [[NSUserDefaults standardUserDefaults] objectForKey:@"token"];
                if (!token)
                {
                    fprintf(stderr, "Error: Supply token id with -token\n");
                    continue;
                }
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-use"] == NSOrderedSame) 
            {
                NSString *use = [[NSUserDefaults standardUserDefaults] objectForKey:@"use"];
                if (!use) 
                {
                    fprintf(stderr, "Error: supply a device name with -use\n");
                    continue;
                }
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:deviceFile()];
                if (!dict)
                {
                    fprintf(stderr, "Error: token not found for device %s.\n", [use UTF8String]);
                    continue;
                }
                
                NSString *usetoken = dict[[use uppercaseString]];
                if (!usetoken)
                {
                    fprintf(stderr, "Error: token not found for device %s.\n", [use UTF8String]);
                    continue;
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:usetoken forKey:@"defaultToken"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                printf("Default token set for device %s\n", [use UTF8String]);
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-sandbox"] == NSOrderedSame)
            {
                [APNSHelper sharedInstance].useSandboxServer = YES;
                printf("Will use sandbox (not production) sever.\n");
                continue;
            }
        }
        
        if ((token && !deviceName) || (deviceName && !token))
        {
            fprintf(stderr, "Error: Supply both a device name with -add and a device token with -token\n");
            exit(-1);
        }
        
        if (token && deviceName)
        {
            if (!workingDir())
            {
                fprintf(stderr, "Error: You must set up a working directory before adding devices\n");
                exit(-1);
            }
            
            if ([token length] != 71)
            {
                fprintf(stderr, "Error: Supply the token using the following format\n");
                printf("-token \"xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx\"\n");
                exit(-1);
            }
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:deviceFile()];
            dict[[deviceName uppercaseString]] = token;
            [dict writeToFile:deviceFile() atomically:YES];
            printf("Added %s to device list\n", [deviceName UTF8String]);
        }
        
        // Scan for actions
        for (NSString *darg in dashedArgs)
        {
            if ([darg caseInsensitiveCompare:@"-cwd"] == NSOrderedSame) 
            {
                char wd[256];
                getwd(wd);
                
                NSString *cwd = @(wd);
                [[NSUserDefaults standardUserDefaults] setObject:cwd forKey:@"cwd"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                printf("Updated working directory:\n    %s\n", [cwd UTF8String]);
                checkCert();
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-pwd"] == NSOrderedSame) 
            {
                NSString *cwd = workingDir();
                if (!cwd) 
                    printf("The working directory has not yet been set. Use -cwd to set it here.\n");
                else
                    printf("Working directory: %s\n", [cwd UTF8String]);
                checkCert();
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-clearwd"] == NSOrderedSame)  // undocumented
            {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cwd"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                printf("Cleared working directory\n");
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-cleartoken"] == NSOrderedSame)  // undocumented
            {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"defaultToken"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                printf("Cleared default token\n");
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-devices"] == NSOrderedSame) 
            {
                if (!workingDir())
                {
                    printf("You must set up a working directory before checking for devices\n");
                    continue;
                }
                
                NSString *dfile = deviceFile();
                if (!dfile)
                {
                    printf("No devices have been set up yet\n");
                    continue;
                }
                
                NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:dfile];
                if (!dict)
                    printf("No devices have been set up yet\n");
                else
                {
                    printf("There are %d available devices\n", (int) dict.allKeys.count);
                    for (NSString *key in [dict allKeys])
                        printf("    %s\n", [key UTF8String]);
                }
                
                NSString *dtok = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultToken"];
                if (!dtok) continue;
                NSArray *keys = [dict allKeysForObject:dtok];
                if (keys && ([keys count] > 0)) printf("Default device is %s\n", [[keys lastObject] UTF8String]);
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-remove"] == NSOrderedSame)
            {
                NSString *key = [[NSUserDefaults standardUserDefaults] objectForKey:@"remove"];
                if (!key)
                {
                    fprintf(stderr, "Error: Supply a device name to -remove. Use -devices to list.\n");
                    continue;
                }
                
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:deviceFile()];
                if (!dict)
                {
                    fprintf(stderr, "Error: device not found\n");
                    continue;
                }
                
                if (!dict[key])
                {
                    fprintf(stderr, "Error: device not found\n");
                    continue;
                }
                
                [dict removeObjectForKey:key];
                [dict writeToFile:deviceFile() atomically:YES];
                printf("Device %s removed from list.\n", [key UTF8String]);
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-kvpairs"] == NSOrderedSame)  // undocumented
            {
                NSString *kvstring = [[NSUserDefaults standardUserDefaults] objectForKey:@"kvpairs"];
                NSArray *kvarray = [kvstring componentsSeparatedByString:@" "];
                for (NSString *item in kvarray)
                {
                    NSArray *pair = [item componentsSeparatedByString:@":"];
                    if ([pair count] != 2) continue;
                    mainDict[pair[0]] = [pair lastObject];
                }
                
                printf("Custom key value pairs added to dictionary\n");
                continue;
            }
            
            if ([darg caseInsensitiveCompare:@"-feedback"] == NSOrderedSame) 
            {
                NSString *dToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultToken"];
                if (!dToken)
                {
                    fprintf(stderr, "Error: Device token has not been set.\n");
                    exit(-1);
                }
                
                NSData *dCert = apnsCert();
                if (!dCert)
                {
                    fprintf(stderr, "Error retrieving apns certificate\n");
                    exit(-1);
                }
                
                [APNSHelper sharedInstance].deviceTokenID = dToken;
                [APNSHelper sharedInstance].certificateData = dCert;
                NSArray *resultsArray = [[APNSHelper sharedInstance] fetchFeedback];
                
                if	(resultsArray.count == 0)
                {
                    printf("No feedback results at this time.\n");
                }
                else
                {
                    
                    NSString *path = [workingDir() stringByAppendingPathComponent:@"feedback.txt"];
                    FILE *fp;
                    if ((fp = fopen([path UTF8String], "a")) == NULL)
                    {
                        printf("Cannot open feedback.txt for output\n");
                        exit(-1);
                    }
                    
                    printf("APNS has encountered the following delivery failures:\n\n");
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.dateFormat = @"MM/dd/YY h:mm:ss a";
                    
                    for (NSDictionary *dict in resultsArray)
                    {
                        NSString *deviceid = [[dict allKeys] lastObject];
                        NSDate *date = dict[deviceid];
                        NSString *timestamp = [formatter stringFromDate:date];
                        fprintf(fp, "%s %s\n", [timestamp UTF8String], [deviceid UTF8String]);
                        printf("TIMESTAMP: %s\n", [timestamp UTF8String]);
                        printf("DEVICE ID: %s\n\n", [deviceid UTF8String]);
                    }
                    
                    fclose(fp);
                    printf("Wrote %d events to feedback.txt\n", (int) resultsArray.count);
                }
                
                exit(1); // successful exit
            }
            
            if ([darg caseInsensitiveCompare:@"-undoc"] == NSOrderedSame)  // undocumented
            {
                printf("-undoc			print this message\n");
                printf("-usage			synonym for -help\n");
                printf("-snd			synonym for -sound\n");
                printf("-ok			synonym for -okay\n");
                printf("-message		synonym for -msg\n");
                printf("-device			synonym for -add\n");
                printf("-clearwd		clear the current working directory from memory\n");
                printf("-cleartoken		remove the active token setting\n");
                printf("-kvpairs		manually add custom k/v pairs, string-to-string only\n");
                continue;
            }
        }
        
        // Determine whether to continue with sending alert
        
        BOOL goOn = (payloadDict[@"sound"] || payloadDict[@"badge"]);
        goOn = goOn || alertDict[@"body"];
        goOn = goOn || ([[mainDict allKeys] count] > 1);
        if (!goOn)
        {
            printf("No message to send.\nDone.\n");
            exit(1);
        }
        
        NSString *dToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultToken"];
        if (!dToken)
        {
            fprintf(stderr, "Error: Device token has not been set.\n");
            exit(-1);
        }
        
        NSData *dCert = apnsCert();
        if (!dCert)
        {
            fprintf(stderr, "Error retrieving apns certificate\n");
            exit(-1);
        }
        
        printf("Preparing to send message\n");
        
        [APNSHelper sharedInstance].deviceTokenID = dToken;
        [APNSHelper sharedInstance].certificateData = dCert;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:mainDict options:0 error:nil];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        BOOL success = [[APNSHelper sharedInstance] push:jsonString];
        
        if (success) printf("Done.\n");
        else fprintf(stderr, "Errors encountered during send.\n");
        
    }
    return 0;
}

