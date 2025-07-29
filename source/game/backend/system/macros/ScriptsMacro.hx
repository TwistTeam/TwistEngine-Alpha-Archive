package game.backend.system.macros;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;

/**
 * Macros containing additional help functions to expand HScript capabilities.
 */
class ScriptsMacro
{
	/*
	public static function fixOptionalArgs():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		if (fields.length == 0) return null;

		var clRef:Null<Ref<ClassType>> = Context.getLocalClass();
		if (clRef == null) return null;

		var cl = clRef.get();
		if (cl.isInterface || cl.isExtern || cl.isAbstract) return null;

		var clStr:String = clRef.toString();
		var field:Field;
		var i:UInt = 0;
		var len:UInt = fields.length;
		while (i < len)
		{
			field = fields[i];
			if (field.access == null || !field.access.contains(AMacro) || !field.access.contains(AExtern))
			{
				switch (field.kind)
				{
					case FFun(func) if (func.args.length != 0):
						trace(clStr + "." + field.name);
						var optArgs:Array<FunctionArg> = [];
						for (arg in func.args)
						{
							if (arg.value == null || arg.value.expr.match(EConst(CIdent("Null"))))
								continue;

							// var complexType:ComplexType = arg.type;
							// if (complexType == null)
							// {
							// 	trace(arg.value);
							// 	switch(arg.value.expr)
							// 	{
							// 		case EConst(CIdent("false" | "true")):
							// 			complexType = macro:Bool;
							// 		case EConst(CInt(_)):
							// 			complexType = macro:Int;
							// 		case EConst(CFloat(_)):
							// 			complexType = macro:Float;
							// 		default:
							// 			complexType = macro:Dynamic;
							// 	}
							// 	// complexType = Context.toComplexType(Context.typeof(arg.value));
							// 	// if (complexType == null)
							// 	// arg.type = TOptional(arg.type);
							// }
							// arg.type = macro:Null<$complexType>;

							optArgs.push(arg);
						}
						if (optArgs.length != 0)
						{
							// trace(optArgs);
							var exprs = [func.expr];
							for (i in optArgs)
								exprs.unshift(macro if ($i{i.name} == null) $i{i.name} = $e{i.value});
							func.expr = {
								expr: EBlock(exprs),
								pos: Context.currentPos()
							};
							for (i in optArgs)
							{
								i.opt = true;
								// i.value = macro null;
								i.value = null;
							}
						}
					case _:
				}
			}
			i++;
		}
		return fields;
	}
	*/
	/*
	public static function compileGenericFunctions():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();
		if (fields.length == 0) return null;

		var clRef:Null<Ref<ClassType>> = Context.getLocalClass();
		if (clRef == null) return null;

		var cl = clRef.get();
		if (cl.isInterface || cl.isExtern || cl.isAbstract) return null;

		var clStr:String = clRef.toString();
		var field:Field;
		var i:UInt = 0;
		var len:UInt = fields.length;
		while (i < len)
		{
			field = fields[i];
			switch (field.kind)
			{
				case FFun(fun):
					if (field.meta.find(m -> m.name == ":generic") != null)
					{
						trace(clStr + "." + field.name);
						var newMeta:Metadata = field.meta.filter(f -> f.name != ":generic");
						newMeta.push({
							name: ":native",
							params: [field.access.contains(AStatic) ? macro $v{clStr + "_obj" + "." + field.name} : macro $v{field.name}],
							pos: Context.currentPos()
						});
						newMeta.push({
							name: ":keep",
							pos: Context.currentPos()
						});

						var func_callArgs:Array<Expr> = [for (arg in fun.args) macro $i{arg.name}];
						var funcPath = field.name;
						var haseReturn:Bool = fun.ret != null ? haxe.macro.ComplexTypeTools.toString(fun.ret) != "Void" : false;
						ExprTools.iter(fun.expr, expr -> {
							if (haseReturn) return;
							// trace(haxe.macro.ExprTools.toString(expr));
							haseReturn = expr.expr.match(EReturn(_)) && !expr.expr.match(EReturn(null));
						});
						var newField:Field = {
							name: field.name + "_piss_me",
							doc: field.doc,
							access: field.access,
							meta: newMeta,
							pos: Context.currentPos(),
							kind: FFun({
								args: fun.args,
								ret: fun.ret,
								expr: haseReturn ?
									macro return $i{funcPath}($a{func_callArgs})
								:
									macro $i{funcPath}($a{func_callArgs}),
								params: fun.params
							})
						}

						fields.insert(i, newField);

						i++;
						len++;
					}
				case _:
			}
			i++;
		}
		return fields;
	}
	*/

	public static function addAdditionalClasses() {
		Compiler.include("game", ['game.backend.system.macros']);

		if (Context.defined("display") || Context.defined("hl") || Context.defined("html5")) return; // todo: more for hashlink and html5

		Compiler.include("flixel.system", ['flixel.system.macros']);
		Compiler.include("flixel.util", ['flixel.util.FlxSignal']);
		for(inc in [
			// BASE HAXE
			"DateTools",		"EReg",			"Lambda",			"StringBuf",
			// "haxe.crypto",		"haxe.display",	"haxe.exceptions",

			// FLIXEL
			"flixel.ui",		"flixel.tweens",	"flixel.tile",		"flixel.text",		"flixel.sound",
			"flixel.path",		"flixel.math",		"flixel.input",		"flixel.group",		"flixel.graphics",
			"flixel.effects",	"flixel.animation",

			// FLIXEL ADDONS
			"flixel.addons.api",	"flixel.addons.display",	"flixel.addons.effects",	"flixel.addons.ui",
			"flixel.addons.plugin",	"flixel.addons.text",		"flixel.addons.tile",		"flixel.addons.transition",
			"flixel.addons.util",

			// OTHER LIBRARIES & STUFF
			"openfl",

			#if (native && android)
			// HaxeExtension & MAJigsaw77 stuff
			"extension",
			#end

			#if format "format", #end
			#if funk.vis "funkin.vis", #end
			#if THREE_D_ALLOWED "away3d", "flx3d", #end
			#if sys "sys", #end
			#if hxvlc "hxvlc.flixel", "hxvlc.openfl", #end
			#if nape_haxe4 "nape", #end
			"spine",
		])
		{
			Compiler.include(inc);
		}
	}
}
#end
