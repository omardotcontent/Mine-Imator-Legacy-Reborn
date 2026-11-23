#ifndef AppName
#define AppName "Mine-Imator: Legacy Reborn"
#endif
#ifndef AppExeName
#define AppExeName "Mine-imator-Legacy-Reborn.exe"
#endif
#ifndef AppSourceDir
#define AppSourceDir "Mine-imator"
#endif
#ifndef AppMenuName
#define AppMenuName "Mine-Imator Legacy Reborn"
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

AppId=OmarDotContent.MineImator.LegacyReborn
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
DefaultGroupName={#AppMenuName}
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\{#AppExeName}
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
Name: "{group}\{#AppMenuName}"; Filename: "{app}\{#AppExeName}"; AppUserModelID: "OmarDotContent.MineImator.LegacyReborn"
Name: "{autodesktop}\{#AppMenuName}"; Filename: "{app}\{#AppExeName}"; AppUserModelID: "OmarDotContent.MineImator.LegacyReborn"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
