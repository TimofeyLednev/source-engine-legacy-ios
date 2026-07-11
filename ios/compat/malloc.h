// ios/compat/malloc.h -- shim for legacy iOS cross builds.
//
// Several third-party sources (notably the IVP/Havok physics submodule)
// do `#include <malloc.h>`, a glibc-ism that does not exist on Apple
// platforms. On iOS/macOS the equivalent lives in <malloc/malloc.h>, and
// the standard allocation prototypes come from <stdlib.h>. This shim is
// found first because ios/compat is placed on the global include path, so
// those legacy includes resolve without patching the submodule sources.
#ifndef ISOURCE_IOS_COMPAT_MALLOC_H
#define ISOURCE_IOS_COMPAT_MALLOC_H

#include <stdlib.h>
#include <malloc/malloc.h>

// glibc exposes memalign() via <malloc.h>; Apple provides posix_memalign()
// and valloc() instead. Nothing in the engine's hot paths needs memalign(),
// so we intentionally do not emulate it here.

#endif // ISOURCE_IOS_COMPAT_MALLOC_H
