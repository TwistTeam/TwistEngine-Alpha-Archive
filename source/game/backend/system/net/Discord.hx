package game.backend.system.net;

import game.Config;
import game.backend.data.EngineData;
import game.backend.system.macros.HaxeLibsMacro;
import game.backend.utils.HttpUtil;
import game.backend.utils.ThreadUtil;

import flixel.system.macros.FlxMacroUtil;
import flixel.util.FlxStringUtil;

// import lime.app.Application;
import openfl.display.BitmapData;

import haxe.extern.EitherType;
import haxe.io.Bytes;

import lime.app.Future;
import lime.graphics.Image;

#if DISCORD_RPC
import haxe.MainLoop;

import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;

import sys.thread.Thread;
import sys.thread.Mutex;

import cpp.ConstCharStar;
import cpp.RawConstPointer;
#if GLOBAL_SCRIPT
import game.backend.system.scripts.GlobalScript;
import game.backend.system.scripts.ScriptPack;
#end
#end

typedef DPresence =
{
	var ?state:String; /* max 128 bytes */
	var ?details:String; /* max 128 bytes */
	var ?startTimestamp:Long;
	var ?endTimestamp:Long;
	var ?largeImageKey:String; /* max 32 bytes */
	var ?largeImageText:String; /* max 128 bytes */
	var ?smallImageKey:String; /* max 32 bytes */
	var ?smallImageText:String; /* max 128 bytes */
	var ?partyId:String; /* max 128 bytes */
	var ?partySize:Int;
	var ?partyMax:Int;
	var ?partyPrivacy:Int;
	var ?matchSecret:String; /* max 128 bytes */
	var ?joinSecret:String; /* max 128 bytes */
	var ?spectateSecret:String; /* max 128 bytes */
	var ?instance:Byte;
	var ?button1Label:String; /* max 32 bytes */
	var ?button1Url:String; /* max 512 bytes */
	var ?button2Label:String; /* max 32 bytes */
	var ?button2Url:String; /* max 512 bytes */
}

typedef ActivityAssets =
{
	var ?smallImage:String;
	var ?smallText:String;
	var ?largeImage:String;
	var ?largeText:String;

	var ?button1Label:String;
	var ?button1Url:String;
	var ?button2Label:String;
	var ?button2Url:String;
}

typedef DiscordJson =
{
	var ?clientID:String;
	var ?largeImageKey:String;
	var ?largeImageText:String;
	var ?button1Label:String;
	var ?button1Url:String;
	var ?button2Label:String;
	var ?button2Url:String;
}

class DiscordClient
{
	public static var isInitialized(get, never):Bool;
	static inline function get_isInitialized() return isConnected;
	public static var isConnected(default, null):Bool = false;
	public static var user:DUser = null;
	public static var config:DiscordJson = null;
	public static var defaultID(default, never):String = Config.discordConfig.clientID;
	public static var clientID(default, set):String = defaultID;
	public static var currentThread(default, null):ThreadParams;
	#if DISCORD_RPC
	static var mutex = new Mutex();
	#end

	public static final presence:Presence = new Presence();

	static function set_clientID(newID:String)
	{
		newID = newID ?? defaultID;
		#if DISCORD_RPC
		final change:Bool = (clientID != newID);
		clientID = newID;

		if (change && isConnected)
		{
			Log("Discord RPC ID Changed", BLUE);
			shutdown();
			initialize();
		}
		#else
		clientID = newID;
		#end
		return newID;
	}

	public static function reloadJsonData()
	{
		#if DISCORD_RPC
		config = null;
		var jsonPath = Paths.json("DiscordConfig");
		if (Assets.exists(jsonPath))
		{
			try
				config = haxe.Json.parse(Assets.getText(jsonPath))
			catch (e)
				Log('Couldn\'t load Discord RPC configuration: ${e.toString()}', RED);
		}
		config ??= {};
		#else
		config = {};
		#end
		var field:Dynamic;
		for (i in Reflect.fields(Config.discordConfig))
		{
			field = Reflect.field(config, i);
			if (field == null)
				Reflect.setField(config, i, Reflect.field(Config.discordConfig, i));
		}
		clientID = config.clientID;
	}

	public static dynamic function filter(txt:Null<String>):String
	{
		if (txt == null) return null;

		txt = txt.replace("<ENGINE-VERSION>", EngineData.engineVersion).replace("<APP-TITLE>", game.backend.utils.WindowUtil.winTitle);
		var maxLength = 0xFF >> 1;
		if (txt.length > maxLength)
			txt = txt.substring(0, maxLength);
		return txt;
	}

	public static function check()
	{
		#if DISCORD_RPC
		if (ClientPrefs.disc)
			start();
		else
			shutdown();
		#end
	}

	public static function start()
	{
		#if DISCORD_RPC
		if (!isConnected && ClientPrefs.disc)
		{
			initialize();
		}
		#end
	}

	public static function shutdown()
	{
		#if DISCORD_RPC
		if (isConnected)
		{
			Discord.Shutdown();
			isConnected = false;
		}
		if (currentThread != null)
			currentThread.isDestroyed = true;
		currentThread = null;
		#end
	}

	public static var dirtyUpdate:Bool = true;

	public static function initialize()
	{
		#if DISCORD_RPC
		Log("Discord RPC starting...", DARKBLUE);
		isConnected = false;

		var idThread = clientID + "_DISCORD_ACTIVITY";
		if (currentThread != null)
			currentThread.isDestroyed = true;
		currentThread = ThreadUtil.createLoopingThread(idThread, () ->
		{
			#if DISCORD_DISABLE_IO_THREAD
			Discord.UpdateConnection();
			#end
			Discord.RunCallbacks();
			if (dirtyUpdate && isConnected && mutex.tryAcquire())
			{
				// Obtained times are in milliseconds so they are divided so Discord can use it
				updatePresence();
				// Sys.println("pawtuah");
				dirtyUpdate = false;
				mutex.release();
			}
		}, 0.0, 0.3);

		var discordHandlers:DiscordEventHandlers = new DiscordEventHandlers();
		// discordHandlers.ready = cpp.Function.fromStaticFunction(onReady);
		discordHandlers.ready = cpp.Callable.fromStaticFunction(onReady);
		discordHandlers.disconnected = cpp.Callable.fromStaticFunction(onDisconnected);
		discordHandlers.errored = cpp.Callable.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), false, null);

		Log("Discord RPC initialized", DARKBLUE);
		#end
	}

	#if DISCORD_RPC
	static function onReady(request:RawConstPointer<DiscordUser>)
	{
		user = DUser.initRaw(request);
		MainLoop.runInMainThread(() -> {
			Log("Discord RPC started.", DARKBLUE);
			// if (lastThread != null && lastThread.isDestroyed)
			// {
			// 	return;
			// }
			Log('Connected to User ${user.globalName} (${user.handle})', DARKBLUE);
			isConnected = true;
			updatePresence();
		});

	}

	static function onError(errorCode:Int, message:ConstCharStar)
	{
		MainLoop.runInMainThread(Log.bind('Discord: Error ($errorCode: $message)', DARKBLUE));
	}

	static function onDisconnected(errorCode:Int, message:ConstCharStar)
	{
		user = null;
		MainLoop.runInMainThread(Log.bind('Discord: Disconnected ($errorCode: $message)', DARKBLUE));
	}
	#end

	// public static function changePresence(details:String, state:String, ?smallImageKey:String,
	// 	?hasStartTimestamp:Bool, ?endTimestamp:Float, ?largeImageKey:String = '')
	#if !DISCORD_RPC
	inline
	#end
	public static function changePresence(?details:String, ?state:String, ?endTimestamp:Float, ?activity:ActivityAssets)
	{
		#if DISCORD_RPC
		mutex.acquire();
		#if GLOBAL_SCRIPT
		if (ScriptPack.resultIsStop(GlobalScript.call("preChangeDSPresence", [details, state, endTimestamp, activity])))
		{
			mutex.release();
			return;
		}
		#end
		presence.state = filter(state);
		presence.details = filter(details);

		if (endTimestamp != null && endTimestamp > 0)
		{
			final startTimestamp:Float = Date.now().getTime();
			endTimestamp += startTimestamp;
			presence.startTimestamp = Std.int(startTimestamp / 1000);
			presence.endTimestamp = Std.int(endTimestamp / 1000);
		}
		else
		{
			presence.startTimestamp = 0;
			presence.endTimestamp = 0;
		}

		if (activity != null)
		{
			if (config != null)
			{
				activity.largeImage ??= config.largeImageKey;
				activity.largeText ??= config.largeImageText;
				activity.button1Label ??= config.button1Label;
				activity.button1Url ??= config.button1Url;
				activity.button2Label ??= config.button2Label;
				activity.button2Url ?? config.button2Url;
			}

			presence.largeImageKey = activity.largeImage;
			presence.largeImageText = filter(activity.largeText);
			presence.smallImageKey = activity.smallImage;
			presence.smallImageText = filter(activity.smallText);

			presence.button1Label = filter(activity.button1Label);
			presence.button1Url = activity.button1Url;
			presence.button2Label = filter(activity.button2Label);
			presence.button2Url = activity.button2Url;
		}
		else if (config != null)
		{
			presence.largeImageKey = config.largeImageKey;
			presence.largeImageText = filter(config.largeImageText);
			presence.button1Label = filter(config.button1Label);
			presence.button1Url = config.button1Url;
			presence.button2Label = filter(config.button2Label);
			presence.button2Url = config.button2Url;
		}

		dirtyUpdate = true;

		#if GLOBAL_SCRIPT
		GlobalScript.call("postChangeDSPresence", [details, state, endTimestamp, activity]);
		#end
		// Log('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp', DARKBLUE);
		mutex.release();
		#end
	}

	public static inline function updatePresence()
	{
		#if DISCORD_RPC
		if (isConnected)
			presence.updatePresence();
		#end
	}
}

@:noCustomClass
@:allow(game.backend.system.net.Discord)
final class Presence
{
	public var button1Label(get, set):String;
	public var button1Url(get, set):String;

	public var button2Label(get, set):String;
	public var button2Url(get, set):String;

	public var button1:DButton;
	public var button2:DButton;

	#if DISCORD_RPC
	public var state(default, set):String;
	public var details(default, set):String;

	public var smallImageText(default, set):String;
	public var smallImageKey(default, set):String;
	public var largeImageKey(default, set):String;
	public var largeImageText(default, set):String;

	public var startTimestamp(default, set):Long;
	public var endTimestamp(default, set):Long;

	public var address(get, never):PresenceAddress;

	@:unreflective @:noCompletion var presence(default, null):DiscordRichPresence;

	function new()
	{
		presence = new DiscordRichPresence();
		presence.type = DiscordActivityType_Playing;

		button1 = new DButton();
		button2 = new DButton();
		for (i in 0...2)
			presence.buttons[i] = new DiscordButton();
	}

	public function updatePresence()
	{
		updateButton(button1, 0);
		updateButton(button2, 1);

		Discord.UpdatePresence(address);
	}

	function updateButton(button:DButton, index:Int)
	{
		// if (!button.dirty)
			// return;

		// if (button.isVisible())
		// {
			var native_button:DiscordButton = presence.buttons[index];
			native_button.label = button.label;
			native_button.url = button.url;
			presence.buttons[index] = native_button;
		// }
		// else
		// {
		// 	presence.buttons[index] = null;
		// }
		button.dirty = false;
	}

	function set_state(value:String):String
		return presence.state = state = value;

	function set_details(value:String):String
		return presence.details = details = value;

	function set_smallImageKey(value:String):String
		return presence.smallImageKey = smallImageKey = value;

	function set_smallImageText(value:String):String
		return presence.smallImageText = smallImageText = value;

	function set_largeImageText(value:String):String
		return presence.largeImageText = largeImageText = value;

	function set_largeImageKey(value:String):String
		return presence.largeImageKey = largeImageKey = value;

	function set_startTimestamp(value:Long):Long
		return presence.startTimestamp = startTimestamp = value;

	function set_endTimestamp(value:Long):Long
		return presence.endTimestamp = endTimestamp = value;

	function get_address():PresenceAddress
		return RawConstPointer.addressOf(presence);
	#else

	public var state:String;
	public var details:String;

	public var smallImageText:String;
	public var smallImageKey:String;
	public var largeImageKey:String;
	public var largeImageText:String;

	public var startTimestamp:Long;
	public var endTimestamp:Long;

	public var address:Dynamic = null;

	function new()
	{
	}

	public function updatePresence(){ }
	#end

	inline function get_button1Label():String
		return button1.label;

	function set_button1Label(value:String):String
		return button1.label = value;

	inline function get_button1Url():String
		return button1.url;

	function set_button1Url(value:String):String
		return button1.url = value;

	inline function get_button2Label():String
		return button2.label;

	function set_button2Label(value:String):String
		return button2.label = value;

	inline function get_button2Url():String
		return button2.url;

	function set_button2Url(value:String):String
		return button2.url = value;

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			// LabelValuePair.weak("address", address),
			LabelValuePair.weak("button1", button1),
			LabelValuePair.weak("button2", button2),
			LabelValuePair.weak("details", details),
			LabelValuePair.weak("endTimestamp", endTimestamp),
			LabelValuePair.weak("largeImageKey", largeImageKey),
			LabelValuePair.weak("largeImageText", largeImageText),
			LabelValuePair.weak("smallImageKey", smallImageKey),
			LabelValuePair.weak("smallImageText", smallImageText),
			LabelValuePair.weak("startTimestamp", startTimestamp),
			LabelValuePair.weak("state", state),
		]);
	}
}

#if DISCORD_RPC
typedef PresenceAddress = RawConstPointer<DiscordRichPresence>;
#end

@:noCustomClass
final class DUser
{
	/**
	 * The username + discriminator if they have it
	**/
	public var handle:String;

	/**
	 * The user id, aka 860561967383445535
	**/
	public var userId:String;

	/**
	 * The user's username
	**/
	public var username:String;

	/**
	 * The #number from before discord changed to usernames only, if the user has changed to a username them its just a 0
	**/
	public var discriminator:Int;

	/**
	 * The user's avatar filename
	**/
	public var avatar:String;

	/**
	 * The user's display name
	**/
	public var globalName:String;

	/**
	 * If the user is a bot or not
	**/
	public var bot:Bool;

	/**
	 * If the user has nitro
	**/
	public var premiumType:Int;

	private function new()
	{
	}

	public function getPremiumType():String
	{
		#if DISCORD_RPC
		return switch(cast (premiumType : DiscordPremiumType))
		{
			case DiscordPremiumType.DiscordPremiumType_NitroClassic:	"NitroClassic";
			case DiscordPremiumType.DiscordPremiumType_Nitro:			"Nitro";
			case DiscordPremiumType.DiscordPremiumType_NitroBasic:		"NitroBasic";
			case DiscordPremiumType.DiscordPremiumType_None:			"None";
		}
		#else
		return "None";
		#end
	}

	public static function initRaw(req:#if DISCORD_RPC RawConstPointer<DiscordUser> #else Dynamic #end)
	{
		#if DISCORD_RPC
		return init(cpp.ConstPointer.fromRaw(req).ptr);
		#else
		return null;
		#end
	}

	public static function init(userData:#if DISCORD_RPC cpp.Star<DiscordUser> #else Dynamic #end)
	{
		#if DISCORD_RPC
		var d = new DUser();
		d.userId = userData.userId;
		d.username = userData.username;
		d.discriminator = Std.parseInt(userData.discriminator);
		d.avatar = userData.avatar;
		d.globalName = userData.globalName;
		d.bot = userData.bot;
		d.premiumType = userData.premiumType;
		d.handle = d.discriminator == 0 ? d.username : '${d.username}#${d.discriminator}';
		return d;
		#else
		return null;
		#end
	}

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("avatar", avatar),
			LabelValuePair.weak("bot", bot),
			LabelValuePair.weak("discriminator", discriminator),
			LabelValuePair.weak("globalName", globalName),
			LabelValuePair.weak("handle", handle),
			LabelValuePair.weak("premiumType", getPremiumType()),
			LabelValuePair.weak("userId", userId),
			LabelValuePair.weak("username", username),
		]);
	}

	/**
	 * Calling this function gets the BitmapData of the user
	**/
	public function getAvatar(?size:Int):BitmapData
		return BitmapData.fromBytes(getAvatarBytes(size));

	public function getASyncAvatar(?size:Int):Future<BitmapData>
	{
		return getASyncAvatarBytes(size).then(function(bytes) // сначало ищем байты
		{
			return Image.loadFromBytes(bytes).then(function(image) // потом превращаем байты в изображение
			{
				return new Future<BitmapData>(BitmapData.fromImage.bind(image), true); // и наконец-то превращаем изображение в битмапу
			});
		});
	}

	public function getAvatarBytes(?size:Int):Bytes
		return HttpUtil.requestBytes(getUrlAvatar(size));

	public function getASyncAvatarBytes(?size:Int):Future<Bytes>
		return HttpUtil.aSyncRequestBytes(getUrlAvatar(size));

	function getUrlAvatar(size:Null<Int>)
		return 'https://cdn.discordapp.com/avatars/$userId/$avatar.png${size == null ? "" : '?size=$size'}';
}

@:noCustomClass
final class DButton
{
	public var label(default, set):String;

	public var url(default, set):String;

	public var dirty:Bool = false;
	public function new(?label:String, ?url:String)
	{
		this.label = label;
		this.url = url;
	}

	public function isVisible()
	{
		return !FlxStringUtil.isNullOrEmpty(label) && !FlxStringUtil.isNullOrEmpty(url);
	}

	public function toString():String
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("label", label),
			LabelValuePair.weak("url", url),
		]);
	}

	function set_label(value:String):String
	{
		if (label != value)
			dirty = true;
		return label = value;
	}

	function set_url(value:String):String
	{
		if (url != value)
			dirty = true;
		return url = value;
	}
}