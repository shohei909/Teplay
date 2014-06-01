package teplay.core;
import haxe.ds.StringMap;
import haxe.PosInfos;
import haxe.macro.Context;
import sys.io.File;

/**
 * ...
 * @author shohei909
 */
class TeplayTools{

	static public function posInfosToPosition(posInfos:PosInfos) {
		#if macro
		var ps = posInfos.customParams;
		var min, max;
		if ( ps != null && ps.length > 1 && ps[0] != null && ps[1] != null ) {
			min = ps[0];
			max = ps[1];
		} else {
			min = 0;
			max = 0;
			var r	 = File.read(posInfos.fileName);
			var file = r.readAll().toString();
			r.close();
			var ereg = ~/(\r\n|\r|\n)/;
			min = 0;
			for ( i in 0...posInfos.lineNumber - 1 ) {
				ereg.match( file );
				var pos = ereg.matchedPos();
				min += pos.pos + pos.len;
				file = ereg.matchedRight();
			}
			max = min + if (ereg.match( file )) ereg.matchedPos().pos else file.length;
		}
		return Context.makePosition({file : posInfos.fileName, min : min, max : max});
		#else
		return {file : posInfos.fileName, min : 0, max : 0}
		#end
	}
	
	static public function mapToStructure(map:Dynamic) {
		var result:Dynamic = {};
		var m:StringMap<Dynamic> = map;
		for (key in m.keys()) {
			Reflect.setField(result, key, map.get(key));
		}
		return result;
	}
}