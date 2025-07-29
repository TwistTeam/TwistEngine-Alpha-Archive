package game.backend.utils;

@:final class Constants
{
	public static inline final DEFAULT_ARTIST:String = "Unknown";
	public static inline final DEFAULT_CHARTER:String = "Unknown";

	public static inline final DEFAULT_CHARACTER:String = "defaultStatic"; // In case a character is missing, it will use BF on its place

	public static inline final DEFAULT_NOTESPLASH_SKIN:String = "noteSplashes";
	public static inline final DEFAULT_NOTEHOLDCOVER_SKIN:String = "noteHoldCovers";
	public static inline final DEFAULT_NOTESUSTAINGLOW_SKIN:String = "noteHoldCovers"; // TODO
	public static inline final DEFAULT_NOTE_SKIN:String = "NOTE_assets";
	public static inline final DEFAULT_TYPE_NOTE:game.objects.game.notes.Note.TypeNote = FNF_NOTE;

	public static inline final MODSLIST_FILE:String = "./modsFolders.txt";
	public static inline final MODS_PATH:String = "./mods/*";

	public static inline final SONG_AUDIO_FILES_FOLDER:String = "songs";
	public static inline final SONG_CHART_FILES_FOLDER:String = "data";
	public static inline final SONG_EVENTS_FILES_FOLDER:String = "custom_events";
	public static inline final SONG_NOTETYPES_FILES_FOLDER:String = "custom_notetypes";
}