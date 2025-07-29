package game.shaders;

class GayBoyShader extends FlxShader
{
	public var amount(default, set):Float = 1000;
	public var threshold(default, set):Float = 0.65;

	inline function set_amount(value:Float)
		return amount = _iamount.value[0] = value;
	inline function set_threshold(value:Float)
		return threshold = _ithreshold.value[0] = value;

	@:glFragmentSourceFile('./sourceShaders/GayBoyEffect.frag')
	public function new(){
		super();
		#if !macro
		_iamount.value = [amount];
		_ithreshold.value = [threshold];
		#end
	}
}
