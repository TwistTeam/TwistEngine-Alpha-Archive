package game.backend.system.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end
class MacroUtils
{
	public static macro function getDefineString(key:String, defaultValue:String):Expr
		return macro $v{Context.definedValue(key) ?? defaultValue}

	public static macro function getDefineInt(key:String, defaultValue:Int):Expr
	{
		final valueName:String = Context.definedValue(key);

		if (valueName != null)
		{
			final value:Null<Int> = Std.parseInt(valueName);

			if (value != null)
				return macro $v{value};
		}

		return macro $v{defaultValue};
	}

	public static macro function getDefineFloat(key:String, defaultValue:Float):Expr
	{
		final valueName:String = Context.definedValue(key);

		if (valueName != null)
		{
			final value:Null<Float> = Std.parseFloat(valueName);

			if (value != null)
				return macro $v{value};
		}

		return macro $v{defaultValue};
	}

	public static macro function getDefineBool(key:String, defaultValue:Bool):Expr
	{
		final valueName:String = Context.definedValue(key);

		if (valueName != null)
		{
			return macro $v{valueName.toLowerCase() == "true"};
		}

		return macro $v{defaultValue};
	}

	public static macro function generateReflectionLike(totalArguments:Int, funcName:String, argsName:String)
	{
		totalArguments++;

		var funcCalls = [];
		for (i in 0...totalArguments)
		{
			funcCalls.push(macro $i{funcName}($a{[
				for (d in 0...i)
					macro $i{argsName}[$v{d}]
			]}));
		}

		var expr = {
			pos: Context.currentPos(),
			expr: ESwitch(macro($i{argsName}.length), [
				for (i in 0...totalArguments)
					{
						values: [macro $v{i}],
						expr: funcCalls[i],
						guard: null,
					}
			], macro throw "Too many arguments")
		}

		return expr;
	}

	public static macro function safeSet(variable:Null<Expr>, value:Null<Expr>):Null<Expr>
	{
		return macro if (${value} != null) ${variable} = ${value};
	}

	public static macro function safeSetWrapper(variable:Null<Expr>, value:Null<Expr>, wrapper:Null<Expr>):Null<Expr>
	{
		return macro if (${value} != null) ${variable} = ${wrapper}(${value});
	}

	public static macro function safeReflection(variable:Null<Expr>, value:Null<Expr>, field:Null<Expr>):Null<Expr>
	{
		return macro if (Reflect.hasField(${value}, ${field})) ${variable} = Reflect.field(${value}, ${field});
	}
}
