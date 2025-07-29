package game.backend.system.macros;

import haxe.Json;
#if macro
import haxe.macro.Context;
import haxe.io.Path;
import sys.io.Process;
import haxe.macro.Expr;
import haxe.xml.Access;
import sys.io.File;
#end

typedef HaxeLibData = {
	name:String,
	?url:String,
	?license:String,
	?tags:Array<String>,
	?description:String,
	version:String,
	directory:String,
	?releasenote:String,
	?contributors:Array<String>,
	?dependencies:Dynamic,
	?dependecies:Dynamic,
	?classPath:String,
	?binaryversion:Int,
}

class HaxeLibsMacro {
	/**
	 * Returns the defined values
	 */
	public static var libs(get, never):Array<HaxeLibData>;

	// GETTER MACROS
	static function get_libs()
		return __getLibs();

	// INTERNAL MACROS
	static macro function __getLibs()
	{
		#if display
		return macro $v{[]};
		#else
		var libs:Array<HaxeLibData> = [];

		var project = new Access(Xml.parse(File.getContent('./project.xml')).firstElement());

		var lib:HaxeLibData;
		var name;
		libs.push({
			name: "haxe",
			version: haxe.macro.Context.definedValue("haxe"),
			directory: haxe.macro.Context.definedValue("haxe")
		});
		#if hl
		libs.push({
			name: "hl",
			version: haxe.macro.Context.definedValue("hl-ver"),
			directory: haxe.macro.Context.definedValue("hl-ver")
		});
		#end
		for (haxelib in project.nodes.haxelib)
		{
			name = haxelib.att.name;
			if (Context.defined(name.toLowerCase())) // checks if it is currently in use
			{
				lib = getHaxelib(name, haxelib.has.version ? haxelib.att.version : null);
				if (lib != null)
					libs.push(lib);
			}
		}
		libs.sort((i, y) -> return i.name > y.name ? 1 : -1);

		// for (haxelib in libs) Sys.println('$haxelib');
		return macro $v{libs};

		#end
	}
	#if macro
	static function getHaxelib(name:String, ?version:String):HaxeLibData
	{
		try
		{
			var subProcess = new Process('haxelib', ['libpath', version == null ? name : '$name:$version']);
			subProcess.exitCode(true);
			var path = subProcess.stdout.readAll().toString();
			while (StringTools.endsWith(path, "\r") || StringTools.endsWith(path, "\n"))
				path = path.substr(0, path.length - 2);
			while (StringTools.endsWith(path, "\\"))
				path = path.substr(0, path.length - 2);

			var data = Json.parse(File.getContent(Path.join([path, 'haxelib.json'])));
			var lib:HaxeLibData = {
				name: "|UNKNOWN|",
				version: "|N/A|",
				directory: #if linux Path.withoutDirectory(path) #else Path.withoutDirectory(Path.directory(path)) #end
			};
			// var field;
			for (i in Reflect.fields(data))
			{
				// field = Reflect.field(lib, i); // check is unvalid
				// if (field == null)
					Reflect.setField(lib, i, Reflect.field(data, i));
			}
			return lib;

			// var isGit       = Path.withoutDirectory(path) == 'git';
			// var isMercurial = Path.withoutDirectory(path) == 'mercurial';
			// if (isGit || isMercurial) return data.url ?? data.version ?? 'N/A';
			// else return data.version ?? 'N/A';
		}
		catch(e)
		{
			trace(e.details());
			return null;
		}
	}
	#end
}