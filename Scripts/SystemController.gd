class_name SystemController
extends Node

func bring_launcher_to_front() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_move_to_foreground()
	DisplayServer.window_request_attention()

func mute_emulator() -> void:
	_set_emulator_mute(true)

func unmute_emulator() -> void:
	_set_emulator_mute(false)

func _set_emulator_mute(mute: bool) -> void:
	match OS.get_name():
		"Windows":
			_mute_windows(mute)
		"Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			_mute_linux(mute)
		_:
			Log.d("[sysctl] mute unsupported on this OS")

func _mute_windows(mute: bool) -> void:
	var flag := "$true" if mute else "$false"
	var cmd := _PS_MUTE.replace("__FLAG__", flag)
	OS.create_process("powershell.exe", ["-NoProfile", "-NonInteractive", "-WindowStyle", "Hidden", "-Command", cmd])

const _PS_MUTE := """
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace Au {
 [ComImport,Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDevEnum {}
 [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"),InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] interface IMMDeviceEnumerator { int f();int GetDefaultAudioEndpoint(int d,int r,out IMMDevice e); }
 [Guid("D666063F-1587-4E43-81F1-B948E807363F"),InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] interface IMMDevice { int Activate(ref Guid id,int c,IntPtr p,out IAudioSessionManager2 m); }
 [Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"),InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] interface IAudioSessionManager2 { int a();int b();int GetSessionEnumerator(out IAudioSessionEnumerator e); }
 [Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"),InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] interface IAudioSessionEnumerator { int GetCount(out int c);int GetSession(int i,out IAudioSessionControl2 s); }
 [Guid("BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D"),InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] interface IAudioSessionControl2 { int a();int b();int c();int d();int e();int f();int g();int h();int i();int j();int GetProcessId(out uint pid);int k();int l(); }
 [Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8"),InterfaceType(ComInterfaceType.InterfaceIsIUnknown)] interface ISimpleAudioVolume { int SetMasterVolume(float l,ref Guid e);int GetMasterVolume(out float l);int SetMute(bool m,ref Guid e);int GetMute(out bool m); }
 public static class Vol {
  public static void Set(bool mute){
   var e=(IMMDeviceEnumerator)(new MMDevEnum());
   IMMDevice dev; e.GetDefaultAudioEndpoint(0,1,out dev);
   var iid=typeof(IAudioSessionManager2).GUID;
   IAudioSessionManager2 m; dev.Activate(ref iid,1,IntPtr.Zero,out m);
   IAudioSessionEnumerator en; m.GetSessionEnumerator(out en);
   int n; en.GetCount(out n);
   for(int k=0;k<n;k++){
    IAudioSessionControl2 s; en.GetSession(k,out s);
    uint pid; s.GetProcessId(out pid);
    try{ var p=System.Diagnostics.Process.GetProcessById((int)pid);
     if(p.ProcessName.ToLower().Contains("pcsx2")){ var sav=(ISimpleAudioVolume)s; Guid g=Guid.Empty; sav.SetMute(mute,ref g); } }catch{}
   }
  }
 }
}
"@
[Au.Vol]::Set(__FLAG__)
"""

func _mute_linux(mute: bool) -> void:
	var pid := _find_pcsx2_pid_linux()
	if pid == "":
		Log.d("[sysctl] pcsx2 not found")
		return
	if not _has_command("pactl"):
		Log.d("[sysctl] pactl not found")
		return
	var flag := "1" if mute else "0"
	var script := "pactl list sink-inputs | awk -v pid=" + pid + " -v m=" + flag + " '/Sink Input #/{id=$3; gsub(\"#\",\"\",id)} /application.process.id/{if($0 ~ (\"\\\"\" pid \"\\\"\")){system(\"pactl set-sink-input-mute \" id \" \" m)}}'"
	OS.execute("bash", ["-c", script], [])

func _find_pcsx2_pid_linux() -> String:
	var out := []
	OS.execute("pgrep", ["-i", "pcsx2"], out)
	if out.is_empty() or out[0].strip_edges() == "":
		return ""
	return out[0].strip_edges().split("\n")[0]

func _has_command(cmd: String) -> bool:
	var out := []
	var code := OS.execute("bash", ["-c", "command -v " + cmd], out)
	return code == 0