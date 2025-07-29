package game.backend.system.scripts;

interface IScript {
	public function call(eventName:String, ?funcArgs:Array<Dynamic>):Dynamic;
}