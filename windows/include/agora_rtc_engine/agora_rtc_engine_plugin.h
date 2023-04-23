#ifndef FLUTTER_PLUGIN_AGORA_RTC_NG_PLUGIN_H_
#define FLUTTER_PLUGIN_AGORA_RTC_NG_PLUGIN_H_

#include <flutter_plugin_registrar.h>
#include <memory>
#include <vector>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

typedef void (OnFrameCallback)(std::vector<uint8_t> data, size_t width, size_t height);

#if defined(__cplusplus)
extern "C"
{
#endif

    FLUTTER_PLUGIN_EXPORT void AgoraRtcEnginePluginRegisterWithRegistrar(
        FlutterDesktopPluginRegistrarRef registrar);

    FLUTTER_PLUGIN_EXPORT void RegOnFrame(OnFrameCallback *cb);

#if defined(__cplusplus)
} // extern "C"
#endif

#endif // FLUTTER_PLUGIN_AGORA_RTC_NG_PLUGIN_H_
