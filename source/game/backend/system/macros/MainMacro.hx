package game.backend.system.macros;

#if macro
import game.backend.system.macros.*;
import haxe.macro.Context;
import haxe.macro.Compiler;

class MainMacro
{
	public static function dogo()
	{
		#if !display
		if (Context.defined("display")) return;

		var missing:Bool = false;
		while(!sys.FileSystem.exists("./assets/images/dog.png"))
		{
			missing = true;
			Sys.print("WHERE IS MY DOG.PNG?!");
		}
		if (missing)
			Sys.println("\n\n\nDon't\ndo\nthis\nagain.\n\n");
		#end
	}
	public static function checkUpdaterFeature()
	{
		/*
		if (!Context.defined("UPDATE_FEATURE")) return;
		var gitUrl = game.objects.openfl.UpdaterPopup.gitHubRepUrlReleases;
		var http = new haxe.Http(gitUrl);
		http.setHeader("User-Agent", "request");
		http.onError = function(msg:String)
		{
			switch msg
			{
				case "404" | "403":
					trace('Warning on Request $gitUrl : Code $msg');
				case msg:
					Context.reportError('Error on Request $gitUrl : Code $msg', (macro null).pos);
			}
		}
		http.request(false);
		*/
	}
	public static function run()
	{
		checkUpdaterFeature();
		Compiler.allowPackage('flash');

		if (Context.defined("RELEASE_BUILD"))
		{
			Compiler.define("BUILD_TYPE", "RELEASE");
		}
		else if (Context.defined("DEV_BUILD"))
		{
			Compiler.define("BUILD_TYPE", "DEV");
		}
		else
		{
			Compiler.define("BUILD_TYPE", "UNKNOWN");
		}

		// trace(Context.defined("openfljs"));
		if (Context.defined("web")) // TODO: Auto convert ogg to mp3, probably use ffmpeg
		{
			// Compiler.define("lime_webgl", "1");
			// Compiler.define("openfljs", "1");
		}

		// for (key => i in Context.getDefines()) trace('$key => $i');

		if (Context.defined("COMPILE_ALL_CLASSES"))
			ScriptsMacro.addAdditionalClasses();

		#if !display
		if (Context.defined("display")) return;

		// trace("hello");
		// Compiler.addGlobalMetadata("flixel", "@:build(game.backend.system.macros.ScriptsMacro.fixOptionalArgs())");
		/*
		for (i in [
			"flixel"
		])
			Compiler.addGlobalMetadata(i, "@:build(game.backend.system.macros.ScriptsMacro.compileGenericFunctions())");
		*/

		if (Context.defined("EMBED_FILES") && Context.defined("ZIPLIBS_ALLOWED")) // lime test windows -DUPDATE_EMDASSETS
			AssetsMacro.zipSecretFiles();

		if (Context.defined("USE_SYS_ASSETS"))
			AssetsMacro.placeAssets();

		if (Context.defined("hxvlc") && !Context.defined("android"))
			AssetsMacro.deleteExportFile("manifest/libvlc.json"); // kill that bitch
		#end
	}
}
#end