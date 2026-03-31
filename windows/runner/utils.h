#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Log levels for console output.
enum class LogLevel {
  kInfo,
  kWarning,
  kError,
  kVerbose,
};

// Creates a console for the process, and redirects stdout and stderr to
// it for both the runner and the Flutter library.
void CreateAndAttachConsole();

// Logs a message to the attached console at the given |level|.
void LogMessage(LogLevel level, const std::string& message);

// Takes a null-terminated wchar_t* encoded in UTF-16 and returns a std::string
// encoded in UTF-8. Returns an empty std::string on failure.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Gets the command line arguments passed in as a std::vector<std::string>,
// encoded in UTF-8. Returns an empty std::vector<std::string> on failure.
std::vector<std::string> GetCommandLineArguments();

// Returns true if |flag| (e.g. "--verbose") is present in |arguments|.
bool HasCommandLineFlag(const std::vector<std::string>& arguments,
                        const std::string& flag);

// Returns the value for |key| (e.g. "--log-level=debug") from |arguments|,
// or |default_value| if the key is not present.
std::string GetCommandLineFlagValue(const std::vector<std::string>& arguments,
                                    const std::string& key,
                                    const std::string& default_value = "");

#endif  // RUNNER_UTILS_H_
