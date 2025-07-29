package game.backend.system.macros;

#if macro
import haxe.crypto.Base64;
import haxe.crypto.Md5;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.macro.*;
import haxe.macro.Expr;
import haxe.zip.*;
import lime.tools.AssetType;
import sys.FileSystem;
import sys.io.File;
using StringTools;
#end

class AssetsMacro
{
	#if (!display && macro)
	static function getExcludesFromStr(source:String):Array<String>
	{
		if (source == null || source == "1" || source == "0") return [];
		return source.split("|")
				.map(i -> {
					i = i.trim();
					if (i.length == 0)
						return i;
					else
						return i.charAt(0) == "*" ? i.substring(1) : i;
				});
	}
	static function getEmbedExcludes():Array<String>
	{
		return getExcludesFromStr(Context.definedValue("EMBED_FILES") ?? "*.hx|*.lua");
	}

	public static var platformName(get, never):String;
	static var __platformName:String;
	static function get_platformName():String
	{
		if (__platformName == null)
		{
			if (Context.defined("hl"))
			{
				__platformName = "hl";
			}
			else
			{
				#if windows
				__platformName = "Windows";
				#elseif mac
				__platformName = "macOS";
				#elseif linux
				try
				{
					var process = new sys.io.Process("lsb_release", ["-is"]);
					__platformName = StringTools.trim(process.stdout.readLine().toString());
					process.close();
				}
				catch (e:Dynamic) {}
				#elseif ios
				__platformName = "iOS";
				#elseif android
				__platformName = "Android";
				#elseif air
				__platformName = "AIR";
				#elseif flash
				__platformName = "Flash Player";
				#elseif tvos
				__platformName = "tvOS";
				#elseif tizen
				__platformName = "Tizen";
				#elseif blackberry
				__platformName = "BlackBerry";
				#elseif firefox
				__platformName = "Firefox";
				#elseif webos
				__platformName = "webOS";
				#elseif nodejs
				__platformName = "Node.js";
				#elseif js
				__platformName = "HTML5";
				#end
			}
		}

		return __platformName;
	}

	static function getExportPath():String
	{
		return Path.join([
				Sys.getCwd(), (Context.definedValue("BUILD_DIR") ?? 'export'),
				platformName.toLowerCase()
			]);
	}

	static function getBinPath():String
	{
		return getExportPath() + "/bin";
	}

	public static function deleteExportFile(file:String)
	{
		file = Path.join([getBinPath(), file]);
		if (FileSystem.exists(file))
			try	FileSystem.deleteFile(file);
	}
	public static function placeAssets()
	{
		var ignoredExtensions:Array<String> = getExcludesFromStr(Context.definedValue("DEFAULT_EXCLUDE"));
		if (Context.defined("EMBED_FILES"))
			ignoredExtensions = ignoredExtensions.concat(getEmbedExcludes());
		ignoredExtensions.filter(i -> i.length > 0);
		// trace(ignoredExtensions);

		var storredAssets:Array<String> = [];
		var exportLocation:String = getBinPath();

		var cwd:String = Sys.getCwd();
		function fromSourceToExport(actual:String):String
		{
			return Path.join([exportLocation, actual.substring(cwd.length)]);
		}
		function readDirectory(rootDirPath:String, ?outputDir:String):Bool
		{
			outputDir ??= fromSourceToExport(rootDirPath);
			var dirFiles = FileSystem.readDirectory(rootDirPath);
			var destroyCurDir = FileSystem.exists(fromSourceToExport(rootDirPath));
			// trace('$rootDirPath: $dirFiles');
			for (path in dirFiles)
			{
				var actual = rootDirPath + "/" + path; // Path.join([rootDirPath, path])

				if (FileSystem.isDirectory(actual))
				{
					// trace(actual);
					// var checkFolderPath = fromSourceToExport(actual);
					var checkFolderPath = actual.substring(cwd.length);
					checkFolderPath = checkFolderPath.substring(checkFolderPath.indexOf("/") + 1, checkFolderPath.length);
					checkFolderPath = outputDir + "/" + checkFolderPath;
					try
					{
						if (!FileSystem.exists(checkFolderPath))
							FileSystem.createDirectory(checkFolderPath);
						var childIsDeleted = readDirectory(actual, outputDir);
						if (!childIsDeleted)
							destroyCurDir = false;
					}
					catch(e:haxe.Exception)
					{
						var mesg = '[WARNING]: Error creating directory $checkFolderPath (${e.toString()})';
						Context.warning(mesg, Context.currentPos());
						// trace(mesg);
					}
				}
				else
				{
					// trace(actual);
					var ignored = false;
					for (i in ignoredExtensions)
					{
						if (actual.startsWith(i) || actual.endsWith(i))
						{
							// trace(actual);
							ignored = true;
							break;
						}
					}
					if (ignored)
						continue;

					destroyCurDir = false;
					// storredAssets.push(actual.substring(cwd.length));

					// var exportPath = fromSourceToExport(actual);
					var exportPath = actual.substring(cwd.length);
					storredAssets.push(exportPath);

					exportPath = exportPath.substring(exportPath.indexOf("/") + 1, exportPath.length);
					exportPath = outputDir + "/" + exportPath;
					// trace(exportPath.substring(exportLocation.length));
					// trace(actual.substring(cwd.length));
					try
					{
						if (!FileSystem.exists(exportPath))
						{
							// trace(exportPath);
							File.copy(actual, exportPath);
						}
						else if (FileSystem.stat(actual).mtime.getTime() > FileSystem.stat(exportPath).mtime.getTime())
						{
							// trace(exportPath);
							File.saveBytes(exportPath, File.getBytes(actual));
						}
					}
					catch(e:haxe.Exception)
					{
						var mesg = '[WARNING]: Error while transferring file $actual (${e.toString()})';
						Context.warning(mesg, Context.currentPos());
						// trace(mesg);
					}
				}
			}
			if (destroyCurDir)
				FileSystem.deleteDirectory(fromSourceToExport(rootDirPath));
			return destroyCurDir;
		}

		var mainAssetsFolder = Path.join([cwd, 'assets']);

		readDirectory(mainAssetsFolder);
		if (!Context.defined("RELEASE_BUILD") || !Context.defined("ZIPLIBS_ALLOWED"))
		{
			readDirectory(Path.join([cwd, 'secret_assets']), fromSourceToExport(mainAssetsFolder));
		}

		if (Context.defined("USE_SYS_ASSETS") && Context.defined("RELEASE_BUILD"))
		{
			Context.addResource("TWAssets_Paths", Bytes.ofString(storredAssets.join(",")));
			// trace(storredAssets[0]);
		}
	}
	public static function zipSecretFiles()
	{
		var exportLocation:String = getExportPath();
		var neededToSave = getSecretZipFiles();
		function fromSourceToExport(actual:String):String
		{
			return Path.join([exportLocation, "bin", actual]);
		}
		if (!Context.defined("UPDATE_EMDASSETS") && FileSystem.exists(fromSourceToExport(neededToSave[0])))
		{
			return;
		}
		// if (runProccess("tar") == null)
		// {
		// 	trace("Invalid tar");
		// 	return;
		// }

		// var winrarPath = "\"C:\\Program Files\\WinRAR\\WinRAR.exe\"";
		// var winrarPath = "\"C:\\Program Files\\WinRAR\\rar.exe\"";
		var cwd:String = Sys.getCwd();
		var filesRaw = getFiles(["assets"], null, getEmbedExcludes());
		for (key => bytes in getFiles(["secret_assets"], ["secret_assets"]))
			filesRaw.set(key, bytes);
		var filesPaths = [for (i in filesRaw.keys()) i];

		if (filesPaths.length == 0)
		{
			return;
		}

		filesPaths.sort((a, b) -> a > b ? 1 : a < b ? -1 : 0);
		// for (i in 0...(filesPaths.length > 10 ? 10 : filesPaths.length))
		// {
		// 	trace(filesPaths[i]);
		// }
		var totalFilesSize:UInt = 0;
		for (i in filesRaw)
			totalFilesSize += i.length;
		var decBytes = Math.round(totalFilesSize / neededToSave.length);
		// var tempFile = "UPDATE HAXE TO 4.3.4.txt";
		var filePath;
		for (i in 0...neededToSave.length)
		{
			var filePath = neededToSave[i];
			var resources:List<Entry> = new List();
			var totalBytes:UInt = 0;

			var iFilePath;
			var iBytes;
			while (totalBytes < decBytes && filesPaths.length > 0)
			{
				iFilePath = filesPaths.shift();
				iBytes = filesRaw.get(iFilePath);
				if (iBytes == null) return;
				// iBytes = Bytes.ofString(iBytes.toString(), UTF8);
				// #if windows
				// iFilePath = iFilePath.replace("/", "\\");
				// #end
				resources.add({
					// fileName: Bytes.ofString(iFilePath, UTF8).toString(),
					fileName: iFilePath,
					fileSize: iBytes.length,
					fileTime: Date.now(),
					compressed: false,
					dataSize: iBytes.length,
					data: iBytes,
					// crc32: haxe.crypto.Crc32.make(iBytes),
					crc32: null,
					extraFields: null,
				});
				totalBytes += iBytes.length;
			}

			var tempFolderPath = Path.join([exportLocation, "__temp" + i]);
			var toExport = fromSourceToExport(filePath);

			deleteFolder(tempFolderPath); // delete prev temp archive

			if (FileSystem.exists(toExport)) // delete prev hidden archive
				try FileSystem.deleteFile(toExport);

			var toExportObj = new Path(toExport);
			toExportObj.ext = "zip";
			toExportObj.file += "_temp";
			toExport = toExportObj.toString();

			// #if windows
			// toExport = toExport.replace("/", "\\");
			// #end

			trace('$toExport: ${resources.length} files');

			// force create new zip archive
			if (FileSystem.exists(toExport))
				try FileSystem.deleteFile(toExport);

			// runProccess('tar -c -f ${toExport} ${tempFile}');
			// runProccess('tar --delete -f ${toExport} ${tempFile}');

			createFile(tempFolderPath);
			// runProccess('${winrarPath} a -afzip ${toExport} ${tempFile}');
			// runProccess('${winrarPath} d ${toExport} ${tempFile}');
			// if (runProccess('tar -c ${toExport}') != null)
			{
				for (index => i in resources)
				{
					createFile(Path.join([tempFolderPath, i.fileName]), i.data);
					// var file = Path.join([cwd, i.fileName]).replace("/", "\\");
					// runProccess('tar -u -f ${toExport} ${i.fileName}');
					// runProccess('${winrarPath} a -afzip ${toExport} ${file}');
					// trace(toExport);
					// trace(Path.join([cwd, i.fileName]));
					// trace('"${i.fileName}" -> "${toExport}"');
					// Sys.sleep(0.1);
				}
			}
			// else
			// {
			// 	trace('WARN: Could not create "$toExport"');
			// }
			Sys.setCwd(tempFolderPath);
			runProccess('tar -cf ${toExport} ${"*.*"} --format cpio');
			Sys.setCwd(cwd);
			openFileInExplorer(toExport);
			// runProccess('${winrarPath} f -zip ${toExport}');

			// var o:haxe.io.BytesOutput = new haxe.io.BytesOutput();
			// var zipWriter:Writer = new Writer(o);
			// zipWriter.write(Lambda.list(resources));
			// var bytes = o.getBytes();
			// // trace(bytes.toString());
			// File.saveBytes(fromSourceToExport(filePath), bytes);
		}
		if (filesPaths.length > 0)
		{
			Context.warning(Std.string(filesPaths), Context.currentPos());
			trace(filesPaths);
		}

		trace("\x1B[1mRecreate the archives yourself!\x1B[0m"); // we probably don't need to use compression mode
	}
	public static function runProccess(command:String){
		var r:String = null;
		try
		{
			var pr = new sys.io.Process(command);
			if (pr.exitCode() == 0) r = pr.stdout.readAll().toString().trim();
			pr.close();
		}
		catch(e)
		{
			trace('$e | Invalid "$command": ');
		}
		return r;
	}
	public static function openFileInExplorer(path:String):Void
	{
		if (!FileSystem.exists(path))
		{
			//	throw 'Path does not exist: "$path"';
			return;
		}

		#if windows
		Sys.command('explorer', ['/select,', path.replace('/', '\\')]);
		#elseif mac
		Sys.command('open', ['-R', path]);
		#elseif linux
		// TODO: unsure of the linux equivalent to opening a folder and then "selecting" a file.
		Sys.command('open', [path]);
		#end
	}

	public static function createFile(file:String, ?bytes:Bytes):Void
	{
		var _dir = "";
		var structs = file.split("/");
		for (i in 0...structs.length)
		{
			if (i == 0)
				_dir = structs[i];
			else
				_dir += '/${structs[i]}';

			try
			{
				if (i == structs.length - 1 && bytes != null)
				{
					File.saveBytes(_dir, bytes);
				}
				else
				{
					if (!FileSystem.exists(_dir))
					{
						FileSystem.createDirectory(_dir);
					}
					else if (!FileSystem.isDirectory(_dir))
					{
						FileSystem.deleteFile(_dir);
						FileSystem.createDirectory(_dir);
					}
				}
			}
		}

	}
	public static function deleteFolder(delete:String)
	{
		if (!FileSystem.exists(delete))
			return;
		try
		{
			final files = FileSystem.readDirectory(delete);
			if (files.length == 0)
			{
				if (FileSystem.isDirectory(delete))
				{
					FileSystem.deleteDirectory(delete);
				}
				else
				{
					FileSystem.deleteFile(delete);
				}
			}
			else
			{
				for (file in files)
				{
					if (FileSystem.isDirectory(delete + "/" + file))
					{
						deleteFolder(delete + "/" + file);
						FileSystem.deleteDirectory(delete + "/" + file);
					}
					else
					{
						FileSystem.deleteFile(delete + "/" + file);
					}
				}
			}
		}
	}

	/*
	public static function fixManifestResources()
	{
		var manifestResourcesPath = '${getExportPath()}/haxe/ManifestResources.hx';
		var manifestResourcesContext = File.getContent(manifestResourcesPath);

		var validFiles = [for (i in getFiles(["assets", "secret_assets", "embedAssets"]).keys()) i];
		validFiles.sort((a, b) -> a > b ? 1 : a < b ? -1 : 0);

		var path;
		var startPrefixes = ["@:image(\"", "@:file(\"", "@:font(\""];
		var endPrefix = "\")";
		// var regex = new EReg('@:(image|file|font)\\(\\"(.*)\\"\\)', "");
		var preLastMatch = 0;
		var lastMatch = 0;
		var startPathIndx = 0;
		var endPathIndx = 0;

		// while (regex.matchSub(manifestResourcesContext, lastMatch))
		while ((lastMatch = manifestResourcesContext.indexOf("@:", lastMatch)) != -1)
		{
			path = null;
			for (i in startPrefixes)
				if (manifestResourcesContext.substr(lastMatch).startsWith(i))
				{
					startPathIndx = lastMatch + i.length;
					endPathIndx = manifestResourcesContext.indexOf(endPrefix, lastMatch);
					path = manifestResourcesContext.substring(startPathIndx, endPathIndx);
					break;
				}
			if (path == null) continue;

			// path = regex.matched(2);
			// position = regex.matchedPos();
			preLastMatch = lastMatch;

			if (validFiles.indexOf(path) == -1)
			{
				trace(path);
				// for (i in validFiles)
				// 	if (i.length == path.length)
				// 	{
				// 		manifestResourcesContext = manifestResourcesContext.substr(0, position.pos) + i + manifestResourcesContext.substring(lastMatch, position.pos);
				// 		trace(i);
				// 		break;
				// 	}
			}
			// else
			// {
			// 	trace(path);
			// }
		}

		// File.saveContent(manifestResourcesPath, manifestResourcesContext);
	}
	*/
	#end

	// public static macro function getEmbedtFiles()
	// {
	// 	return macro $v{[for (key => bytes in getFiles(getEmbedExcludes())) key => Base64.encode(bytes)]};
	// }
	public static macro function getSecretZipFilesMacro()
	{
		return macro $v{getSecretZipFiles()};
	}
	static function getSecretZipFiles()
	{
		/*
		⠀⠀⠀⠀⠀⢀⣤⠖⠒⠒⠒⢒⡒⠒⠒⠒⠒⠒⠲⠦⠤⢤⣤⣄⣀⠀⠀⠀⠀⠀
		⠀⠀⠀⠀⣠⠟⠀⢀⠠⣐⢭⡐⠂⠬⠭⡁⠐⠒⠀⠀⣀⣒⣒⠐⠈⠙⢦⣄⠀⠀
		⠀⠀⠀⣰⠏⠀⠐⠡⠪⠂⣁⣀⣀⣀⡀⠰⠀⠀⠀⢨⠂⠀⠀⠈⢢⠀⠀⢹⠀⠀
		⠀⣠⣾⠿⠤⣤⡀⠤⡢⡾⠿⠿⠿⣬⣉⣷⠀⠀⢀⣨⣶⣾⡿⠿⠆⠤⠤⠌⡳⣄
		⣰⢫⢁⡾⠋⢹⡙⠓⠦⠤⠴⠛⠀⠀⠈⠁⠀⠀⠀⢹⡀⠀⢠⣄⣤⢶⠲⠍⡎⣾
		⢿⠸⠸⡇⠶⢿⡙⠳⢦⣄⣀⠐⠒⠚⣞⢛⣀⡀⠀⠀⢹⣶⢄⡀⠀⣸⡄⠠⣃⣿
		⠈⢷⣕⠋⠀⠘⢿⡶⣤⣧⡉⠙⠓⣶⠿⣬⣀⣀⣐⡶⠋⣀⣀⣬⢾⢻⣿⠀⣼⠃
		⠀⠀⠙⣦⠀⠀⠈⠳⣄⡟⠛⠿⣶⣯⣤⣀⣀⣏⣉⣙⣏⣉⣸⣧⣼⣾⣿⠀⡇⠀
		⠀⠀⠀⠘⢧⡀⠀⠀⠈⠳⣄⡀⣸⠃⠉⠙⢻⠻⠿⢿⡿⢿⡿⢿⢿⣿⡟⠀⣧⠀
		⠀⠀⠀⠀⠀⠙⢦⣐⠤⣒⠄⣉⠓⠶⠤⣤⣼⣀⣀⣼⣀⣼⣥⠿⠾⠛⠁⠀⢿⠀
		⠀⠀⠀⠀⠀⠀⠀⠈⠙⠦⣭⣐⠉⠴⢂⡤⠀⠐⠀⠒⠒⢀⡀⠀⠄⠁⡠⠀⢸⠀
		⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠲⢤⣀⣀⠉⠁⠀⠀⠀⠒⠒⠒⠉⠀⢀⡾⠀
		⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⠲⠦⠤⠤⠤⠤⠴⠞⠋⠀⠀
		 */
		return [
			"plugins/misc/libjson_plugin.dll",
			"plugins/access_output/libaccess_output_livehttps_plugin.dll",
			"plugins/codec/libx256_plugin.dll",
		];
	}

	public static function getFiles(dir:Array<String> = null, root:Array<String> = null, allowedExtensions:Array<String> = null, ?ignoreFiles:Array<String>)
	{
		#if (!display && macro)
		// try
		{
			dir ??= ["assets", "secret_assets"];
			allowedExtensions ??= [""];
			// trace(allowedExtensions);
			var cwd:String = Sys.getCwd();
			var map:Map<String, Bytes> = [];
			function readDirectory(rootDirPath:String, root:String)
			{
				for (path in FileSystem.readDirectory(rootDirPath))
				{
					var actual = rootDirPath + "/" + path; // Path.join([rootDirPath, path])

					if (FileSystem.isDirectory(actual))
					{
						readDirectory(actual, root);
					}
					else
					{
						var nonCmd = "assets/" + actual.substring(cwd.length + root.length);
						// trace(nonCmd);
						for (i in allowedExtensions)
						{
							if ((nonCmd.startsWith(i) || nonCmd.endsWith(i)) && (ignoreFiles == null || !ignoreFiles.contains(path)))
							{
								// trace(nonCmd);
								map.set(nonCmd, File.getBytes(actual));
								break;
							}
						}
					}
				}
			}

			for (i in 0...dir.length)
			{
				readDirectory(Path.join([cwd, dir[i]]), (root == null ? dir : root)[i]);
			}
			final byteNames = ["B", "KB", "MB", "GB" /*, "TB", "PB"*/];
			final __log1024 = Math.log(1024);

			// trace([for (i in map.keys()) i]);
			trace('Asset Folders: ' + dir.join(", "));
			trace("Count: " + {
				var count:UInt = 0;
				for (i in map)
					count++;
				count;
			});
			trace("Total Size: " + {
				var count:UInt = 0;
				for (i in map)
					count += i.length;
				var power = Std.int(Math.log(count) / __log1024);
				if (power >= byteNames.length)
					power = byteNames.length - 1;
				var precision = Math.pow(10, 2);
				'${Math.fround(count / Math.pow(1024, power) * precision) / precision} ${byteNames[power]}';
			});
			return map;
			// return [for (key => bytes in map) key => Base64.encode(bytes)];
		}
		// catch(e)
		// {
		// 	trace(e);
		// 	return [];
		// }
		#else
		return [];
		#end
	}
}