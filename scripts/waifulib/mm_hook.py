from waflib import TaskGen

@TaskGen.extension('.mm')
def mm_hook(self, node):
	"""Alias .mm (Objective-C++) files to be compiled the same as .cpp files.

	clang picks Objective-C++ automatically from the .mm extension, so routing
	the node through the normal 'cxx' task is enough on both macOS and the
	Linux->iOS cross toolchain."""
	return self.create_compiled_task('cxx', node)

@TaskGen.extension('.m')
def m_hook(self, node):
	"""Alias .m (Objective-C) files to be compiled through the 'c' task.

	The legacy iOS launcher (launcher_main/ios/Launchdiag.m) and SDL's UIKit
	entry point are Objective-C; clang infers the ObjC dialect from the .m
	extension, so the standard 'c' task compiles them correctly."""
	return self.create_compiled_task('c', node)
