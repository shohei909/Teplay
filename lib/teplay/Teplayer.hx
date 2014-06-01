package teplay;

import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.PosInfos;
import sys.FileSystem;
import sys.io.File;
import teplay.core.TeplayContext;
import teplay.core.TeplayError;
import teplay.core.TeplayPosInfos.TeplayErrorInfos;
import teplay.core.TeplayTools;

/**
 * ...
 * @author shohei909
 */
class Teplayer {
	public var context(default,null):TeplayContext;
	public var branches(default, null):Map<String,Dynamic>;
	public var extensionSupports:Map<String, String->String>;
	public var outputFilters:Map<String, String->Void>;
	public var outputDir:String;
	public var resourceDir:String;
	public var parameters:Dynamic;
	
	public function new(outputDir:String, resourceDir:String, ?parameters:Dynamic, ?posInfos:PosInfos) {
		this.outputDir = outputDir;
		this.resourceDir = resourceDir;
		this.parameters = parameters;
		
		if (!FileSystem.exists(resourceDir)) {
			warning('sourceDir "$resourceDir" is not found', posInfos);
		}
		
		branches = new Map();
		this.outputFilters = new Map();
		
		extensionSupports = [
			"tplt" => _execute
		];
	}
	
	public function _execute(file:String) {
		return context.executeTemplate(file, []);
	}
	
	public function addBranch(flag:String, branch:Dynamic) {
		if ( Std.is(branch, StringMap) ) branch = TeplayTools.mapToStructure(branch);
		branches[flag] = branch;
	}
	
	public function addExtension(extension:String, convertion:String->String) {
		extensionSupports[extension] = convertion;
	}
	
	public function addOutputFilter(extention:String, filter:String->Void) {
		outputFilters[extention] = filter;
	}
	
	public function addPlugin(plugin: { function apply(r:Teplayer):Void; } ) {
		plugin.apply(this);
	}
	
	public function play(?posInfos:PosInfos) {
		context = new TeplayContext(this);
		
		try {
			context.currentPos = posInfos;
			context.compileAll();
		} catch (e:TeplayError) {
			switch (e) {
				case EXECUTE_ERROR(msg, pos): error(msg, pos);
			}
		}
		
		context = null;
	}
	
	public dynamic function warning (msg:String, pos:PosInfos) {
		if (context != null && context.currentBranchSetting != null) {
			msg += ": at " + Std.string(context.currentBranchSetting);
		}
		
		try {
			Context.warning(msg, TeplayTools.posInfosToPosition(pos));
		} catch (e:Dynamic) {
			Context.warning(msg, Context.currentPos() );
		}
	}
	
	public dynamic function error (msg:String, pos:PosInfos) {
		if (context != null && context.currentBranchSetting != null) {
			msg += ": at " + Std.string(context.currentBranchSetting);
		}
		try {
			Context.error(msg, TeplayTools.posInfosToPosition(pos));
		} catch (e:Dynamic) {
			Context.error(msg, Context.currentPos());
		}
	}
	
	public function throwWarning(msg:String) {
		if (context != null) {
			warning(msg, context.currentPos);
		} else {
			Context.error(msg, Context.currentPos());
		}
	}
	
	public function warningFromFile(coller:String, fileName:String, readError:String->Array<TeplayErrorInfos>) {
		var f = File.read(fileName);
		var data = f.readAll().toString();
		f.close();
		
		Sys.print(data);
		var es = readError(data);
		
		for (e in es) {
			warning(e.msg, e.pos);
		}
		
		throwWarning('$coller : External Error. $data');
	}
	
	public function getArticleList(dir:String) {
		var result = new Map<String, {article : {number:String, file:String}}>();
		
		var files = FileSystem.readDirectory(resourceDir + "/" + dir);
		var ereg = ~/^(([0-9]+)_)?([^\.]+)/;
		
		for (f in files) {
			if (FileSystem.isDirectory(resourceDir + "/" + dir + "/" + f)) {
				continue;
			}
			if (ereg.match(f)) {
				var name = ereg.matched(0);
				var num = ereg.matched(2);
				var title = ereg.matched(3);
				
				result[title] = {
					article : {
						number : num, 
						file : name,
					}
				};
			}
		}
		
		return result;
	}
}