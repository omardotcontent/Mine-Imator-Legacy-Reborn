#ifndef AppName
#define AppName "Mine-Imator: Legacy Reborn"
#endif
#ifndef AppExeName
#define AppExeName "Mine-imator.exe"
#endif
#ifndef AppSourceDir
#define AppSourceDir "Mine-imator"
#endif
#ifndef AppVersion
#define AppVersion "1.0.0"
#endif
#ifndef AppYear
#define AppYear "2026"
#endif
#define AppURL "https://github.com/omardotcontent/Mine-Imator-Legacy-Reborn"
#define AppPublisher "OmarDotContent"
#define AppPublisherURL "https://github.com/omardotcontent"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)

AppId={{EF61A1AA-5F85-4E94-ACC6-D5650A312AE6}}
AppName={#AppName}
AppVersion={#AppVersion}
ApPVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppPublisherURL}
AppContact={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
AppCopyright=(c){#AppYear} {#AppPublisher}
DefaultDirName={userpf}\Mine-Imator Legacy Reborn
DefaultGroupName={#AppName}
OutputDir=.
OutputBaseFilename=installer
LicenseFile=license.txt
SetupIconFile=icon.ico
WizardImageFile=install.bmp
Compression=lzma
SolidCompression=yes
AllowNoIcons=yes
DisableDirPage=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#AppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{commondesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
Filename: {cmd}; Parameters: "/C Move ""{app}\unins000.exe"" ""{app}\Uninstall {#AppName}.exe"""; StatusMsg: Installing {#AppName}...; Flags: RunHidden WaitUntilTerminated
Filename: {cmd}; Parameters: "/C Move ""{app}\unins000.dat"" ""{app}\Uninstall {#AppName}.dat"""; StatusMsg: Installing {#AppName}...; Flags: RunHidden WaitUntilTerminated
Filename: {cmd}; Parameters: "/C Move ""{app}\unins000.msg"" ""{app}\Uninstall {#AppName}.msg"""; StatusMsg: Installing {#AppName}...; Flags: RunHidden WaitUntilTerminated
