//
//  FileDescription.h
//  Draggy
//
//  Created by El D on 25.02.2021.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileDescription : NSObject

+ (nullable NSString*)getDescriptionForFile:(NSURL*)file; 

@end

NS_ASSUME_NONNULL_END
