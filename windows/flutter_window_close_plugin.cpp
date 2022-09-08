#include "include/flutter_window_close/flutter_window_close_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <sstream>

namespace
{

    using flutter::EncodableMap;
    using flutter::EncodableValue;

    static LRESULT CALLBACK WindowCloseWndProc(HWND hWnd, UINT iMessage, WPARAM wParam, LPARAM lParam);
    static WNDPROC oldProc;
    static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

    class FlutterWindowClosePlugin : public flutter::Plugin
    {
    public:
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

        FlutterWindowClosePlugin();

        virtual ~FlutterWindowClosePlugin();

        void SetWindow(HWND handle);
        HWND GetWindow();

    private:
        HWND m_windowHandle;
        // Called when a method is called on this plugin's channel from Dart.
        void HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue> &method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    };

    // static
    void FlutterWindowClosePlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarWindows *registrar)
    {
        HWND handle = GetActiveWindow();
        oldProc = reinterpret_cast<WNDPROC>(GetWindowLongPtr(handle, GWLP_WNDPROC));
        SetWindowLongPtr(handle, GWLP_WNDPROC, (LONG_PTR)WindowCloseWndProc);

        channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(),
            "flutter_window_close_notification",
            &flutter::StandardMethodCodec::GetInstance());

        auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
            registrar->messenger(), "flutter_window_close",
            &flutter::StandardMethodCodec::GetInstance());

        auto plugin = std::make_unique<FlutterWindowClosePlugin>();
        plugin->SetWindow(handle);

        channel->SetMethodCallHandler(
            [plugin_pointer = plugin.get()](const auto &call, auto result)
            {
                plugin_pointer->HandleMethodCall(call, std::move(result));
            });

        registrar->AddPlugin(std::move(plugin));
    }

    FlutterWindowClosePlugin::FlutterWindowClosePlugin() {}

    FlutterWindowClosePlugin::~FlutterWindowClosePlugin() {}

    void FlutterWindowClosePlugin::SetWindow(HWND handle)
    {
        m_windowHandle = handle;
    }

    HWND FlutterWindowClosePlugin::GetWindow()
    {
        return m_windowHandle;
    }

    void FlutterWindowClosePlugin::HandleMethodCall(
        const flutter::MethodCall<flutter::EncodableValue> &method_call,
        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result)
    {
        if (method_call.method_name().compare("closeWindow") == 0)
        {
            if (m_windowHandle)
            {
                PostMessage(m_windowHandle, WM_CLOSE, 0, 0);
                result->Success(flutter::EncodableValue(nullptr));
            }
            else
            {
                result->Error("no_window", "The active window does not exist");
            }
        }
        else if (method_call.method_name().compare("destroyWindow") == 0)
        {
            if (m_windowHandle)
            {
                DestroyWindow(m_windowHandle);
                result->Success(flutter::EncodableValue(nullptr));
            }
            else
            {
                result->Error("no_window", "The active window does not exist");
            }
        }
        else
        {
            result->NotImplemented();
        }
    }

    LRESULT CALLBACK
    WindowCloseWndProc(HWND hWnd, UINT iMessage, WPARAM wparam, LPARAM lparam)
    {
        if (iMessage == WM_CLOSE)
        {
            auto args = std::make_unique<flutter::EncodableValue>(nullptr);
            channel_->InvokeMethod("onWindowClose", std::move(args));
            return 0;
        }
        if (iMessage == WM_POWERBROADCAST)
        {
            if (wparam == PBT_APMSUSPEND)
            {
                auto args = std::make_unique<flutter::EncodableValue>("sleep");
                channel_->InvokeMethod("onWindowsSleep", std::move(args));
            }
            else if (wparam == PBT_APMRESUMEAUTOMATIC)
            {
                auto args = std::make_unique<flutter::EncodableValue>("woke_up");
                channel_->InvokeMethod("onWindowsSleep", std::move(args));
            }

            return TRUE;
        }
        return oldProc(hWnd, iMessage, wparam, lparam);
    }

} // namespace

void FlutterWindowClosePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar)
{
    FlutterWindowClosePlugin::RegisterWithRegistrar(
        flutter::PluginRegistrarManager::GetInstance()
            ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
