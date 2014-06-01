package teplay.core;
import haxe.PosInfos;

typedef TeplayLogger = { 
	var currentPos:PosInfos; 
	function warning(msg:String, pos:PosInfos):Void;
}