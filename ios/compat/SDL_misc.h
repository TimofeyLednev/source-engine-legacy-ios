// ios/compat/SDL_misc.h -- shim for legacy iOS cross builds.
//
// SDL_misc.h (and SDL_OpenURL) first appeared in SDL 2.0.14. Our legacy-iOS
// target pins SDL2 2.0.7 (the last release supporting iOS 6.1), which has no
// such header. The engine's GameUI includes <SDL_misc.h> and calls
// SDL_OpenURL() under `#if ANDROID || IOS` to open a web link from the menu.
//
// Opening an external URL is a non-essential convenience on this challenge
// port, so we provide a tiny inline no-op here (found first because ios/compat
// is on the global include path). A real UIKit-based openURL: can replace this
// later without touching the engine sources.
#ifndef ISOURCE_IOS_COMPAT_SDL_MISC_H
#define ISOURCE_IOS_COMPAT_SDL_MISC_H

#ifdef __cplusplus
extern "C" {
#endif

// Mirrors SDL 2.0.14's signature: int SDL_OpenURL(const char *url);
// Returns 0 on "success" (no-op). Marked unused-friendly via inline.
static inline int SDL_OpenURL(const char *url)
{
	(void)url;
	return 0;
}

#ifdef __cplusplus
}
#endif

#endif // ISOURCE_IOS_COMPAT_SDL_MISC_H
