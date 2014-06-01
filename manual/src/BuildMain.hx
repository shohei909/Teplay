import common.Config;
import common.HtmlWriter;
import teplay.plugin.PygmentsPlugin;
import teplay.plugin.RedcarpetPlugin;
import teplay.plugin.SassPlugin;
import teplay.Teplayer;

class BuildMain {
	static public var pythonDir				= "C:\\Python34";
	static public var rubyDir				= "C:\\Ruby193";
	static public var redcarpetArgs 		= ["--render-hard-wrap", "--render-xhtml", "--parse-fenced-code-blocks", "--parse-tables"];
	static public var sassArgs				= ["--style", "compressed", "--no-cache", "--trace"];
	
	static function main() {
		
		var player = new Teplayer(
			"bin", 
			"manual/resource", 
			{
				HtmlWriter 	: HtmlWriter,
				scripts 	: [],
				styleSheets	: ["css/reset.css", "css/teplay.css", "css/pygments.css", "css/main.css"],
			}
		);
		
		var articles = player.getArticleList("_internal/article/ja/");
		player.addBranch("article", articles);
		
		player.addBranch( 
			"lang", 
			{
				ja : Config.localizedStrings["ja"],
				en : Config.localizedStrings["en"],
			}
		);
		
		player.addPlugin(new RedcarpetPlugin(rubyDir, redcarpetArgs));
		player.addPlugin(new SassPlugin(rubyDir, sassArgs));
		
		#if !debug
		player.addPlugin(new PygmentsPlugin(pythonDir));
		#end
		
		player.play();
	}
}