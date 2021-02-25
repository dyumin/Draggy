#  <#Title#>

1. CoreFoundation leaks memory on dragging session end. Maybe something can be done (Apple bug?)

2. Draggy/External/file/file/src/file.c:245
From getopt_long's man: 
BUGS
     The argv argument is not really const as its elements may be permuted (unless POSIXLY_CORRECT is set).
May lead to crashes since we pass internal std::string pointer
