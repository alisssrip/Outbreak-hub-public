class_name PCSX2_IniHelper
extends RefCounted

var ctx

const BASE_PATH := "/home/%s/.config/PCSX2/inis/"

func init(hndlr) -> void:
	ctx = hndlr

func get_path(filename: String) -> String:
	return ctx.paths.get_ini_path(filename)

func read(filename: String) -> String:
	if not FileAccess.file_exists(get_path("PCSX2.ini")):
		restore_ini()
	var path := get_path(filename)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var content := file.get_as_text()
	file.close()
	return content

func _write_bios_to_ini(bios_path: String) -> bool:
	var ini_path = ctx.paths.get_ini_path("PCSX2.ini")
	if not FileAccess.file_exists(ini_path):
		restore_ini()
		return false
	var f := FileAccess.open(ini_path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var bios_dir := bios_path.get_base_dir()
	var bios_file := bios_path.get_file()
	text = _set_ini_key(text, "Folders", "Bios", bios_dir)
	text = _set_ini_key(text, "Filenames", "BIOS", bios_file)
	text = _set_ini_key(text, "UI", "ConfirmShutdown", "false")
	var w := FileAccess.open(ini_path, FileAccess.WRITE)
	if w == null:
		Popups_Controller.instance.show_error(tr("POPUP_EMULATOR_ERROR_TITLE"), tr("POPUP_INI_WRITE_FAILED"))
		return false
	w.store_string(text)
	w.close()
	return true

func restore_ini() -> void:
	var path : String = ctx.paths.get_ini_path("PCSX2.ini")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		Log.d("ini restore failed: ", FileAccess.get_open_error(), " path: ", path)
		return
	file.store_string(_fill_tokens(ini_default))
	file.close()


func _fill_tokens(text: String) -> String:
	text = text.replace("%PS2_DNS%", Endpoints.ps2_dns())
	text = text.replace("%DNAS_HOST%", Endpoints.get_url("dnas_host"))
	text = text.replace("%KDDI_HOST%", Endpoints.get_url("kddi_host"))
	return text


func _set_ini_key(text: String, section: String, key: String, value: String) -> String:
	var lines := text.split("\n")
	var result := PackedStringArray()
	var in_section := false
	var key_written := false
	var section_found := false
	for line in lines:
		var stripped := line.strip_edges()
		if stripped.begins_with("[") and stripped.ends_with("]"):
			if in_section and not key_written:
				result.append(key + " = " + value)
				key_written = true
			in_section = stripped == "[" + section + "]"
			if in_section:
				section_found = true
			result.append(line)
			continue
		if in_section and stripped.begins_with(key + " ") or (in_section and stripped.begins_with(key + "=")):
			result.append(key + " = " + value)
			key_written = true
			continue
		result.append(line)
	if in_section and not key_written:
		result.append(key + " = " + value)
		key_written = true
	if not section_found:
		result.append("[" + section + "]")
		result.append(key + " = " + value)
	return "\n".join(result)

func write(filename: String, content: String) -> bool:
	var path := get_path(filename)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		Popups_Controller.instance.show_error(tr("POPUP_EMULATOR_ERROR_TITLE"), tr("POPUP_INI_WRITE_FAILED"))
		return false
	file.store_string(content)
	file.close()
	return true

func set_value(content: String, key: String, value: String) -> String:
	var lines := content.split("\n")
	for i in lines.size():
		var stripped := lines[i].strip_edges()
		if stripped.contains("="):
			var parts := stripped.split("=", true, 1)
			if parts[0].strip_edges() == key:
				lines[i] = "%s = %s" % [key, value]
				return "\n".join(lines)
	return content

func set_value_in_section(content: String, section: String, key: String, value: String) -> String:
	var lines := content.split("\n")
	var in_section := false
	var section_header := "[%s]" % section
	for i in lines.size():
		var stripped := lines[i].strip_edges()
		if stripped.begins_with("[") and stripped.ends_with("]"):
			in_section = (stripped == section_header)
			continue
		if in_section and stripped.contains("="):
			var parts := stripped.split("=", true, 1)
			if parts[0].strip_edges() == key:
				lines[i] = "%s = %s" % [key, value]
				return "\n".join(lines)
	return content

func insert_after_section(content: String, section: String, key: String, value: String) -> String:
	return content.replace("[%s]" % section, "[%s]\n%s = %s" % [section, key, value])

var ini_default: String = "[UI]
SettingsVersion = 1
InhibitScreensaver = true
ConfirmShutdown = false
StartPaused = false
PauseOnFocusLoss = false
StartFullscreen = false
DoubleClickTogglesFullscreen = true
HideMouseCursor = false
RenderToSeparateWindow = false
HideMainWindowWhenRunning = false
DisableWindowResize = false
PreferEnglishGameList = false
Theme = fusion
SetupWizardIncomplete = false
MainWindowGeometry = AdnQywADAAAAAAQAAAAEOAAACBkAAAbRAAAEAAAABDgAAAgZAAAG0QAAAAAAAAAAB4AAAAQAAAAEOAAACBkAAAbR
MainWindowState = AAAA/wAAAAD9AAAAAAAABBoAAAJuAAAABAAAAAQAAAAIAAAACPwAAAABAAAAAgAAAAEAAAAOAHQAbwBvAGwAQgBhAHIAAAAAAP////8AAAAAAAAAAA==
VerboseStatusBar = false
AdvancedSettingsWarningShown = true
ShowAdvancedSettings = true
Language = en-US
DisplayWindowGeometry = AdnQywADAAAAAAQAAAAEOAAAB9QAAAdcAAAEAAAABDgAAAfUAAAHXAAAAAAAAAAAB4AAAAQAAAAEOAAAB9QAAAdc


[Folders]
Bios = bios
Snapshots = snaps
Savestates = sstates
MemoryCards = memcards
Logs = logs
Cheats = cheats
Patches = patches
UserResources = resources
Cache = cache
Textures = textures
InputProfiles = inputprofiles
Videos = videos
DebuggerLayouts = debuggerlayouts
DebuggerSettings = debuggersettings


[EmuCore]
CdvdVerboseReads = false
CdvdDumpBlocks = false
CdvdPrecache = false
EnablePatches = true
EnableCheats = false
EnablePINE = true
EnableWideScreenPatches = false
EnableNoInterlacingPatches = false
EnableFastBoot = false
EnableFastBootFastForward = false
EnableThreadPinning = false
EnableRecordingTools = true
EnableGameFixes = true
SaveStateOnShutdown = false
UseSavestateSelector = true
EnableDiscordPresence = false
InhibitScreensaver = true
HostFs = false
BackupSavestate = true
McdFolderAutoManage = true
WarnAboutUnsafeSettings = true
ManuallySetRealTimeClock = false
UseSystemLocaleFormat = false
SavestateCompressionType = 2
SavestateCompressionRatio = 1
GzipIsoIndexTemplate = $(f).pindex.tmp
PINESlot = 28011
RtcYear = 0
RtcMonth = 1
RtcDay = 1
RtcHour = 0
RtcMinute = 0
RtcSecond = 0
BlockDumpSaveDirectory = 


[EmuCore/Speedhacks]
EECycleRate = 0
EECycleSkip = 0
fastCDVD = false
IntcStat = true
WaitLoop = true
vuFlagHack = true
vuThread = true
vu1Instant = true


[EmuCore/CPU]
FPU.DenormalsAreZero = true
FPU.Roundmode = 3
FPUDiv.DenormalsAreZero = true
FPUDiv.Roundmode = 0
VU0.DenormalsAreZero = true
VU0.Roundmode = 3
VU1.DenormalsAreZero = true
VU1.Roundmode = 3
ExtraMemory = false


[EmuCore/CPU/Recompiler]
EnableEE = true
EnableIOP = true
EnableEECache = false
EnableVU0 = true
EnableVU1 = true
EnableFastmem = true
PauseOnTLBMiss = false
vu0Overflow = true
vu0ExtraOverflow = false
vu0SignOverflow = false
vu0Underflow = false
vu1Overflow = true
vu1ExtraOverflow = false
vu1SignOverflow = false
vu1Underflow = false
fpuOverflow = true
fpuExtraOverflow = false
fpuFullMode = false


[EmuCore/GS]
SynchronousMTGS = false
VsyncEnable = false
DisableMailboxPresentation = false
ExtendedUpscalingMultipliers = false
VsyncQueueSize = 2
FramerateNTSC = 59.94
FrameratePAL = 50
AspectRatio = Auto 4:3/3:2
FMVAspectRatioSwitch = Off
ScreenshotSize = 0
ScreenshotFormat = 0
ScreenshotQuality = 90
OrganizeScreenshotsByGame = false
StretchY = 100
CropLeft = 0
CropTop = 0
CropRight = 0
CropBottom = 0
pcrtc_antiblur = true
disable_interlace_offset = false
pcrtc_offsets = false
pcrtc_overscan = false
IntegerScaling = false
UseDebugDevice = false
UseBlitSwapChain = false
DisableShaderCache = false
DisableFramebufferFetch = false
DisableVertexShaderExpand = false
SkipDuplicateFrames = false
OsdShowSpeed = false
OsdShowFPS = false
OsdShowVPS = false
OsdShowCPU = false
OsdShowGPU = false
OsdShowResolution = false
OsdShowGSStats = false
OsdShowIndicators = true
OsdShowSettings = false
OsdshowPatches = false
OsdShowInputs = false
OsdShowFrameTimes = false
OsdShowVersion = false
OsdShowHardwareInfo = false
OsdShowVideoCapture = true
OsdShowInputRec = true
OsdShowTextureReplacements = false
HWSpinGPUForReadbacks = false
HWSpinCPUForReadbacks = false
paltex = false
autoflush_sw = true
preload_frame_with_gs_data = false
mipmap = true
UserHacks = false
UserHacks_align_sprite_X = false
UserHacks_AutoFlushLevel = 0
UserHacks_CPU_FB_Conversion = false
UserHacks_ReadTCOnClose = false
UserHacks_DisableDepthSupport = false
UserHacks_DisablePartialInvalidation = false
UserHacks_Disable_Safe_Features = false
UserHacks_DisableRenderFixes = false
UserHacks_merge_pp_sprite = false
UserHacks_ForceEvenSpritePosition = false
UserHacks_BilinearHack = 0
UserHacks_NativePaletteDraw = false
UserHacks_TextureInsideRt = 0
UserHacks_EstimateTextureRegion = false
fxaa = false
ShadeBoost = false
DumpGSData = false
SaveRT = false
SaveFrame = false
SaveTexture = false
SaveDepth = false
SaveAlpha = false
SaveInfo = false
SaveTransferImages = false
SaveDrawStats = false
SaveFrameStats = false
DumpReplaceableTextures = false
DumpReplaceableMipmaps = false
DumpTexturesWithFMVActive = false
DumpDirectTextures = true
DumpPaletteTextures = true
LoadTextureReplacements = false
LoadTextureReplacementsAsync = true
PrecacheTextureReplacements = false
EnableVideoCapture = true
EnableVideoCaptureParameters = false
VideoCaptureAutoResolution = false
EnableAudioCapture = true
EnableAudioCaptureParameters = false
linear_present_mode = 1
deinterlace_mode = 0
OsdScale = 100
OsdMessagesPos = 1
OsdPerformancePos = 3
Renderer = -1
upscale_multiplier = 1
hw_mipmap = true
accurate_blending_unit = 0
filter = 2
texture_preloading = 2
GSDumpCompression = 2
HWDownloadMode = 0
CASMode = 0
CASSharpness = 50
dithering_ps2 = 2
MaxAnisotropy = 0
extrathreads = 3
extrathreads_height = 4
TVShader = 0
UserHacks_SkipDraw_Start = 0
UserHacks_SkipDraw_End = 0
UserHacks_HalfPixelOffset = 0
UserHacks_round_sprite_offset = 0
UserHacks_native_scaling = 0
UserHacks_TCOffsetX = 0
UserHacks_TCOffsetY = 0
UserHacks_CPUSpriteRenderBW = 0
UserHacks_CPUSpriteRenderLevel = 0
UserHacks_CPUCLUTRender = 0
UserHacks_GPUTargetCLUTMode = 0
TriFilter = -1
OverrideTextureBarriers = -1
ShadeBoost_Brightness = 50
ShadeBoost_Contrast = 50
ShadeBoost_Saturation = 50
ShadeBoost_Gamma = 50
ExclusiveFullscreenControl = -1
png_compression_level = 1
SaveDrawStart = 0
SaveDrawCount = 5000
SaveDrawBy = 1
SaveFrameStart = 0
SaveFrameCount = -1
SaveFrameBy = 1
CaptureContainer = mp4
VideoCaptureCodec = 
VideoCaptureFormat = 
VideoCaptureParameters = 
AudioCaptureCodec = 
AudioCaptureParameters = 
VideoCaptureBitrate = 6000
VideoCaptureWidth = 640
VideoCaptureHeight = 480
AudioCaptureBitrate = 192
Adapter = 
HWDumpDirectory = 
SWDumpDirectory = 
SyncToHostRefreshRate = false
UseVSyncForTiming = false


[SPU2/Debug]
Global_Enable = false
Show_Messages = false
Show_Messages_Key_On_Off = false
Show_Messages_Voice_Off = false
Show_Messages_DMA_Transfer = false
Show_Messages_AutoDMA = false
Show_Messages_CacheStats = false
Log_Register_Access = false
Log_DMA_Transfers = false
Log_WAVE_Output = false
Dump_Info = false
Dump_Memory = false
Dump_Regs = false


[SPU2/Output]
StandardVolume = 100
FastForwardVolume = 100
OutputMuted = false
Backend = Cubeb
SyncMode = TimeStretch
DriverName = 
DeviceName = 
ExpansionMode = Disabled
OutputLatencyMinimal = false
BufferMS = 50
OutputLatencyMS = 20
StretchSequenceLengthMS = 30
StretchSeekWindowMS = 20
StretchOverlapMS = 10
StretchUseQuickSeek = false
StretchUseAAFilter = false
ExpandBlockSize = 2048
ExpandCircularWrap = 90
ExpandShift = 0
ExpandDepth = 1
ExpandFocus = 0
ExpandCenterImage = 1
ExpandFrontSeparation = 1
ExpandRearSeparation = 1
ExpandLowCutoff = 40
ExpandHighCutoff = 90


[DEV9/Eth]
EthEnable = true
EthApi = Sockets
EthDevice = Auto
EthLogDHCP = false
EthLogDNS = false
InterceptDHCP = true
PS2IP = 192.168.0.30
Mask = 0.0.0.0
Gateway = 0.0.0.0
DNS1 = %PS2_DNS%
DNS2 = %PS2_DNS%
AutoMask = true
AutoGateway = true
ModeDNS1 = Manual
ModeDNS2 = Manual


[DEV9/Eth/Hosts]
Count = 3


[DEV9/Hdd]
HddEnable = false
HddFile = DEV9hdd.raw


[EmuCore/Gamefixes]
VuAddSubHack = false
FpuMulHack = false
XgKickHack = false
EETimingHack = false
InstantDMAHack = false
SoftwareRendererFMVHack = false
SkipMPEGHack = false
OPHFlagHack = false
DMABusyHack = false
VIFFIFOHack = false
VIF1StallHack = false
GIFFIFOHack = false
GoemonTlbHack = false
IbitHack = false
VUSyncHack = false
VUOverflowHack = false
BlitInternalFPSHack = false
FullVU0SyncHack = false


[EmuCore/Profiler]
Enabled = false
RecBlocks_EE = true
RecBlocks_IOP = true
RecBlocks_VU0 = true
RecBlocks_VU1 = true


[Debugger/Analysis]
RunCondition = If Debugger Is Open
GenerateSymbolsForIRXExports = true
AutomaticallySelectSymbolsToClear = true
ImportSymbolsFromELF = true
DemangleSymbols = true
DemangleParameters = true
FunctionScanMode = Scan From ELF
CustomFunctionScanRange = false
FunctionScanStartAddress = 
FunctionScanEndAddress = 
GenerateFunctionHashes = true


[Debugger/Analysis/SymbolSources]
Count = 0


[Debugger/Analysis/ExtraSymbolFiles]
Count = 0


[EmuCore/TraceLog]
Enabled = false
EE.bios = false
EE.memory = false
EE.giftag = false
EE.vifcode = false
EE.mskpath3 = false
EE.r5900 = false
EE.cop0 = false
EE.cop1 = false
EE.cop2 = false
EE.cache = false
EE.knownhw = false
EE.unknownhw = false
EE.dmahw = false
EE.ipu = false
EE.dmac = false
EE.counters = false
EE.spr = false
EE.vif = false
EE.gif = false
IOP.bios = false
IOP.memcards = false
IOP.pad = false
IOP.r3000a = false
IOP.cop2 = false
IOP.memory = false
IOP.knownhw = false
IOP.unknownhw = false
IOP.dmahw = false
IOP.dmac = false
IOP.counters = false
IOP.cdvd = false
IOP.mdec = false
MISC.sif = false


[Achievements]
Enabled = false
ChallengeMode = false
EncoreMode = false
SpectatorMode = false
UnofficialTestMode = false
Notifications = true
LeaderboardNotifications = true
SoundEffects = true
InfoSound = true
UnlockSound = true
LBSubmitSound = true
Overlays = true
LBOverlays = true
NotificationsDuration = 5
LeaderboardsDuration = 10
OverlayPosition = 8
NotificationPosition = 1
InfoSoundName = /usr/share/pcsx2/resources/sounds/achievements/message.wav
UnlockSoundName = /usr/share/pcsx2/resources/sounds/achievements/unlock.wav
LBSubmitSoundName = /usr/share/pcsx2/resources/sounds/achievements/lbsubmit.wav
Username = username
LoginTimestamp = 1784632605


[Filenames]
BIOS = SCPH-10000_BIOS_V1_JAP_100.BIN


[Framerate]
NominalScalar = 1
TurboScalar = 2
SlomoScalar = 0.5


[MemoryCards]
Slot1_Enable = true
Slot1_Filename = Complete.ps2
Slot2_Enable = true
Slot2_Filename = Mcd002.ps2
Multitap1_Slot2_Enable = false
Multitap1_Slot2_Filename = Mcd-Multitap1-Slot02.ps2
Multitap1_Slot3_Enable = false
Multitap1_Slot3_Filename = Mcd-Multitap1-Slot03.ps2
Multitap1_Slot4_Enable = false
Multitap1_Slot4_Filename = Mcd-Multitap1-Slot04.ps2
Multitap2_Slot2_Enable = false
Multitap2_Slot2_Filename = Mcd-Multitap2-Slot02.ps2
Multitap2_Slot3_Enable = false
Multitap2_Slot3_Filename = Mcd-Multitap2-Slot03.ps2
Multitap2_Slot4_Enable = false
Multitap2_Slot4_Filename = Mcd-Multitap2-Slot04.ps2


[Logging]
EnableSystemConsole = true
EnableFileLogging = false
EnableTimestamps = true
EnableVerbose = false
EnableEEConsole = false
EnableIOPConsole = true
EnableInputRecordingLogs = true
EnableControllerLogs = false
EnableLogWindow = false


[InputSources]
Keyboard = true
Mouse = true
SDL = true
SDLControllerEnhancedMode = true
SDLPS5PlayerLED = true


[Hotkeys]
ToggleFullscreen = Keyboard/Alt & Keyboard/Return
CycleAspectRatio = Keyboard/F6
CycleInterlaceMode = Keyboard/F5
ToggleMipmapMode = Keyboard/Insert
GSDumpMultiFrame = Keyboard/Control & Keyboard/Shift & Keyboard/F8
Screenshot = Keyboard/F8
GSDumpSingleFrame = Keyboard/Shift & Keyboard/F8
ToggleSoftwareRendering = Keyboard/F9
ZoomIn = Keyboard/Control & Keyboard/Plus
ZoomOut = Keyboard/Control & Keyboard/Minus
InputRecToggleMode = Keyboard/Shift & Keyboard/R
LoadStateFromSlot = 
SaveStateToSlot = 
NextSaveStateSlot = 
PreviousSaveStateSlot = 
OpenPauseMenu = 
ToggleFrameLimit = 
TogglePause = 
ToggleSlowMotion = 
ToggleTurbo = 
HoldTurbo = 


[Pad]
MultitapPort1 = false
MultitapPort2 = false
PointerXScale = 8
PointerYScale = 8


[Pad1]
Type = DualShock2
InvertL = 1
InvertR = 0
Deadzone = 0
AxisScale = 1.33
LargeMotorScale = 1
SmallMotorScale = 1
ButtonDeadzone = 0
PressureModifier = 0.5
Up = SDL-0/DPadUp
Right = SDL-0/DPadRight
Down = SDL-0/DPadDown
Left = SDL-0/DPadLeft
Triangle = SDL-0/FaceNorth
Circle = SDL-0/FaceEast
Cross = SDL-0/FaceSouth
Square = SDL-0/FaceWest
Select = SDL-0/Back
Start = SDL-0/Start
L1 = SDL-0/LeftShoulder
L2 = SDL-0/+LeftTrigger
R1 = SDL-0/RightShoulder
R2 = SDL-0/+RightTrigger
L3 = SDL-0/LeftStick
R3 = SDL-0/RightStick
LUp = SDL-0/-LeftY
LRight = SDL-0/-LeftX
LDown = SDL-0/+LeftY
LLeft = SDL-0/+LeftX
RUp = SDL-0/-RightY
RRight = SDL-0/-RightX
RDown = SDL-0/+RightY
RLeft = SDL-0/+RightX
Analog = SDL-0/Guide
LargeMotor = SDL-0/LargeMotor
SmallMotor = SDL-0/SmallMotor


[Pad2]
Type = None


[Pad3]
Type = None


[Pad4]
Type = None


[Pad5]
Type = None


[Pad6]
Type = None


[Pad7]
Type = None


[Pad8]
Type = None


[USB1]
Type = None


[USB2]
Type = None


[GameList]


[GameListTableView]
HeaderState = AAAA/wAAAAAAAAABAAAAAAAAAAIBAAAAAAAAAAAAAAALGAQAAAADAAAACgAAAGQAAAADAAAAZAAAAAQAAABLAAAEGAAAAAsBAQAAAAAAAAAAAAAAAAAAZP////8AAACEAAAAAAAAAAsAAAA3AAAAAQAAAAAAAABVAAAAAQAAAAAAAAHPAAAAAQAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAQAAAAAAAABfAAAAAQAAAAAAAABaAAAAAQAAAAAAAABQAAAAAQAAAAAAAAA8AAAAAQAAAAAAAAB4AAAAAQAAAAAAAAAAAAAAAQAAAAAAAAPoAAAAAAAAAAAAAAAAAAAAAAAAAAAB


[DEV9/Eth/Hosts/Host0]
Url = gate1.jp.dnas.playstation.org
Desc = DNAS
Address = %DNAS_HOST%
Enabled = false


[DEV9/Eth/Hosts/Host1]
Url = www01.kddi-mmbb.jp
Desc = NOSE
Address = %DNAS_HOST%
Enabled = false


[DEV9/Eth/Hosts/Host2]
Url = kddi-mmbb.jp
Desc = Server
Address = %KDDI_HOST%
Enabled = false


[Debugger/UserInterface]
WindowGeometry = AdnQywADAAAAAAVWAAAAAAAADF4AAAPtAAAFVgAAAAAAAAxeAAAD7QAAAAAAAAAACgAAAAVWAAAAAAAADF4AAAPt
"
