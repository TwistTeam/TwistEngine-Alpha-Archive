package game.backend.system.audio;

import flixel.sound.FlxSound;

#if (lime_cffi && lime_openal)
import lime.system.CFFIPointer;
import lime.media.openal.ALEffect;
import lime.media.openal.ALAuxiliaryEffectSlot;
import lime.media.openal.ALFilter;
import lime.media.openal.AL;

import flixel.util.typeLimit.OneOfTwo;

using game.backend.system.audio.extensions.ALExtension;

// https://www.openal-soft.org/misc-downloads/Effects%20Extension%20Guide.pdf
class EffectSound extends FlxSound // TODO: TO REWRITE FROM SINGLE TO LAYERED
{
	public static final EffectsList:Map<String, Array<String>> = [
		'NULL' => [],
		'EAXREVERB' => [ // Windows only... ?
			'DENSITY',
			'DIFFUSION',
			'GAIN',
			'GAINHF',
			'GAINLF',
			'DECAY_TIME',
			'DECAY_HFRATIO',
			'DECAY_LFRATIO',
			'REFLECTIONS_GAIN',
			'REFLECTIONS_DELAY',
			'REFLECTIONS_PAN',
			'LATE_REVERB_GAIN',
			'LATE_REVERB_DELAY',
			'LATE_REVERB_PAN',
			'ECHO_TIME',
			'ECHO_DEPTH',
			'MODULATION_TIME',
			'MODULATION_DEPTH',
			'AIR_ABSORPTION_GAINHF',
			'HFREFERENCE',
			'LFREFERENCE',
			'ROOM_ROLLOFF_FACTOR',
			'DECAY_HFLIMIT'
		],
		'REVERB' => [
			'DENSITY',
			'DIFFUSION',
			'GAIN',
			'GAINHF',
			'DECAY_TIME',
			'DECAY_HFRATIO',
			'REFLECTIONS_GAIN',
			'REFLECTIONS_DELAY',
			'LATE_REVERB_GAIN',
			'LATE_REVERB_DELAY',
			'AIR_ABSORPTION_GAINHF',
			'ROOM_ROLLOFF_FACTOR',
			'DECAY_HFLIMIT'
		],
		'CHORUS' => [
			'WAVEFORM',
			'PHASE',
			'RATE',
			'DEPTH',
			'FEEDBACK',
			'DELAY'
		],
		'DISTORTION' => [
			'EDGE',
			'GAIN',
			'LOWPASS_CUTOFF',
			'EQCENTER',
			'EQBANDWIDTH'
		],
		'ECHO' => [
			'DELAY',
			'LRDELAY',
			'DAMPING',
			'FEEDBACK',
			'SPREAD'
		],
		'FLANGER' => [
			'WAVEFORM',
			'PHASE',
			'RATE',
			'DEPTH',
			'FEEDBACK',
			'DELAY'
		],
		'FREQUENCY_SHIFTER' => [
			'FREQUENCY',
			'LEFT_DIRECTION',
			'RIGHT_DIRECTION'
		],
		'VOCAL_MORPHER' => [
			'PHONEMEA',
			'PHONEMEA_COARSE_TUNING',
			'PHONEMEB',
			'PHONEMEB_COARSE_TUNING',
			'WAVEFORM',
			'RATE'
		],
		'PITCH_SHIFTER' => [
			'COARSE_TUNE',
			'FINE_TUNE'
		],
		'RING_MODULATOR' => [
			'FREQUENCY',
			'HIGHPASS_CUTOFF',
			'WAVEFORM'
		],
		'AUTOWAH' => [
			'ATTACK_TIME',
			'RELEASE_TIME',
			'RESONANCE',
			'PEAK_GAIN'
		],
		'COMPRESSOR' => [
			'ONOFF'
		],
		'EQUALIZER' => [
			'LOW_GAIN',
			'LOW_CUTOFF',
			'MID1_GAIN',
			'MID1_CENTER',
			'MID1_WIDTH',
			'MID2_GAIN',
			'MID2_CENTER',
			'MID2_WIDTH',
			'HIGH_GAIN',
			'HIGH_CUTOFF'
		]
	];

	public static final FiltersList:Map<String, Array<String>> = [
		'NULL'		=> [],
		'BANDPASS'	=> ['GAIN', 'GAINLF', 'GAINHF'],
		'HIGHPASS'	=> ['GAIN', 'GAINLF'],
		'LOWPASS'	=> ['GAIN', 'GAINHF']
	];

	public inline static function load(?embeddedSound:flixel.system.FlxAssets.FlxSoundAsset, volume = 1.0, looped = false,
			?group:flixel.sound.FlxSoundGroup, autoDestroy = false, autoPlay = false, ?url:String, ?onComplete:Void->Void, ?onLoad:Void->Void):EffectSound
		return cast CoolUtil.loadSound(embeddedSound, volume, looped, EffectSound, group, autoDestroy, autoPlay, url, onComplete, onLoad);

	var effect:Null<ALEffect>;
	public var curEffect(default, null) = {name: 'NULL', data: EffectsList.get('NULL')};

	var filter:Null<ALFilter>;
	var filterIndex:Int = 0;
	public var curFilter(default, null) = {name: 'NULL', data: FiltersList.get('NULL')};

	var _effectAuxSlot:Null<ALAuxiliaryEffectSlot> = null;

	static final _eregSpaces = ~/[ -]/;
	inline static function formatVarName(_:String) return _eregSpaces.replace(_.trim().toUpperCase(), "_");

	inline static function checkAudio(?filepos:haxe.PosInfos){
		final message = AL.getErrorString();
		if (message.length > 1) Log(message, RED, filepos);
	}

	public function setFilter(filterName:String):EffectSound
	{
		filterName = formatVarName(filterName);
		if (curFilter.name == filterName)
			return this; // ignore

		filter ??= AL.createFilter();
		if (FiltersList.exists(filterName))
		{
			curFilter.name = filterName;
			curFilter.data = FiltersList.get(filterName);
		}
		else
		{
			curFilter.name = 'NULL';
			curFilter.data = FiltersList.get('NULL');
		}
		// trace(curFilter);
		AL.filteri(filter, AL.FILTER_TYPE, filterIndex = Reflect.field(SoundFields, 'FILTER_${curFilter.name}'));
		checkAudio();
		updateFilter();
		checkAudio();
		return this;
	}
	public function setFilterVar(valName:String, value:Float, type:OPENALSetType):EffectSound
	{
		if (filter == null)
			return this; // fagot
		valName = formatVarName(valName);
		if (curFilter.data.contains(valName))
		{
			if (type == OPENAL_FLOAT)
				AL.filterf(filter, Reflect.field(SoundFields, '${curFilter.name}_$valName'), value);
			else
				AL.filteri(filter, Reflect.field(SoundFields, '${curFilter.name}_$valName'), Std.int(value));
			// trace('${curFilter.name}_$valName = $value');
			checkAudio();
			updateFilter();
			checkAudio();
		}
		return this;
	}

	public function setEffect(effectName:String):EffectSound
	{
		effectName = formatVarName(effectName);
		if (curEffect.name == effectName)
			return this; // ignore
		effect ??= AL.createEffect();
		if (EffectsList.exists(effectName))
		{
			curEffect.name = effectName;
			curEffect.data = EffectsList.get(effectName);
		}
		else
		{
			curEffect.name = 'NULL';
			curEffect.data = EffectsList.get('NULL');
		}
		// trace(curEffect);
		AL.effecti(effect, AL.EFFECT_TYPE, Reflect.field(SoundFields, 'EFFECT_${curEffect.name}'));
		checkAudio();
		return this;
	}
	public function setEffectVar(valName:String, value:Float, type:OPENALSetType):EffectSound
	{
		if (effect == null)
			return this; // fagot
		valName = formatVarName(valName);
		if (curEffect.data.contains(valName))
		{
			if (type == OPENAL_FLOAT)
				AL.effectf(effect, Reflect.field(SoundFields, '${curEffect.name}_$valName'), value);
			else
				AL.effecti(effect, Reflect.field(SoundFields, '${curEffect.name}_$valName'), Std.int(value));
			// trace('${curEffect.name}_$valName = $value');
			checkAudio();
		}
		return this;
	}

	override function resume()
	{
		super.resume();
		updateFilter();
		updateEffect();
		return this;
	}

	override function reset():Void
	{
		deleteFilter();
		deleteEffect();
		deleteAux();
		super.reset();
		// filter = AL.createFilter();
		// effect = AL.createEffect();
		curEffect.name = 'NULL';
		curEffect.data = EffectsList.get('NULL');
		curFilter.name = 'NULL';
		curFilter.data = FiltersList.get('NULL');
		updateFilter();
		updateEffect();
	}

	public function clearALStuff():Void
	{
		deleteFilter();
		deleteEffect();
		deleteAux();
		curFilter.name = 'NULL';
		curFilter.data = FiltersList.get('NULL');
		curEffect.name = 'NULL';
		curEffect.data = EffectsList.get('NULL');
		updateFilter();
		updateEffect();
	}

	public function clearFilter():Void
	{
		deleteFilter();
		curFilter.name = 'NULL';
		curFilter.data = FiltersList.get('NULL');
		updateFilter();
		updateEffect();
	}

	public function clearEffect():Void
	{
		deleteEffect();
		curEffect.name = 'NULL';
		curEffect.data = EffectsList.get('NULL');
		updateEffect();
	}

	public function deleteFilter()
	{
		if (filter == null) return;
		AL.deleteFilter(filter);
		filter = null;
	}
	public function deleteEffect()
	{
		if (effect == null) return;
		AL.deleteEffect(effect);
		effect = null;
	}
	public function deleteAux()
	{
		if (_effectAuxSlot == null) return;
		AL.deleteAux(_effectAuxSlot);
		_effectAuxSlot = null;
	}
	public override function destroy():Void
	{
		deleteFilter();
		deleteEffect();
		deleteAux();
		curEffect.name = 'NULL';
		curEffect.data = EffectsList.get('NULL');
		curFilter.name = 'NULL';
		curFilter.data = FiltersList.get('NULL');
		updateFilter();
		updateEffect();
		super.destroy();
	}

	@:allow(flixel.sound.FlxSoundGroup)
	override function updateTransform():Void
	{
		_transform.volume = #if FLX_SOUND_SYSTEM FlxG.sound.muted ? 0 : FlxG.sound.volume * #end (group?.volume ?? 1) * _volume * _volumeAdjust;

		if (_channel != null)
		{
			_channel.soundTransform = _transform;
		}
		updateFilter();
		updateEffect();
	}

	@:access(openfl.media.SoundChannel)
	inline function getAudioSource()
	{
		#if (openfl < "9.3.2")
		return this._channel?.__source;
		#else
		return this._channel?.__audioSource;
		#end
	}


	public function updateEffect()
	@:privateAccess
	{
		if (getAudioSource() == null || curEffect.name == 'NULL') return;
		final handle = getAudioSource().__backend.handle;
		_effectAuxSlot ??= AL.createAux();
		if (effect == null)
		{
			AL.auxi(_effectAuxSlot, AL.EFFECTSLOT_EFFECT, AL.EFFECT_NULL);
			AL.removeSend(handle, 0);
		}
		else
		{
			AL.auxi(_effectAuxSlot, AL.EFFECTSLOT_EFFECT, effect);
			AL.removeSend(handle, 0);
			AL.source3i(handle, AL.AUXILIARY_SEND_FILTER, _effectAuxSlot, 0, filterIndex);
		}
	}

	public function updateFilter()
	@:privateAccess
	{
		if (getAudioSource() == null || curFilter.name == 'NULL') return;
		final handle = getAudioSource().__backend.handle;
		if(filter == null)
			AL.removeDirectFilter(handle);
		else
			AL.sourcei(handle, AL.DIRECT_FILTER, filter);
	}
}
@:enum
private abstract OPENALSetType(Byte) {
	var OPENAL_FLOAT:OPENALSetType = 0;
	var OPENAL_INT:OPENALSetType = 1;
	@:to
	function toString():String {
		return switch (cast this) {
			case OPENAL_FLOAT: "OPENAL_FLOAT";
			default: "OPENAL_INT";
		}
	}
	@:from
	static function fromString(str:String):OPENALSetType {
		return switch (str.toLowerCase()) {
			case "f" | "float" | "openal_float": OPENAL_FLOAT;
			default: OPENAL_INT;
		}
	}
}

// fuck it inlines
@:publicFields
private class SoundFields{
	static final NONE:Int = 0;
	static final FALSE:Int = 0;
	static final TRUE:Int = 1;
	static final SOURCE_RELATIVE:Int = 0x202;
	static final CONE_INNER_ANGLE:Int = 0x1001;
	static final CONE_OUTER_ANGLE:Int = 0x1002;
	static final PITCH:Int = 0x1003;
	static final POSITION:Int = 0x1004;
	static final DIRECTION:Int = 0x1005;
	static final VELOCITY:Int = 0x1006;
	static final LOOPING:Int = 0x1007;
	static final BUFFER:Int = 0x1009;
	static final GAIN:Int = 0x100A;
	static final MIN_GAIN:Int = 0x100D;
	static final MAX_GAIN:Int = 0x100E;
	static final ORIENTATION:Int = 0x100F;
	static final SOURCE_STATE:Int = 0x1010;
	static final INITIAL:Int = 0x1011;
	static final PLAYING:Int = 0x1012;
	static final PAUSED:Int = 0x1013;
	static final STOPPED:Int = 0x1014;
	static final BUFFERS_QUEUED:Int = 0x1015;
	static final BUFFERS_PROCESSED:Int = 0x1016;
	static final REFERENCE_DISTANCE:Int = 0x1020;
	static final ROLLOFF_FACTOR:Int = 0x1021;
	static final CONE_OUTER_GAIN:Int = 0x1022;
	static final MAX_DISTANCE:Int = 0x1023;
	static final SEC_OFFSET:Int = 0x1024;
	static final SAMPLE_OFFSET:Int = 0x1025;
	static final BYTE_OFFSET:Int = 0x1026;
	static final SOURCE_TYPE:Int = 0x1027;
	static final STATIC:Int = 0x1028;
	static final STREAMING:Int = 0x1029;
	static final UNDETERMINED:Int = 0x1030;
	static final FORMAT_MONO8:Int = 0x1100;
	static final FORMAT_MONO16:Int = 0x1101;
	static final FORMAT_STEREO8:Int = 0x1102;
	static final FORMAT_STEREO16:Int = 0x1103;
	static final FREQUENCY:Int = 0x2001;
	static final BITS:Int = 0x2002;
	static final CHANNELS:Int = 0x2003;
	static final SIZE:Int = 0x2004;
	static final NO_ERROR:Int = 0;
	static final INVALID_NAME:Int = 0xA001;
	static final INVALID_ENUM:Int = 0xA002;
	static final INVALID_VALUE:Int = 0xA003;
	static final INVALID_OPERATION:Int = 0xA004;
	static final OUT_OF_MEMORY:Int = 0xA005;
	static final VENDOR:Int = 0xB001;
	static final VERSION:Int = 0xB002;
	static final RENDERER:Int = 0xB003;
	static final EXTENSIONS:Int = 0xB004;
	static final DOPPLER_FACTOR:Int = 0xC000;
	static final SPEED_OF_SOUND:Int = 0xC003;
	static final DOPPLER_VELOCITY:Int = 0xC001;
	static final DISTANCE_MODEL:Int = 0xD000;
	static final INVERSE_DISTANCE:Int = 0xD001;
	static final INVERSE_DISTANCE_CLAMPED:Int = 0xD002;
	static final LINEAR_DISTANCE:Int = 0xD003;
	static final LINEAR_DISTANCE_CLAMPED:Int = 0xD004;
	static final EXPONENT_DISTANCE:Int = 0xD005;
	static final EXPONENT_DISTANCE_CLAMPED:Int = 0xD006;
	/* Listener properties. */
	static final METERS_PER_UNIT:Int = 0x20004;
	/* Source properties. */
	static final DIRECT_FILTER:Int = 0x20005;
	static final AUXILIARY_SEND_FILTER:Int = 0x20006;
	static final AIR_ABSORPTION_FACTOR:Int = 0x20007;
	static final ROOM_ROLLOFF_FACTOR:Int = 0x20008;
	static final CONE_OUTER_GAINHF:Int = 0x20009;
	static final DIRECT_FILTER_GAINHF_AUTO:Int = 0x2000A;
	static final AUXILIARY_SEND_FILTER_GAIN_AUTO:Int = 0x2000B;
	static final AUXILIARY_SEND_FILTER_GAINHF_AUTO:Int = 0x2000C;
	/* Effect properties. */
	/* Reverb effect parameters */
	static final REVERB_DENSITY:Int = 0x0001;
	static final REVERB_DIFFUSION:Int = 0x0002;
	static final REVERB_GAIN:Int = 0x0003;
	static final REVERB_GAINHF:Int = 0x0004;
	static final REVERB_DECAY_TIME:Int = 0x0005;
	static final REVERB_DECAY_HFRATIO:Int = 0x0006;
	static final REVERB_REFLECTIONS_GAIN:Int = 0x0007;
	static final REVERB_REFLECTIONS_DELAY:Int = 0x0008;
	static final REVERB_LATE_REVERB_GAIN:Int = 0x0009;
	static final REVERB_LATE_REVERB_DELAY:Int = 0x000A;
	static final REVERB_AIR_ABSORPTION_GAINHF:Int = 0x000B;
	static final REVERB_ROOM_ROLLOFF_FACTOR:Int = 0x000C;
	static final REVERB_DECAY_HFLIMIT:Int = 0x000D;
	/* EAX Reverb effect parameters */ // Windows only... ?
	static final EAXREVERB_DENSITY:Int = 0x0001;
	static final EAXREVERB_DIFFUSION:Int = 0x0002;
	static final EAXREVERB_GAIN:Int = 0x0003;
	static final EAXREVERB_GAINHF:Int = 0x0004;
	static final EAXREVERB_GAINLF:Int = 0x0005;
	static final EAXREVERB_DECAY_TIME:Int = 0x0006;
	static final EAXREVERB_DECAY_HFRATIO:Int = 0x0007;
	static final EAXREVERB_DECAY_LFRATIO:Int = 0x0008;
	static final EAXREVERB_REFLECTIONS_GAIN:Int = 0x0009;
	static final EAXREVERB_REFLECTIONS_DELAY:Int = 0x000A;
	static final EAXREVERB_REFLECTIONS_PAN:Int = 0x000B;
	static final EAXREVERB_LATE_REVERB_GAIN:Int = 0x000C;
	static final EAXREVERB_LATE_REVERB_DELAY:Int = 0x000D;
	static final EAXREVERB_LATE_REVERB_PAN:Int = 0x000E;
	static final EAXREVERB_ECHO_TIME:Int = 0x000F;
	static final EAXREVERB_ECHO_DEPTH:Int = 0x0010;
	static final EAXREVERB_MODULATION_TIME:Int = 0x0011;
	static final EAXREVERB_MODULATION_DEPTH:Int = 0x0012;
	static final EAXREVERB_AIR_ABSORPTION_GAINHF:Int = 0x0013;
	static final EAXREVERB_HFREFERENCE:Int = 0x0014;
	static final EAXREVERB_LFREFERENCE:Int = 0x0015;
	static final EAXREVERB_ROOM_ROLLOFF_FACTOR:Int = 0x0016;
	static final EAXREVERB_DECAY_HFLIMIT:Int = 0x0017;
	/* Chorus effect parameters */
	static final CHORUS_WAVEFORM:Int = 0x0001;
	static final CHORUS_PHASE:Int = 0x0002;
	static final CHORUS_RATE:Int = 0x0003;
	static final CHORUS_DEPTH:Int = 0x0004;
	static final CHORUS_FEEDBACK:Int = 0x0005;
	static final CHORUS_DELAY:Int = 0x0006;
	/* Distortion effect parameters */
	static final DISTORTION_EDGE:Int = 0x0001;
	static final DISTORTION_GAIN:Int = 0x0002;
	static final DISTORTION_LOWPASS_CUTOFF:Int = 0x0003;
	static final DISTORTION_EQCENTER:Int = 0x0004;
	static final DISTORTION_EQBANDWIDTH:Int = 0x0005;
	/* Echo effect parameters */
	static final ECHO_DELAY:Int = 0x0001;
	static final ECHO_LRDELAY:Int = 0x0002;
	static final ECHO_DAMPING:Int = 0x0003;
	static final ECHO_FEEDBACK:Int = 0x0004;
	static final ECHO_SPREAD:Int = 0x0005;
	/* Flanger effect parameters */
	static final FLANGER_WAVEFORM:Int = 0x0001;
	static final FLANGER_PHASE:Int = 0x0002;
	static final FLANGER_RATE:Int = 0x0003;
	static final FLANGER_DEPTH:Int = 0x0004;
	static final FLANGER_FEEDBACK:Int = 0x0005;
	static final FLANGER_DELAY:Int = 0x0006;
	/* Frequency shifter effect parameters */
	static final FREQUENCY_SHIFTER_FREQUENCY:Int = 0x0001;
	static final FREQUENCY_SHIFTER_LEFT_DIRECTION:Int = 0x0002;
	static final FREQUENCY_SHIFTER_RIGHT_DIRECTION:Int = 0x0003;
	/* Vocal morpher effect parameters */
	static final VOCAL_MORPHER_PHONEMEA:Int = 0x0001;
	static final VOCAL_MORPHER_PHONEMEA_COARSE_TUNING:Int = 0x0002;
	static final VOCAL_MORPHER_PHONEMEB:Int = 0x0003;
	static final VOCAL_MORPHER_PHONEMEB_COARSE_TUNING:Int = 0x0004;
	static final VOCAL_MORPHER_WAVEFORM:Int = 0x0005;
	static final VOCAL_MORPHER_RATE:Int = 0x0006;
	/* Pitchshifter effect parameters */
	static final PITCH_SHIFTER_COARSE_TUNE:Int = 0x0001;
	static final PITCH_SHIFTER_FINE_TUNE:Int = 0x0002;
	/* Ringmodulator effect parameters */
	static final RING_MODULATOR_FREQUENCY:Int = 0x0001;
	static final RING_MODULATOR_HIGHPASS_CUTOFF:Int = 0x0002;
	static final RING_MODULATOR_WAVEFORM:Int = 0x0003;
	/* Autowah effect parameters */
	static final AUTOWAH_ATTACK_TIME:Int = 0x0001;
	static final AUTOWAH_RELEASE_TIME:Int = 0x0002;
	static final AUTOWAH_RESONANCE:Int = 0x0003;
	static final AUTOWAH_PEAK_GAIN:Int = 0x0004;
	/* Compressor effect parameters */
	static final COMPRESSOR_ONOFF:Int = 0x0001;
	/* Equalizer effect parameters */
	static final EQUALIZER_LOW_GAIN:Int = 0x0001;
	static final EQUALIZER_LOW_CUTOFF:Int = 0x0002;
	static final EQUALIZER_MID1_GAIN:Int = 0x0003;
	static final EQUALIZER_MID1_CENTER:Int = 0x0004;
	static final EQUALIZER_MID1_WIDTH:Int = 0x0005;
	static final EQUALIZER_MID2_GAIN:Int = 0x0006;
	static final EQUALIZER_MID2_CENTER:Int = 0x0007;
	static final EQUALIZER_MID2_WIDTH:Int = 0x0008;
	static final EQUALIZER_HIGH_GAIN:Int = 0x0009;
	static final EQUALIZER_HIGH_CUTOFF:Int = 0x000A;
	/* Effect type */
	static final EFFECT_FIRST_PARAMETER:Int = 0x0000;
	static final EFFECT_LAST_PARAMETER:Int = 0x8000;
	static final EFFECT_TYPE:Int = 0x8001;
	/* Effect types, used with the AL_EFFECT_TYPE property */
	static final EFFECT_NULL:Int = 0x0000;
	static final EFFECT_EAXREVERB:Int = 0x8000;
	static final EFFECT_REVERB:Int = 0x0001;
	static final EFFECT_CHORUS:Int = 0x0002;
	static final EFFECT_DISTORTION:Int = 0x0003;
	static final EFFECT_ECHO:Int = 0x0004;
	static final EFFECT_FLANGER:Int = 0x0005;
	static final EFFECT_FREQUENCY_SHIFTER:Int = 0x0006;
	static final EFFECT_VOCAL_MORPHER:Int = 0x0007;
	static final EFFECT_PITCH_SHIFTER:Int = 0x0008;
	static final EFFECT_RING_MODULATOR:Int = 0x0009;
	static final EFFECT_AUTOWAH:Int = 0x000A;
	static final EFFECT_COMPRESSOR:Int = 0x000B;
	static final EFFECT_EQUALIZER:Int = 0x000C;
	/* Auxiliary Effect Slot properties. */
	static final EFFECTSLOT_EFFECT:Int = 0x0001;
	static final EFFECTSLOT_GAIN:Int = 0x0002;
	static final EFFECTSLOT_AUXILIARY_SEND_AUTO:Int = 0x0003;
	/* NULL Auxiliary Slot ID to disable a source send. */
	// public static  var EFFECTSLOT_NULL:Int = 0x0000;		//Use removeSend instead
	/* Filter properties. */
	/* Lowpass filter parameters */
	static final LOWPASS_GAIN:Int = 0x0001; /*Not exactly a lowpass. Apparently it's a shelf*/
	static final LOWPASS_GAINHF:Int = 0x0002;
	/* Highpass filter parameters */
	static final HIGHPASS_GAIN:Int = 0x0001;
	static final HIGHPASS_GAINLF:Int = 0x0002;
	/* Bandpass filter parameters */
	static final BANDPASS_GAIN:Int = 0x0001;
	static final BANDPASS_GAINLF:Int = 0x0002;
	static final BANDPASS_GAINHF:Int = 0x0003;
	/* Filter type */
	static final FILTER_FIRST_PARAMETER:Int = 0x0000; /*This is not even in the documentation*/
	static final FILTER_LAST_PARAMETER:Int = 0x8000; /*This one neither*/
	static final FILTER_TYPE:Int = 0x8001;
	/* Filter types, used with the AL_FILTER_TYPE property */
	static final FILTER_NULL:Int = 0x0000;
	static final FILTER_LOWPASS:Int = 0x0001;
	static final FILTER_HIGHPASS:Int = 0x0002;
	static final FILTER_BANDPASS:Int = 0x0003;
}
#else
class EffectSound extends FlxSound
{
	public inline static function load(?embeddedSound:flixel.system.FlxAssets.FlxSoundAsset, volume = 1.0, looped = false,
			?group:flixel.sound.FlxSoundGroup, autoDestroy = false, autoPlay = false, ?url:String, ?onComplete:Void->Void, ?onLoad:Void->Void):EffectSound
		return cast CoolUtil.loadSound(embeddedSound, volume, looped, EffectSound, group, autoDestroy, autoPlay, url, onComplete, onLoad);

}
#end