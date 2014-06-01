package teplay.plugin;
import haxe.Template;
import teplay.core.TeplayBasePlugin;
import teplay.Teplayer;

/**
 * ...
 * @author shohei909
 */
class RedcarpetPlugin extends TeplayBasePlugin{
	public var path:String;
	public var args:Array<String>;
	
	public function new (rubyDir:String, args:Array<String>) {
		this.path = rubyDir + "/bin/redcarpet";
		this.args = args;
	}
	
	override public function apply(player:Teplayer) {
		super.apply(player);
		
		//markdown ".md" file (Ex: aaa.html.md -> Ex: aaa.html)
		player.addExtension("md", redcarpet);
	}
	
	public function redcarpet(data:String) {
		return executeOnTemporaryDir(path, setup.bind(data));
	}
	
	function setup(data, input, output) {
		write(input, data);
		return args.concat([input, '1>$output']);
	}
}