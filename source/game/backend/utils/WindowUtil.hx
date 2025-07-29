package game.backend.utils;

import openfl.Lib.application as Application;
#if CPP_WINDOWS
import game.backend.utils.native.Windows;
#end

class WindowUtil {
	public static var curTitle(get, null):String;
	static function get_curTitle():String return Application.window.title;

	public static var winTitle(default, set):String;
	static function set_winTitle(newWinTitle:String):String {
		winTitle = newWinTitle;
		updateTitle();
		return newWinTitle;
	}
	public static var prefix(default, set):String = "";
	static function set_prefix(newPrefix:String):String {
		prefix = newPrefix;
		updateTitle();
		return newPrefix;
	}
	public static var endfix(default, set):String = "";
	static function set_endfix(endPrefix:String):String {
		endfix = endPrefix;
		updateTitle();
		return endPrefix;
	}

	public static var disableClosing:Bool = true;
	public static var onClosing:Void->Void;

	public static function init() {
		resetTitle();
		disableClosing = false;

		Application.window.onClose.add(function () {
			if (disableClosing) {
				Application.window.onClose.cancel();
			}
			if (onClosing != null) onClosing();
		});
	}

	public static function resetTitle() {
		@:bypassAccessor winTitle = Application.meta["name"];
		@:bypassAccessor prefix = endfix = "";
		updateTitle();
	}

	public static function updateTitle() Application.window.title = '$prefix$winTitle$endfix';

	/**
	 * WINDOW COLOR MODE FUNCTIONS.
	 */

	/**
	 * Switch the window's color mode to dark or light mode.
	 */
	public static function setDarkMode(enable:Bool, ?title:String) {
		#if CPP_WINDOWS
		title ??= lime.app.Application.current.window.title;
		Windows.setDarkMode(enable, title);
		#end
	}

	/**
	 * Switch the window's color to any color.
	 *
	 * WARNING: This is exclusive to windows 11 users, unfortunately.
	 *
	 * NOTE: Setting the color to 0x00000000 (FlxColor.TRANSPARENT) will set the border (must have setBorder on) invisible.
	 */
	public static function setWindowBorderColor(color:FlxColor, ?title:String, setHeader:Bool = true, setBorder:Bool = true) {
		#if CPP_WINDOWS
		title ??= lime.app.Application.current.window.title;
		Windows.setWindowBorderColor(title, [color.red, color.green, color.blue, color.alpha], setHeader, setBorder);
		#end
	}

	/**
	 * Resets the window's border color to the default one.
	 *
	 * WARNING: This is exclusive to windows 11 users, unfortunately.
	**/
	public static function resetWindowBorderColor(?title:String, setHeader:Bool = true, setBorder:Bool = true) {
		#if CPP_WINDOWS
		title ??= lime.app.Application.current.window.title;
		Windows.setWindowBorderColor(title, [-1, -1, -1, -1], setHeader, setBorder);
		#end
	}

	/**
	 * Switch the window's title text to any color.
	 *
	 * WARNING: This is exclusive to windows 11 users, unfortunately.
	 */
	public static function setWindowTitleColor(color:FlxColor, ?title:String) {
		#if CPP_WINDOWS
		title ??= lime.app.Application.current.window.title;
		Windows.setWindowTitleColor(title, [color.red, color.green, color.blue, color.alpha]);
		#end
	}

	/**
	 * Resets the window's title color to the default one.
	 *
	 * WARNING: This is exclusive to windows 11 users, unfortunately.
	**/
	public static function resetWindowTitleColor(?title:String) {
		#if CPP_WINDOWS
		title ??= lime.app.Application.current.window.title;
		Windows.setWindowTitleColor(title, [-1, -1, -1, -1]);
		#end
	}

	/**
	 * Forces the window header to redraw, causes a small visual jitter so use it sparingly.
	 */
	public static function redrawWindowHeader() {
		#if CPP_WINDOWS
		flixel.FlxG.stage.window.borderless = true;
		flixel.FlxG.stage.window.borderless = false;
		#end
	}

	/**
	 * Can be used to check if your using a specific version of an OS (or if your using a certain OS).
	 */
	public static function hasVersion(vers:String)
		return lime.system.System.platformLabel.toLowerCase().indexOf(vers.toLowerCase()) != -1;

}