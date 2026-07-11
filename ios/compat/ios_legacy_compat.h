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

// ---------------------------------------------------------------------------
// MSG_NOSIGNAL.
//
// Linux uses the send() flag MSG_NOSIGNAL to suppress SIGPIPE on a broken
// socket. Apple platforms have no such flag (they use the SO_NOSIGPIPE
// socket option instead), so <sys/socket.h> never defines it. The engine's
// rcon/socketcreator code only guards its own `#define MSG_NOSIGNAL 0` with
// `#ifdef OSX`, which is not set for iOS. Define it here (0 == no flag) for
// every legacy-iOS translation unit so those sends compile and behave like
// the desktop macOS build.
// ---------------------------------------------------------------------------
#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

// ---------------------------------------------------------------------------
// clock_gettime() shim.
//
// clock_gettime() and the CLOCK_* constants only appeared in the iOS 10 SDK.
// We target iOS 5/6, whose SDK headers do not declare them, yet the engine's
// Plat_Rdtsc()/Plat_FloatTime() on ARM+POSIX call clock_gettime(CLOCK_REALTIME).
// Provide a tiny inline replacement built on APIs that exist on every iOS
// version: gettimeofday() for wall-clock and mach_absolute_time() for a
// monotonic source.
// ---------------------------------------------------------------------------
#include <Availability.h>
#if !defined(__IPHONE_10_0) || (__IPHONE_OS_VERSION_MIN_REQUIRED < 100000)
#ifndef ISOURCE_HAVE_CLOCK_GETTIME_SHIM
#define ISOURCE_HAVE_CLOCK_GETTIME_SHIM 1

#include <sys/time.h>
#include <mach/mach_time.h>

#ifndef CLOCK_REALTIME
#define CLOCK_REALTIME  0
#endif
#ifndef CLOCK_MONOTONIC
#define CLOCK_MONOTONIC 6
#endif

typedef int isource_clockid_t;

#ifdef __cplusplus
extern "C" {
#endif

static inline int isource_clock_gettime(isource_clockid_t clk, struct timespec *ts)
{
	if (clk == CLOCK_MONOTONIC) {
		static mach_timebase_info_data_t tb = {0, 0};
		if (tb.denom == 0) mach_timebase_info(&tb);
		uint64_t nsec = mach_absolute_time() * tb.numer / tb.denom;
		ts->tv_sec  = (time_t)(nsec / 1000000000ULL);
		ts->tv_nsec = (long)(nsec % 1000000000ULL);
		return 0;
	}
	struct timeval tv;
	if (gettimeofday(&tv, 0) != 0) return -1;
	ts->tv_sec  = tv.tv_sec;
	ts->tv_nsec = tv.tv_usec * 1000;
	return 0;
}

#ifdef __cplusplus
}
#endif

#define clock_gettime(clk, ts) isource_clock_gettime((clk), (ts))

#endif // ISOURCE_HAVE_CLOCK_GETTIME_SHIM
#endif // pre-iOS 10

#endif // ISOURCE_IOS_LEGACY_COMPAT_H
