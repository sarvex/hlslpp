require ('premake-xbox360/xbox360')
require ("vstudio")

Workspace = "workspace/".._ACTION

-- Compilers

-- x86/x64
PlatformMSVC64AVX2		= "MSVC 64 AVX2"
PlatformMSVC64AVX		= "MSVC 64 AVX"
PlatformMSVC64SSE41		= "MSVC 64 SSE 4.1"
PlatformMSVC64SSE2		= "MSVC 64 SSE 2"
PlatformMSVC64Scalar	= "MSVC 64 Scalar"
PlatformMSVC32SSE2		= "MSVC 32 SSE 2"

PlatformLLVM64AVX		= "LLVM 64 AVX"
PlatformLLVM64SSE41		= "LLVM 64 SSE 4.1"
PlatformLLVM64SSE2		= "LLVM 64 SSE 2"
PlatformLLVM32SSE2		= "LLVM 32 SSE 2"

PlatformOSX64			= "OSX 64"
PlatformLinux64_GCC		= "Linux64_GCC"
PlatformLinux64_Clang	= "Linux64_Clang"

-- NEON
PlatformARM 			= "MSVC ARM"
PlatformARM64 			= "MSVC ARM64"
PlatformAndroidARM 		= "Android ARM"
PlatformAndroidARM64 	= "Android ARM64"

Platform360 			= "Xbox 360"

UnitTestProject = "unit_tests"
AndroidProject = "hlsl++_android"

isMacBuild = _ACTION == "xcode4"
isLinuxBuild = _ACTION == "gmake2"
isWindowsBuild = not isMacBuild and not isLinuxBuild
supportsARMBuild = _ACTION == "vs2017" or _ACTION == "vs2019" or _ACTION == "vs2022"

-- Directories
srcDir = "src"
includeDir = "include"

premake.override(premake.vstudio.vc2010.elements, "clCompile", function(oldfn, cfg)
  local calls = oldfn(cfg)
  table.insert(calls, function(cfg)
    premake.vstudio.vc2010.element("SupportJustMyCode", nil, "false")
  end)
  return calls
end)

function handleAndroidWarnings()

	buildoptions
	{
		"-Wno-error=macro-redefined"
	}

end

workspace("hlsl++")
	configurations { "Debug", "Release" }
	location (Workspace)
	
	flags
	{
		"multiprocessorcompile", -- /MP
	}
	
	includedirs
	{
		includeDir,
	}
	
	vectorextensions ("sse4.1")
	cppdialect("c++11")
	defines { "HLSLPP_FEATURE_TRANSFORM" }
	warnings('extra')
	--flags { 'fatalcompilewarnings' }
		
	if(isMacBuild) then
	
		platforms { PlatformOSX64 }
		toolset("clang")
		architecture("x64")
		buildoptions { "-std=c++11" }
		linkoptions { "-stdlib=libc++" }
		
	elseif(isLinuxBuild) then
	
		platforms { PlatformLinux64_GCC, PlatformLinux64_Clang }
		architecture("x64")
		buildoptions { "-std=c++11 -msse4.1" }
		
		filter { "platforms:"..PlatformLinux64_GCC }
			toolset("gcc")
		
		filter { "platforms:"..PlatformLinux64_Clang }
			toolset("clang")
		
	else
	
		platforms
		{
			PlatformMSVC64AVX2,
			PlatformMSVC64AVX,
			PlatformMSVC64SSE41,
			PlatformMSVC64SSE2,
			PlatformMSVC64Scalar,
			PlatformMSVC32SSE2, 
			
			PlatformLLVM64AVX,
			PlatformLLVM64SSE41,
			PlatformLLVM64SSE2,
			PlatformLLVM32SSE2, 

			Platform360
		}

		if(supportsARMBuild) then

			platforms
			{
				PlatformARM, 
				PlatformARM64, 
				PlatformAndroidARM, 
				PlatformAndroidARM64
			}

		end
	
		local llvmToolset;
		
		if (_ACTION == "vs2015") then
			llvmToolset = "msc-llvm-vs2014";
		elseif(_ACTION == "vs2017") then
			llvmToolset = "msc-llvm";
		else
			llvmToolset = "msc-clangcl";
		end
		
		startproject(UnitTestProject)
		
		filter { "platforms:"..PlatformMSVC64AVX2 }
			toolset("msc")
			architecture("x64")
			vectorextensions("avx2")
		
		filter { "platforms:"..PlatformMSVC64AVX }
			toolset("msc")
			architecture("x64")
			vectorextensions("avx")
		
		filter { "platforms:"..PlatformMSVC64SSE41 }
			toolset("msc")
			architecture("x64")
			vectorextensions("sse4.1")
			defines { "__SSE4_1__" }
			
		filter { "platforms:"..PlatformMSVC64SSE2 }
			toolset("msc")
			architecture("x64")
			vectorextensions("sse2")
			
		filter { "platforms:"..PlatformMSVC64Scalar }
			toolset("msc")
			architecture("x64")
			defines { "HLSLPP_SCALAR" }
		
		filter { "platforms:"..PlatformMSVC32SSE2 }
			toolset("msc")
			vectorextensions("sse2")
			
		filter { "platforms:"..PlatformLLVM64AVX }
			toolset(llvmToolset)
			architecture("x64")
			vectorextensions("avx")
			buildoptions { "-mavx" }
			
		filter { "platforms:"..PlatformLLVM64SSE41 }
			toolset(llvmToolset)
			architecture("x64")
			vectorextensions("sse4.1")
			defines { "__SSE4_1__" }
			buildoptions { "-msse4.1" }
			
		filter { "platforms:"..PlatformLLVM64SSE2 }
			toolset(llvmToolset)
			architecture("x64")
			vectorextensions("sse2")
			
		filter { "platforms:"..PlatformLLVM32SSE2 }
			toolset(llvmToolset)
			
		filter { "platforms:"..PlatformARM }
			architecture("arm")
			vectorextensions ("neon")
			
		filter { "platforms:"..PlatformARM64 }
			architecture("arm64")
			vectorextensions ("neon")
			
		filter { "platforms:"..PlatformAndroidARM }
			system("android")
			architecture("arm")
			linkoptions { "-lm" } -- Link against the standard math library
			handleAndroidWarnings()
			
		filter { "platforms:"..PlatformAndroidARM64 }
			system("android")
			architecture("arm64")
			linkoptions { "-lm" } -- Link against the standard math library
			handleAndroidWarnings()
			
		filter { "platforms:"..Platform360 }
			system("xbox360")
			vectorextensions ("default")
			defines("_XBOX")
			
		filter{}
	end
	
	filter { "configurations:Debug" }
		defines { "DEBUG" }
		symbols ("full")
		inlining("auto") -- hlslpp relies on inlining for speed, big gains in debug builds without losing legibility
		optimize("debug")
		
	filter { "configurations:Release" }
		defines { "NDEBUG" }
		inlining("auto")
		optimize("speed")

project ("hlsl++")
	kind("staticlib")
	language("c++")
	files
	{
		includeDir.."/**.h",
		includeDir.."/*.natvis"
	}
	
project (UnitTestProject)
	kind("consoleapp")
	--links { "hlsl++" }
	files
	{
		srcDir.."/*.cpp",
		srcDir.."/*.h",
	}
	
	filter { "platforms:"..PlatformAndroidARM.." or ".. PlatformAndroidARM64}
		kind("sharedlib")
		files
		{
			"src/android/android_native_app_glue.h",
			"src/android/android_native_app_glue.c",
		}
		
	filter{}
	
	includedirs
	{
		srcDir.."/**.h"
	}

if (supportsARMBuild) then

project (AndroidProject)
	removeplatforms("*")
	platforms { PlatformAndroidARM, PlatformAndroidARM64 }
	kind("Packaging") -- This type of project builds the apk
	links (UnitTestProject) -- Android needs to link to the main project which was built as a dynamic library
	androidapplibname(UnitTestProject)
	files
	{
		"src/android/AndroidManifest.xml",
		"src/android/build.xml",
		"src/android/project.properties",
		"src/android/res/values/strings.xml",
	}
end
