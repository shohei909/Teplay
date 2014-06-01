package teplay.plugin;
import sys.FileSystem;
import teplay.core.TeplayBasePlugin;
import teplay.core.TeplayPosInfos;
import teplay.Teplayer;

/**
 * ...
 * @author shohei909
 */

class SassPlugin extends TeplayBasePlugin{
	public var path:String;
	public var args:Array<String>;
	
	public function new (rubyDir:String, args:Array<String>) {
		this.path = rubyDir + "/bin/sass";
		this.args = args;
	}
	
	override public function apply(player:Teplayer) {
		super.apply(player);
		
		player.addOutputFilter("sass", sass);
		player.addOutputFilter("scss", scss);
	}
	
	public function sass(inputPath:String) {
		var segs = inputPath.split(".");
		segs.pop();
		var output = segs.join(".") + ".css";
		execute(path, args.concat(['$inputPath:$output']), readError);
	}
	
	public function scss(inputPath:String) {
		var segs = inputPath.split(".");
		segs.pop();
		var output = segs.join(".") + ".css";
		execute(path, args.concat(['$inputPath:$output']), readError);
	}
	
	function readError(data:String) {
		var reg = ~/^([^\n\r]+)[\n\r\s]+on line ([0-9]+) of ([^\n\r]+)/;
		var result = [];
		
		while (reg.match(data)) {
			result.push({
				msg : reg.matched(1),
				pos : new TeplayPosInfos(FileSystem.fullPath(reg.matched(3)), Std.parseInt(reg.matched(2)))
			});
			data = reg.matchedRight();
		}
		
		return result;
	}
}