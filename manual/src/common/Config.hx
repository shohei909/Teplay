package common;
import StringTools.htmlEscape in escape;

/**
 * ...
 * @author shohei909
 */
class Config{
	static public var localizedStrings = [
		"ja" => {
			title : "Teplay",
			headTitle : "静的サイトジェネレータ Teplay",
			index 		: "トップ",
			tutorial 	: "チュートリアル",
			plugin 		: "プラグイン",
			tplt 		: "テンプレートエンジン",
			github 		: "Github",
			next : escape("次 >>"),
			prev : escape("前 <<"),
			firstPage 	: "--",
			lastPage 	: "--",
		},
		
		"en" => {
			title : "Teplay",
			headTitle : 'Static Site Generator "Teplay"',
			index : "Top",
			tutorial : "Tutorial",
			tplt : "Template Engine",
			plugin : "Plugin",
			github : "Github",
			next : escape("Next >>"),
			prev : escape("Prev <<"),
			firstPage 	: "--",
			lastPage 	: "--",
		}
	];
	
	static public var menu = [
		{
			page : "index", 
			link : "index.html",
		},{
			page : "tutorial", 
			link : "tutorial.html",
		},{
			page : "plugin", 
			link : "plugin.html",
		},{
			page : "tplt", 
			link : "tplt.html",
		},{
			page : "github", 
			link : "https://github.com/shohei909/Teplay",
		}
	];
	
	static public var httpEreg = ~/^(http|https):\/\//m;
}