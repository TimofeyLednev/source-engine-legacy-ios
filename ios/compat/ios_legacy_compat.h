// ios_legacy_compat.h -- force-included on legacy iOS cross builds.
//
// We build against the iOS 8.0 SDK but target a deployment version as low
// as iOS 5/6 (armv7). A handful of libc / POSIX symbols the Source engine
// expects are either newer than the deployment target or behave slightly
// differently on the old runtime. This header is force-included (via
// `-include`) into every C and C++ translation unit, so anything added
// here must be valid in both languages and must stay dependency-light.
#ifndef ISOURCE_IOS_LEGACY_COMPAT_H
#define ISOURCE_IOS_LEGACY_COMPAT_H

// TARGET_OS_IPHONE / TARGET_OS_IOS are what the engine keys off of to pick
// the mobile code paths. The very old SDK headers do not always define the
// finer-grained macros, so normalize them early.
#include <TargetConditionals.h>

#ifndef TARGET_OS_IPHONE
#define TARGET_OS_IPHONE 1
#endif
#ifndef TARGET_OS_IOS
#define TARGET_OS_IOS 1
#endif

// The engine's POSIX layer assumes these are always available.
#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

#endif // ISOURCE_IOS_LEGACY_COMPAT_H
