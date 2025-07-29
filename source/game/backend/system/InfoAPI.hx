package game.backend.system;

#if extension-androidtools
import extension.androidtools.os.Build;
#end
import game.backend.utils.native.HiddenProcess;

@:unreflective
@:final class InfoAPI
{
	//** Coders/Bug Testers **/
	public static final devsCodes:Array<String> = [ // old idea with bios codes brrrr
		'',	// Redar13
		'',	// ItzRanbins
	];

	public static var osInfo:String;
	public static var cpuName:String;
	public static var cpuNumCores:Int = -1;
	public static var cpuNumLogProc:Int = -1;
	public static var cpuMaxClockSpeed:String;
	public static var gpuName:String;
	public static var vRAM:String;
	public static var totalMem:Int;
	public static var totalMemStr:String;
	public static var memType:String = "NaN";
	public static var gpuMaxSize:Int;
	public static var serialNumber:String;

	public static var SOC_MODEL:String;
	public static var SKU:String;
	public static var SDK:String;

	public static var userName:String = '???';

	public static var devUser(default, null):Bool = true;

	public static function init(){
		userName = getUsername();

		#if (linux && cpp)
		var processResult = runProccess("cat /etc/os-release");
		var osName = "";
		var osVersion = "";
		for (line in processResult.split("\n")) {
			if (line.startsWith("PRETTY_NAME=")) {
				var index = line.indexOf('"');
				if (index != -1)
					osName = line.substring(index + 1, line.lastIndexOf('"'));
				else {
					var arr = line.split("=");
					arr.shift();
					osName = arr.join("=");
				}
			}
			if (line.startsWith("VERSION=")) {
				var index = line.indexOf('"');
				if (index != -1)
					osVersion = line.substring(index + 1, line.lastIndexOf('"'));
				else {
					var arr = line.split("=");
					arr.shift();
					osVersion = arr.join("=");
				}
			}
		}
		if (osName.length > 0)
			osInfo = '${osName} ${osVersion}'.trim();
		#else
		if (
			lime.system.System.platformLabel != null
			&& lime.system.System.platformLabel.length > 0
			&& lime.system.System.platformVersion != null
			&& lime.system.System.platformVersion.length > 0
		)
			osInfo = '${lime.system.System.platformLabel.replace(lime.system.System.platformVersion, "").trim()} ${lime.system.System.platformVersion}';
		else
			Log('Unable to grab OS Label', RED);
		#end

		@:privateAccess
		{
			if (flixel.FlxG.stage.context3D != null && flixel.FlxG.stage.context3D.gl != null)
			{
				gpuName = Std.string(flixel.FlxG.stage.context3D.gl.getParameter(flixel.FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim();

				gpuMaxSize = FlxG.bitmap.maxTextureSize;

				if(openfl.display3D.Context3D.__glMemoryTotalAvailable != -1)
				{
					var vRAMBytes:UInt = cast flixel.FlxG.stage.context3D.gl.getParameter(openfl.display3D.Context3D.__glMemoryTotalAvailable);
					if (vRAMBytes == 1000 || vRAMBytes == 1 || vRAMBytes <= 0)
						Log('Unable to grab GPU VRAM', RED);
					else
						vRAM = CoolUtil.formatBytes(vRAMBytes * 1000);
				}
			}
			else
			{
				Log('Unable to grab GPU Info', RED);
			}
		}

		#if cpp
		#if windows
		cpuName = runProccess("wmic cpu get name").split("\n")[1];
		final cpuNumCoresStr = runProccess("wmic cpu get numberofcores").split("\n")[1];
		if (cpuNumCoresStr != null && cpuNumCoresStr != 'Unknown')
			try
			{
				cpuNumCores = Std.parseInt(cpuNumCoresStr);
			}
			catch(e){}

		final cpuNumLogProcStr = runProccess("wmic cpu get numberoflogicalprocessors").split("\n")[1];
		if (cpuNumLogProcStr != null && cpuNumLogProcStr != 'Unknown')
			try
			{
				cpuNumLogProc = Std.parseInt(cpuNumLogProcStr);
			}
			catch(e){}

		cpuMaxClockSpeed = runProccess("wmic cpu get maxclockspeed").split("\n")[1];
		serialNumber = runProccess("wmic bios get serialnumber").split("\n")[1];

		/*
		#if cpp
		try{
			totalMem = Std.parseInt(runProccess("wmic ComputerSystem get TotalPhysicalMemory").split("\n")[1]);
			Log(totalMem, RED);
		}catch(e)
		#else
		Log('Unable to grab RAM Amount', RED);
		#end{
			totalMem = Std.int(Math.pow(4, 32));
		}
		// totalMem = Std.int(totalMem / 1024);
		totalMemStr = totalMem.getSizeString();
		*/
		var memoryMap:Map<Int, String> = [
			0 => "Unknown",
			1 => "Other",
			2 => "DRAM",
			3 => "Synchronous DRAM",
			4 => "Cache DRAM",
			5 => "EDO",
			6 => "EDRAM",
			7 => "VRAM",
			8 => "SRAM",
			9 => "RAM",
			10 => "ROM",
			11 => "Flash",
			12 => "EEPROM",
			13 => "FEPROM",
			14 => "EPROM",
			15 => "CDRAM",
			16 => "3DRAM",
			17 => "SDRAM",
			18 => "SGRAM",
			19 => "RDRAM",
			20 => "DDR",
			21 => "DDR2",
			22 => "DDR2 FB-DIMM",
			24 => "DDR3",
			25 => "FBD2",
			26 => "DDR4"
		];
		var memoryOutput:Int = -1;
		final result = runProccess("wmic memorychip get SMBIOSMemoryType");
		if (result != 'Unknown') memoryOutput = Std.int(Std.parseFloat(result.split("\n")[1]));
		if (memoryMap.exists(memoryOutput))
			memType = memoryMap[memoryOutput];
		#elseif linux
		cpuName = runProccess("cat /proc/cpuinfo");
		for (line in cpuName.split("\n"))
		{
			if (line.indexOf("model name") == 0)
			{
				cpuName = line.substring(line.indexOf(":") + 2);
				break;
			}
		}
		var lines = runProccess("sudo dmidecode --type 17").split("\n");
		for (line in lines)
		{
			if (line.indexOf("Type:") == 0)
			{
				memType = line.substring("Type:".length).trim();
				break;
			}
		}
		#end

		#end

		#if extension-androidtools
		SOC_MODEL = Build.SOC_MODEL;
		SKU = Build.SKU;
		SDK = VERSION.SDK;
		#end

		//** It should be removed upon release. **/
		// devUser = devsName.contains(userName);
		devUser = serialNumber != null && serialNumber.toLowerCase() != 'default string' && devsCodes.contains(serialNumber);

		Log(devUser ? "Welcome To The Club Buddy" : "Sup", YELLOW);
		Log(userName, DARKYELLOW);
		// Log(userName, DARKYELLOW);
	}

	public static function runProccess(command:String){
		var r:String = 'Unknown';
		#if cpp
		try
		{
			var pr = new game.backend.utils.native.HiddenProcess(command);
			if (pr.exitCode() == 0) r = pr.stdout.readAll().toString().trim();
			pr.close();
		}
		catch(e)
		{
			e.getErrorInfo('Invalid "$command": ');
		}
		#end
		return r;
	}

	public static function getUsername()
	{
		var temp:String = null;
		#if extension-androidtools
		temp = Build.USER;
		#elseif sys
		var envs = Sys.environment();
		// trace(envs);
		temp = envs.get("USERNAME") ?? envs.get("USER");
		#end
		return temp ?? '???';
	}
}