#if !macro
import game.*;
import game.backend.assets.AssetsPaths;
import game.backend.assets.ModsFolder;
import game.backend.system.Paths;
import game.backend.system.Mods;
import game.backend.utils.ClientPrefs.instance as ClientPrefs;
import game.backend.utils.Constants;
import game.backend.utils.CoolUtil;
import game.backend.utils.LogsGame;
import game.backend.utils.LogsGame.Log;
import game.backend.utils.Types;

import openfl.utils.Assets;

import flixel.*;
import game.objects.improvedFlixel.FlxCamera; // override ::troll::
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import game.backend.system.net.Discord.DiscordClient;

using StringTools;
using game.backend.utils.FlxObjectTools;
using game.backend.utils.CoolUtil;
#end