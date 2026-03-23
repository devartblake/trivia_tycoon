#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Set the UI thread to above-normal priority for smoother animations.
  ::SetThreadPriority(::GetCurrentThread(), THREAD_PRIORITY_ABOVE_NORMAL);

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  // Read optional environment variable overrides for the Dart entrypoint.
  // Example: set TRIVIA_TYCOON_ENV=staging before launching.
  {
    // MAX_ENV_VAR_LEN covers typical values; very long strings are silently
    // ignored (env_len will equal 0 when the buffer is too small).
    static constexpr DWORD kMaxEnvVarLen = 256;
    wchar_t env_buf[kMaxEnvVarLen] = {};
    DWORD env_len = ::GetEnvironmentVariableW(L"TRIVIA_TYCOON_ENV",
                                               env_buf,
                                               kMaxEnvVarLen);
    if (env_len > 0) {
      std::string env_value = Utf8FromUtf16(env_buf);
      command_line_arguments.push_back("--trivia-env=" + env_value);
      LogMessage(LogLevel::kInfo, "TRIVIA_TYCOON_ENV = " + env_value);
    }
  }

  // Preload application resources before creating the window so they are
  // available immediately on first paint.
  LogMessage(LogLevel::kInfo, "Preloading application resources...");
  // Resource handles (icons, cursors) are loaded by the window class
  // registrar; requesting them here primes the OS cache.
  ::LoadIcon(nullptr, IDI_APPLICATION);
  ::LoadCursor(nullptr, IDC_ARROW);
  LogMessage(LogLevel::kInfo, "Resource preload complete.");

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Trivia Tycoon", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
