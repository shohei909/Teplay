package teplay.core;

import haxe.PosInfos;
import haxe.xml.Check.Filter;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;
import teplay.Teplayer;
using Lambda;

class TeplayContext {
	public var player:Teplayer;
	public var mainTargets:Array<String>;
	public var outputNames:Array<String>;
	public var relation:Map<String,TargetRelation>;
	public var results:Map<String,String>;
	
	public var currentBranchSetting(default, null):Dynamic;
	public var currentBranch(default, null):Array<Dynamic>;
	public var currentTarget(default, null):String;
	public var currentInputFile(default, null):String;
	public var currentPos:PosInfos;
	
	public var compiledFiles:Map<String,Bool>;
	private var targetNum:Int;
	private var branchNames:Array<String>;
	
	static public var callInfos(default,null):Array<TeplayCallInfo> = [];
	
	public function new(runner:Teplayer) {
		this.player = runner;
		branchNames = [for (k in runner.branches.keys()) k];
	}
	
	public function executeTemplate(string:String, params:Array<Dynamic>) {
		var tpl = new TeplayTemplate(string, this);
		tpl.filePath = player.resourceDir + "/" + currentInputFile;
		callInfos.push( { tpl : tpl, file:currentInputFile } );
		var arr:Array<Dynamic> = null;
		var result = tpl.execute(
			arr = ([
				{
					include 	: include,
					execute 	: execute.bind(_, _, params),
					relative 	: relative,
					print		: tpl.add,
					branch 		: currentBranchSetting,
				},
				player.parameters,
			] : Array<Dynamic>).concat(
				currentBranch
			).concat(params)
		);
		
		callInfos.pop();
		return result;
	}
	
	public function execute(name:String, params:Dynamic, oldParams:Array<Dynamic>) {
		return executeTemplate(include(name), oldParams.concat([params]));
	}
	
	public function compileAll() {
		#if bench
		var t = Sys.cpuTime();
		#end
		
		setupTargets();
		compiledFiles = new Map();
		outputNames = [];
		
		for (name in mainTargets) {
			compileTarget(name);
		}
		
		#if bench
		var t2 = Sys.cpuTime();
		trace( 'time : ${t2 - t}');
		t = t2;
		#end
		
		for (name in outputNames) {
			var segs 	= name.split("/");
			var names 	= segs.pop().split(".");
			var ext 	= names.pop();
			var filter 	= player.outputFilters[ext];
			var file	= player.outputDir + "/" + name;
			
			if (filter != null) {
				filter(file);
			}
		}
		
		#if bench
		t2 = Sys.cpuTime();
		trace( 'time : ${t2 - t}');
		t = t2;
		#end
	}
	
	public function include(name:String) {
		var result = results[name];
		if (result != null) return result;
		var rel = relation[name];
		
		if (rel == null) {
			player.throwWarning('file "$name" is not found');
			return "";
		}
		
		switch (rel) {
			case NOTHING :
				var path = FileSystem.fullPath(player.resourceDir + "/" + name);
				var r = File.read(path, true);
				result = r.readAll().toString();
				r.close();
				
			case DEPEND(type, parent) :
				var parentResult = include(parent);
				var func = player.extensionSupports[type];
				var pos = currentPos;
				
				currentPos = new TeplayPosInfos(player.resourceDir + "/" + parent, null, 0, 0); 
				currentInputFile = parent;
				try {
					result = func(parentResult);
				} catch (e:TeplayError) {
					switch (e) {
						case EXECUTE_ERROR(msg, pos): 
							player.warning(msg, pos);
					}
					
					throw TeplayError.EXECUTE_ERROR("Called from here", pos);
				}
				currentPos = pos;
				
				currentInputFile = null;
		}
		
		return results[name] = result;
	}
	
	
	function compileTarget(name:String) {
		var fileSegs = name.split("/");
		var branchNames:Array<String> = [];
		var branchSettings = [{}];
		
		for (i in 0...fileSegs.length) {
			var s = fileSegs[i];
			if (s.indexOf("$") == 0) {
				var key = s.split(".")[0].substr(1);
				var b = player.branches[key];
				if (b == null) {
					var path = FileSystem.fullPath(player.resourceDir + "/" + parentPath(name));
					throw TeplayError.EXECUTE_ERROR('branch for "$$$key" directory is required', new TeplayPosInfos(path, 0, 0, 0));
				}else if (branchNames.has(key)) {
					var path = FileSystem.fullPath(player.resourceDir + "/" + parentPath(name));
					throw TeplayError.EXECUTE_ERROR('"$$$key" directory is duplicated', new TeplayPosInfos(path, 0, 0, 0) );
				}
				
				branchNames.push(key);
				var nextSettings = [];
				for (s in branchSettings) {
					for (bk in Reflect.fields(b)) {
						var map = {};
						for (sk in Reflect.fields(s)) {
							Reflect.setField(map, sk, Reflect.field(s, sk));
						}
						Reflect.setField(map, key, bk);
						nextSettings.push(map);
					}
				}
				
				branchSettings = nextSettings;
			}
		}
		
		for (b in branchSettings) {
			var outputName = "/" + name;
			for (key in Reflect.fields(b)) {
				outputName = StringTools.replace(outputName, "/$" + key, "/" + Reflect.field(b, key));
			}
			
			outputName = outputName.substr(1);
			currentTarget = outputName;
			results = new Map();
			
			var result = includeWithBranch(name, b);
			output(outputName, b, result);
			outputNames.push(outputName);
			
			currentBranchSetting = null;
			currentBranch = null;
			currentTarget = null;
		}
	}
	
	
	
	function output(name:String, b:Dynamic , result:String) {
		
		if (compiledFiles[name] == true) {
			throw TeplayError.EXECUTE_ERROR('output file "$name" is duplicated', currentPos);
		}
		compiledFiles[name] = true;
		
		var segs = name.split("/");
		var file = FileSystem.fullPath(player.outputDir);
		
		for (seg in segs) {
			var child = file + "/" + seg;
			if (!FileSystem.exists(file)) {
				FileSystem.createDirectory(file);
			} else if (!FileSystem.isDirectory(file)) {
				throw TeplayError.EXECUTE_ERROR('"$file" should be directory', currentPos);
			} 
			file = child;
		}
		
		if (FileSystem.exists(file)) {
			if (FileSystem.isDirectory(file)) {
				throw TeplayError.EXECUTE_ERROR('"$file" is already exist', currentPos);
			}
		}
		
		var w:FileOutput = File.write(file, true);
		w.writeString(result);
		w.flush();
		w.close();
	}
	
	function includeWithBranch(name:String, branch:Dynamic) {
		currentBranchSetting = branch;
		currentBranch = [];
		
		for (key in Reflect.fields(branch)) {
			var bk = Reflect.field(branch, key);
			var data = Reflect.field(player.branches[key], bk);
			currentBranch.push(data);
		}
		
		var result = include(name);
		return result;
	}
	
	function parentPath(path:String) {
		var re = relation[path];
		return switch (re) {
			case NOTHING 		: path;
			case DEPEND(_, p) 	: parentPath(p);
		}
	}
	
	
	function setupTargets() {
		relation = new Map();
		mainTargets = [];
		
		var isInSub:Bool = false;
		var sourceDir = FileSystem.fullPath(player.resourceDir);
		
		function readDir(dir:String) {
			var dirPath = FileSystem.fullPath(sourceDir + "/" + dir);
			var isSub = false;
			
			if (!isInSub) {
				isSub = dir.substr(0, 1) == "_";
				if (isSub) isInSub = true;
			}
			
			for (file in FileSystem.readDirectory(dirPath)) {
				var next = if (dir != "") dir + "/" + file else file;
				
				if (FileSystem.isDirectory(sourceDir + "/" + next)) {
					readDir(next);
				} else {
					var result = addToRelation(next);
					
					if (!isInSub) {
						mainTargets.push(result);
					}
				}
			}
			
			if (isSub) isInSub = false;
		}
		
		readDir("");
	}
	
	
	function addToRelation(path:String) {
		relation[path] = NOTHING;
		var arr = path.split("/");
		var file = arr.pop();
		var dir = arr.join("/");
		var seg = file.split(".");
		
		while (true) {
			if (seg.length <= 1) break;
			var ext = seg.pop();
			var support = player.extensionSupports[ext];
			
			if (support != null) {
				var r = DEPEND(ext, path);
				path = dir + "/" + seg.join(".");
				if (relation[path] != null) throw 'file "$path" is duplicated';
				relation[path] = r;
			} else {
				break;
			}
		}
		
		return path;
	}
	
	public function relative(path:String) {
		function isNotEmpty (str) { return !(str == ""); }
		var currentSegs = currentTarget.split("/").filter(isNotEmpty);
		var segs = path.split("/").filter(isNotEmpty);
		
		currentSegs.pop();
		var name = segs.pop();
		var sameCount = 0;
		if (name == null) name = "";
		
		for (i in 0...currentSegs.length) {
			if (segs[i] == currentSegs[i]) {
				sameCount++;
			} else {
				break;
			}
		}
		var dir = "";
		for (i in sameCount...currentSegs.length) {
			dir += "../";
		}
		for (i in sameCount...segs.length) {
			dir += segs[i] + "/";
		}
		return dir + name;
	}
	
	public function warning (msg, pos) {
		player.warning(msg, pos);
	}
}

private enum TargetRelation{
	NOTHING;
	DEPEND(type:String, path:String);
}


typedef TeplayCallInfo = {
	tpl : TeplayTemplate,
	file : String,
}