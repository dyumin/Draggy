//
//  FileDescription.m
//  Draggy
//
//  Created by El D on 25.02.2021.
//

#import "FileDescription.h"

#include "file.h"

#include <array>

@implementation FileDescription

+ (nullable NSString*)getDescriptionForFile:(NSURL*)file
{
    std::array<char*, 3> argv;
    
    std::string app = NSBundle.mainBundle.executableURL.path.UTF8String;
    std::string arguments = "-I";
    std::string fileString = file.path.UTF8String;
    argv[0] = &*app.begin();
    argv[1] = &*arguments.begin();
    argv[2] = &*fileString.begin();

    std::string description;
    if (!file::copy_file_description(argv.size(), argv.data(), description) && !description.empty())
    {
        return [NSString stringWithUTF8String:description.c_str()];
    }
    
    return nil;
}

@end
