# Windows Development Setup

MedicoHub Windows desktop builds require the Visual Studio C++ desktop toolchain. If these components are missing, Flutter may fail during plugin compilation with errors such as:

```text
Cannot open include file: 'atlstr.h': No such file or directory
```

Install or verify the following components in Visual Studio Installer:

- MSVC v143 VS 2022 C++ x64/x86 build tools
- C++ ATL for latest v143 build tools
- C++ MFC for latest v143 build tools
- Windows 10/11 SDK

Recommended validation commands:

```powershell
flutter doctor -v
Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC" -Recurse -Filter atlstr.h
Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC" -Recurse -Filter afxwin.h
```

After installing the components, rebuild the Windows app:

```powershell
cd "C:\Users\drpha\Documents\Aster\neurolitApp\neurolitApp-April23\doctor_forum_app\frontend_flutter"
flutter clean
flutter pub get
flutter run -d windows
```
