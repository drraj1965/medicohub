cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

if(MSVC)
  # Firebase's Windows C++ SDK may reference STL helper symbols that are only
  # present in the newest installed MSVC runtime libraries.
  file(GLOB _MSVC_RUNTIME_LIBRARY_DIRS
    "C:/Program Files (x86)/Microsoft Visual Studio/2022/*/VC/Tools/MSVC/*/lib/x64"
    "C:/Program Files/Microsoft Visual Studio/2022/*/VC/Tools/MSVC/*/lib/x64"
  )
  list(SORT _MSVC_RUNTIME_LIBRARY_DIRS)
  list(REVERSE _MSVC_RUNTIME_LIBRARY_DIRS)

  foreach(_MSVC_RUNTIME_LIBRARY_DIR IN LISTS _MSVC_RUNTIME_LIBRARY_DIRS)
    if(EXISTS "${_MSVC_RUNTIME_LIBRARY_DIR}/msvcprtd.lib")
      target_link_directories(${BINARY_NAME}
        BEFORE PRIVATE "${_MSVC_RUNTIME_LIBRARY_DIR}")
      break()
    endif()
  endforeach()
endif()

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
