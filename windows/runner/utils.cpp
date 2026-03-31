#include "utils.h"

#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>

#include <iostream>
#include <sstream>

void CreateAndAttachConsole() {
  if (::AllocConsole()) {
    FILE *unused;
    if (freopen_s(&unused, "CONOUT$", "w", stdout) != 0) {
      // Verbose error: failed to redirect stdout.
      ::OutputDebugStringA("[trivia_tycoon] WARNING: Failed to redirect stdout to console.\n");
    } else {
      _dup2(_fileno(stdout), 1);
    }
    if (freopen_s(&unused, "CONOUT$", "w", stderr) != 0) {
      // Verbose error: failed to redirect stderr.
      ::OutputDebugStringA("[trivia_tycoon] WARNING: Failed to redirect stderr to console.\n");
    } else {
      _dup2(_fileno(stdout), 2);
    }
    std::ios::sync_with_stdio();
    FlutterDesktopResyncOutputStreams();
    ::OutputDebugStringA("[trivia_tycoon] Console attached successfully.\n");
  } else {
    DWORD err = ::GetLastError();
    std::ostringstream msg;
    msg << "[trivia_tycoon] ERROR: AllocConsole failed with error code: " << err << "\n";
    ::OutputDebugStringA(msg.str().c_str());
  }
}

void LogMessage(LogLevel level, const std::string& message) {
  std::string prefix;
  switch (level) {
    case LogLevel::kInfo:    prefix = "[INFO]    "; break;
    case LogLevel::kWarning: prefix = "[WARNING] "; break;
    case LogLevel::kError:   prefix = "[ERROR]   "; break;
    case LogLevel::kVerbose: prefix = "[VERBOSE] "; break;
  }
  std::string full_message = "[trivia_tycoon] " + prefix + message + "\n";
  ::OutputDebugStringA(full_message.c_str());
  std::cout << full_message;
}

std::vector<std::string> GetCommandLineArguments() {
  // Convert the UTF-16 command line arguments to UTF-8 for the Engine to use.
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) {
    ::OutputDebugStringA("[trivia_tycoon] ERROR: CommandLineToArgvW returned nullptr.\n");
    return std::vector<std::string>();
  }

  std::vector<std::string> command_line_arguments;

  // Skip the first argument as it's the binary name.
  for (int i = 1; i < argc; i++) {
    command_line_arguments.push_back(Utf8FromUtf16(argv[i]));
  }

  ::LocalFree(argv);

  return command_line_arguments;
}

bool HasCommandLineFlag(const std::vector<std::string>& arguments,
                        const std::string& flag) {
  for (const auto& arg : arguments) {
    if (arg == flag) {
      return true;
    }
  }
  return false;
}

std::string GetCommandLineFlagValue(const std::vector<std::string>& arguments,
                                    const std::string& key,
                                    const std::string& default_value) {
  const std::string prefix = key + "=";
  for (const auto& arg : arguments) {
    if (arg.size() > prefix.size() &&
        arg.substr(0, prefix.size()) == prefix) {
      return arg.substr(prefix.size());
    }
  }
  return default_value;
}

std::string Utf8FromUtf16(const wchar_t* utf16_string) {
  if (utf16_string == nullptr) {
    return std::string();
  }
  unsigned int target_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      -1, nullptr, 0, nullptr, nullptr)
    -1; // remove the trailing null character
  int input_length = (int)wcslen(utf16_string);
  std::string utf8_string;
  if (target_length == 0 || target_length > utf8_string.max_size()) {
    return utf8_string;
  }
  utf8_string.resize(target_length);
  int converted_length = ::WideCharToMultiByte(
      CP_UTF8, WC_ERR_INVALID_CHARS, utf16_string,
      input_length, utf8_string.data(), target_length, nullptr, nullptr);
  if (converted_length == 0) {
    return std::string();
  }
  return utf8_string;
}
