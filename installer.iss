; Script para PulpiPrint Manager - Standalone
; ESTE SCRIPT INCLUYE TODAS LAS DEPENDENCIAS

#define MyAppName "PulpiPrint Manager"
#define MyAppVersion "1.0"
#define MyAppPublisher "PulpiPrint"
#define MyAppExeName "pulpiprint_program.exe"

[Setup]
; ID único de la app (No lo cambies en futuras actualizaciones)
AppId={{A2C3D4E5-F6G7-89H0-I1J2-K3L4M5N6O7P8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Icono del instalador (asegúrate que la ruta exista)
SetupIconFile=C:\Users\Manuel\Desktop\Folder\pulpiprint_program\windows\runner\resources\app_icon.ico
; Dónde se guarda el instalador final
OutputDir=C:\Users\Manuel\Desktop
OutputBaseFilename=Instalador_PulpiPrint_Manager_v1
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; --- EL SECRETO: ESTO COPIA TODO EL CONTENIDO DE LA CARPETA RELEASE ---
; Reemplaza la ruta de abajo con la ruta EXACTA a tu carpeta Release
Source: "C:\Users\Manuel\Desktop\Folder\pulpiprint_program\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; ----------------------------------------------------------------------

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent