package teplay.plugin;
import haxe.xml.Fast;
import haxe.xml.Parser;
import sys.io.File;
import teplay.core.TeplayBasePlugin;
import teplay.core.TeplayPosInfos;
import teplay.Teplayer;

/**
 * ...
 * @author shohei909
 */
class PygmentsPlugin extends TeplayBasePlugin {
	public var path:String;
	public var args:Array<String>;
	
	public function new (pythonDir:String) {
		this.path = pythonDir + "/Scripts/pygmentize";
		this.args = [];
	}
	
	override public function apply(player:Teplayer) {
		super.apply(player);
		
		player.addOutputFilter("html", pygmentizeHtml);
	}
	
	public dynamic function configFromXml(xml:Xml) {
		if (xml.nodeType == Xml.Element && xml.nodeName == "code") {
			var cl = xml.get("class");
			if (cl != null) {
				var arr = cl.split(":");
				
				return {
					lang : arr.shift(),
					title : arr.join(":")
				}
			}
		}
		
		return null;
	}
	
	function pygmentizeHtml(fileName) {	
		var r = File.read(fileName);
		var html = r.readAll().toString();
		r.close();
		
		var time = Sys.cpuTime();
		var node = null;
		
		try { 
			node = Parser.parse(html);
		} catch (d:Dynamic) {
			player.warning('Pygments Plugin : html parse error : $d', new TeplayPosInfos(fileName, 0,0,0));
		}
		
		if (node == null) return;
		
		var changed = pygmentizeNode(node, fileName);
		if (changed) {
			var w = File.write(fileName);
			w.writeString(node.toString());
			w.close();
		}
	}
	
	function pygmentizeNode(node:Xml, fileName) {
		var config = configFromXml(node);
		if (config != null && config.lang != null) {
			var html = StringTools.htmlUnescape((StringTools.htmlUnescape(new Fast(node).innerHTML)));
			var result = if (config.lang == "") {
				html;
			} else {
				executeOnTemporaryDir("pygmentize", setup.bind(config.lang, html));
			}
			
			if (result == null) { result = html; }
			
			var parent = node.parent;
			parent.removeChild(node);
			
			if (config.title != "") {
				parent.addChild(Parser.parse('<div class="code_title">${config.title}</div>'));
			}
			
			parent.addChild(Parser.parse('<code class="${config.lang}">$result</code>'));
			
			return true;
		}
		
		var changed = false;
		for (e in node.elements()) {
			if (pygmentizeNode(e,fileName)) changed = true;
		}
		
		return changed;
	}
	
	function setup(language, string, input, output) {
		write(input, string);
		return args.concat(["-f", "html", "-l", language, "-P", "nowrap=true", "-o", output, input]);
	}
}