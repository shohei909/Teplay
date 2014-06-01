package teplay.core;

class TeplayPosInfos {
	public var fileName : String;
	public var lineNumber : Int;
	public var className : String;
	public var methodName : String;
	public var customParams : Array<Dynamic>;
	
	public function new (fileName:String, ?lineNumber:Int, ?min:Int, ?max:Int) {
		customParams = [];
		customParams[0] = min;
		customParams[1] = max;
		
		this.fileName = fileName;
		this.lineNumber = lineNumber;
	}
}


typedef TeplayErrorInfos = {
	msg:String, 
	pos:TeplayPosInfos
}