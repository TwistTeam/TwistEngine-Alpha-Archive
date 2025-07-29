package game.states.editors;

import haxe.io.Path;

#if sys
import sys.FileSystem;
#end

typedef PathInfo = {
	path:String,
	modFolder:String,
	file:String,
	extension:String,
	?extra:Any
}

@:private enum FileType{
	ANIMATE_ATLAS;
	CHARACTER;
	CHARACTERPNG;
	CHART;
	ICON;
	ICONPNG;
	IMAGE;
	STAGE;
}

class DropFileUtil {
	public static function getInfoPath(path:String, ?type:Null<FileType>):PathInfo {
		final path = Path.normalize(path);
		final pathData = new Path(path);
		trace([pathData.toString()]);
		switch (type) {
			case STAGE:
				if (!['json', 'hx', 'lua'].contains(pathData.ext.toLowerCase())) return null;
				var modFolder = path.split("/");
				if (modFolder[modFolder.length - 2] != 'stages') return null;

				final e = ModsFolder.currentModFolder;
				/*
				ModsFolder.currentModFolder = modFolder[modFolder.length - 3];
				if (!Paths.fileExists('stages/${pathData.file}.json')){
					ModsFolder.currentModFolder = e;
					return null;
				}
				ModsFolder.currentModFolder = e;
				*/
				return {
					path: path,
					modFolder: modFolder[modFolder.length - 3],
					file: pathData.file,
					extension: pathData.ext
				};

			case CHART:
				if (pathData.ext != 'json') return null;
				var modFolder = path.split("/");
				if (modFolder[modFolder.length - 3] != 'data') return null;
				if (!modFolder[modFolder.length - 1].contains(modFolder[modFolder.length - 2])) return null;

				return {
					path: path,
					modFolder: modFolder[modFolder.length - 4],
					file: pathData.file,
					extension: pathData.ext
				};

			case CHARACTER:
				if (pathData.ext != 'json') return null;
				var modFolder = path.split("/");
				if (modFolder[modFolder.length - 2] != 'characters') return null;

				return {
					path: path,
					modFolder: modFolder[modFolder.length - 3],
					file: pathData.file,
					extension: pathData.ext
				};

			case CHARACTERPNG:
				// if (/*path.endsWith('.png') == false &&*/ !FileSystem.exists(path.replace('.png','.xml'))) return null;
				var modFolder = path.split("/");

				var onImageFolder = false, onCharacterFolder = false;
				var modIndex = 0;
				var dumIndex = modFolder.length - 1;
				while(dumIndex > 0){
					if (modFolder[dumIndex] == 'characters'){
						onCharacterFolder = true;
						modIndex = dumIndex - 2;
					}else if (modFolder[dumIndex] == 'images'){
						onImageFolder = true;
						modIndex = dumIndex - 1;
					}
					if(onImageFolder && onCharacterFolder) break;
					dumIndex--;
				}
				if (dumIndex <= 0)
					return null;

				return {
					path: path,
					modFolder: filterMods(modFolder[modIndex]),
					file: Path.withoutExtension(path.substr([for (i in 0...modIndex + 2) modFolder[i]].join('/').length + 1)),
					extension: pathData.ext
				};

			case ICON:
				if (pathData.ext != 'json') return null;
				var modFolder = path.split("/");
				if (modFolder[modFolder.length - 3] != 'characters' || modFolder[modFolder.length - 2] != 'icons') return null;

				return {
					path: path,
					modFolder: modFolder[modFolder.length - 4],
					file: pathData.file,
					extension: pathData.ext
				};

			case ICONPNG:
				// if (/*path.endsWith('.png') == false &&*/ !FileSystem.exists(path.replace('.png','.xml'))) return null;
				var modFolder = path.split("/");

				var onImageFolder = false, onCharacterFolder = false;
				var modIndex = 0;
				var dumIndex = modFolder.length - 1;
				while(dumIndex > 0){
					if (modFolder[dumIndex] == 'icons'){
						onCharacterFolder = true;
						modIndex = dumIndex - 2;
					}else if (modFolder[dumIndex] == 'images'){
						onImageFolder = true;
						modIndex = dumIndex - 1;
					}
					if(onImageFolder && onCharacterFolder) break;
					dumIndex--;
				}
				if (dumIndex <= 0)
					return null;

				return {
					path: path,
					modFolder: filterMods(modFolder[modIndex]),
					file: Path.withoutExtension(path.substr([for (i in 0...modIndex + 3) modFolder[i]].join('/').length + 1)),
					extension: pathData.ext
				};

			case ANIMATE_ATLAS:
				// if (/*path.endsWith('.png') == false &&*/ !FileSystem.exists(path.replace('.png','.xml'))) return null;
				var modFolder = path.split("/");

				var isAtlasFolder = false;
				var modIndex = 0;
				var dumIndex = modFolder.length - 1;
				var atlasRegex = ~/((Animation|spritemap(\d+)?).json$)|((spritemap(\d+)?).png$)/;
				do
				{
					if (dumIndex == modFolder.length - 1)
					{
						if (atlasRegex.match(path))
						{ }
						#if sys
						else if (FileSystem.exists(path + "/Animation.json")
							&& (
								FileSystem.exists(path + "/spritemap1.json") && FileSystem.exists(path + "/spritemap1.png")
								|| FileSystem.exists(path + "/spritemap.json") && FileSystem.exists(path + "/spritemap.png")
							)
						)
						{
							isAtlasFolder = true;
						}
						#end
						else
						{
							dumIndex = -1;
							break;
						}
					}
					else if (modFolder[dumIndex] == 'images')
					{
						modIndex = dumIndex - 1;
						break;
					}
					dumIndex--;
				} while(dumIndex > 0);
				trace(dumIndex, modFolder);
				if (dumIndex <= 0)
					return null;

				var file = path.substr([for (i in 0...modIndex + 2) modFolder[i]].join('/').length + 1);
				if (!isAtlasFolder)
				{
					file = Path.directory(file);
				}
				return {
					path: path,
					modFolder: filterMods(modFolder[modIndex]),
					file: file,
					extension: pathData.ext
				};

			case IMAGE:
				// if (/*path.endsWith('.png') == false &&*/ !FileSystem.exists(path.replace('.png','.xml'))) return null;
				var modFolder = path.split("/");

				var modIndex = 0;
				var dumIndex = modFolder.length - 1;
				while(dumIndex > 0){
					if (modFolder[dumIndex] == 'images'){
						modIndex = dumIndex - 1;
						break;
					}
					dumIndex--;
				}
				trace(dumIndex, modFolder);
				if (dumIndex <= 0)
					return null;

				return {
					path: path,
					modFolder: filterMods(modFolder[modIndex]),
					file: Path.withoutExtension(path.substr([for (i in 0...modIndex + 2) modFolder[i]].join('/').length + 1)),
					extension: pathData.ext
				};

			default:
				return {
					path: path,
					modFolder: null,
					file: pathData.file,
					extension: pathData.ext
				};
		}
	}
	static inline function filterMods(str:String) return str == 'mods' ? '' : str; // ass
}