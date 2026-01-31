#ifndef __OBJC__
extern "C" const char *IOS_GetDocsDir( void );
extern "C" const char *IOS_GetExecDir( void );
#else
const char *IOS_GetDocsDir( void );
const char *IOS_GetExecDir( void );
#endif