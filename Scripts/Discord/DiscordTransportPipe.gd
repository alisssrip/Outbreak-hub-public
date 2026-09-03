class_name DiscordTransportPipe
extends RefCounted

const READY_TOKEN := "READY"

const BRIDGE := """$ErrorActionPreference='Stop'
$p=$null
for($i=0;$i -lt 10;$i++){
try{
$c=New-Object System.IO.Pipes.NamedPipeClientStream('.',"discord-ipc-$i",[System.IO.Pipes.PipeDirection]::InOut)
$c.Connect(500)
$p=$c
break
}catch{}
}
if($p -eq $null){[Console]::Out.WriteLine('FAIL');exit 1}
[Console]::Out.WriteLine('READY')
[Console]::Out.Flush()
while($true){
$line=[Console]::In.ReadLine()
if($line -eq $null){break}
if($line.Length -eq 0){continue}
$b=[Convert]::FromBase64String($line)
$p.Write($b,0,$b.Length)
$p.Flush()
$h=New-Object byte[] 8
$n=0
while($n -lt 8){$r=$p.Read($h,$n,8-$n);if($r -le 0){exit 1};$n+=$r}
$len=[BitConverter]::ToInt32($h,4)
$buf=New-Object byte[] $len
$n=0
while($n -lt $len){$r=$p.Read($buf,$n,$len-$n);if($r -le 0){exit 1};$n+=$r}
$o=New-Object byte[] (8+$len)
[Array]::Copy($h,0,$o,0,8)
[Array]::Copy($buf,0,$o,8,$len)
[Console]::Out.WriteLine([Convert]::ToBase64String($o))
[Console]::Out.Flush()
}"""

var _io: FileAccess
var _pid := -1

func open() -> bool:
	var res := OS.execute_with_pipe("powershell.exe", ["-NoProfile", "-NonInteractive", "-EncodedCommand", _encoded_command()], true)
	if res.is_empty():
		return false
	_pid = int(res.get("pid", -1))
	_io = res.get("stdio")
	if _io == null:
		close()
		return false
	if _io.get_line().strip_edges() != READY_TOKEN:
		close()
		return false
	return true

func send(op: int, payload: PackedByteArray) -> bool:
	if _io == null or not _io.is_open():
		return false
	var pkt := PackedByteArray()
	pkt.resize(8)
	pkt.encode_u32(0, op)
	pkt.encode_u32(4, payload.size())
	pkt.append_array(payload)
	_io.store_line(Marshalls.raw_to_base64(pkt))
	_io.flush()
	return _io.get_error() == OK

func recv():
	if _io == null or not _io.is_open():
		return null
	var line := _io.get_line().strip_edges()
	if line.is_empty():
		return null
	var raw := Marshalls.base64_to_raw(line)
	if raw.size() < 8:
		return null
	return {"op": raw.decode_u32(0), "data": raw.slice(8)}

func close() -> void:
	if _io != null:
		_io.close()
		_io = null
	if _pid > 0 and OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1

func _encoded_command() -> String:
	var utf16 := PackedByteArray()
	for b in BRIDGE.to_utf8_buffer():
		utf16.append(b)
		utf16.append(0)
	return Marshalls.raw_to_base64(utf16)
