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
 * ownership follows create rule (you are responsible for freeing fileDescription), release fileDescription with free(void*) call
 */

#if defined (__cplusplus)

#include <string>
#include <memory>

namespace file {
namespace detail {
extern "C" int copy_file_description(int argc, char *argv[], char** fileDescription);
} // namespace detail

inline int copy_file_description(const int argc, char* argv[], std::string& description) noexcept
{
    char* fileDescription = nullptr;
    const int result = detail::copy_file_description(argc, argv, &fileDescription);
    if (!result && fileDescription)
    {
        const auto& freeDeleter = [](auto* const pointerToFree)
        {
            free(pointerToFree);
        };
        const std::unique_ptr<char[], decltype(freeDeleter)> fileDescriptionUniquePtr(fileDescription, freeDeleter);
        
        try
        {
            description = fileDescriptionUniquePtr.get();
        }
        catch (const std::bad_alloc&)
        {
            return 1;
        }
    }
    
    return result;
}
} // namespace file

#else

extern int copy_file_description(int argc, char *argv[], char** fileDescription);

#endif // defined (__cplusplus)

#endif /* file_h */
