package teplay.core;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.Log;
import haxe.macro.Context;
import haxe.PosInfos;
import sys.FileSystem;

/**
 * ...
 * @author shohei909
 */
class TeplayTemplate {
	private var tokens:Array<TeplayTemplateToken>;
	public var currentPos:PosInfos;
	public var filePath:String;
	public var logger:TeplayLogger;
	
	public function new(str:String, logger:TeplayLogger) {
		this.logger = logger;
		tokens = parse(str);
	}
	
	static function parse( str:String ) {
		var result = [];
		var pos = 0;
		var splitter = new EReg("%%+", "");
		
		while (splitter.match(str.substr(pos))) {
			var key = splitter.matched(0);
			var textEnd = pos + splitter.matchedPos().pos;
			var scriptStart = textEnd + key.length;
			var index = str.substr(scriptStart).indexOf(key);
			
			if (index == -1) break;
			
			result.push(Text(str.substring(pos, textEnd), { start:pos, end:textEnd } ));
			
			var scriptEnd = scriptStart + index;
			pos = scriptEnd + key.length;
			
			result.push( Script(str.substring(scriptStart, scriptEnd), { start:scriptStart, end:scriptEnd } ) );
		}
		
		result.push(Text(str.substr(pos), {start:pos, end:str.length}));
		return result;
	}
	
	var result = "";
	
	public function execute(scope:Array<Dynamic>) {
		result = "";
		var globals = marge(scope);
		lock(globals);
		
		var objects = [globals, {}];
		var ereg = ~/(^|;)[\s\t\n\r]*$/;
		
		for (t in tokens) {
			switch (t) {
			case Text(str, p):
				result += str;
				
			case Script(str, p):
				var pos = currentPos = new TeplayPosInfos(filePath, null, p.start, p.end);
				
				var p = TeplayTools.posInfosToPosition(pos);
				var s = if (ereg.match(str)) 
					str + " ";
				else 
					str + ";";
					
				var logp = logger.currentPos;
				logger.currentPos = pos;
				
				var expr = null;
				var value = null;
				
				//s = ~/[\r\n\t]/g.replace(s, " ");
				
				try {
					expr =  Context.parse("{ " + s + "}", p );
					value = TeplayScriptRunner.run(expr, objects);
				} catch (e:TeplayError) {
					throw e;
				} catch (d:Dynamic) {
					throw TeplayError.EXECUTE_ERROR(Std.string(d), pos);
				}
				
				logger.currentPos = logp;
				
				if (value == null) {
					logger.warning("null", pos);
				} else {
					result += value;
				}
			}
		}
		return result;
	}
	
	public function add( string:String ) {
		result += string;
	}
	
	public function marge(scope:Array<Dynamic>) {
		var result = { };
		for (s in scope) {
			var obj = if (Std.is(s, StringMap)) 
				TeplayTools.mapToStructure(s) 
			else 
				s;
			
			for (key in Reflect.fields(obj)) {
				Reflect.setField(result, key, Reflect.field(obj, key));
			}
		}
		return result;
	}

	static public function lock(obj:Dynamic) {
		switch(Type.typeof(obj)) {
			case TObject :
				if (!Reflect.hasField(obj, "__locked_for_teplay")) {
					Reflect.setField(obj, "__locked_for_teplay", true);
					for(f in Reflect.fields(obj)) {
						lock(Reflect.field(obj, f));
					}
				}
				
			case _ :
		}
	}
}

typedef Pos = {
	start : Int,
	end : Int
}

enum TeplayTemplateToken {
	Text( str:String, pos:Pos );
	Script( str:String, pos:Pos );
}