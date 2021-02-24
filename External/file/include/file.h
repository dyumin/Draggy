//
//  file.h
//  file
//
//  Created by El D on 24.02.2021.
//

#ifndef file_h
#define file_h

/*
 * main - parse arguments and handle options
 * ownership follows create rule (you are responsible for freeing fileDescription)
 */
extern int
copy_file_description(int argc, char *argv[], char** fileDescription);

#endif /* file_h */
