package teplay.core;
import sys.FileSystem;
import sys.io.File;
import teplay.Teplayer;

/**
 * ...
 * @author shohei909
 */
class TeplayBasePlugin
{
	static var temporaryDir 	= "build_temporary";
	public var player:Teplayer;
	
	public function apply(player:Teplayer) {
		if (this.player != null) { 
			throw "This plugin is already added to teplayer.";
		}
		this.player = player;
	}
	
	function execute(cmd:String, args, readError) {
		FileSystem.createDirectory(temporaryDir);
		var error 	= '$temporaryDir/error.txt';
		
		if (Sys.command(cmd, args.concat(['2>$error'])) == 0) {
			remove(temporaryDir);
		} else {
			player.warningFromFile(Type.getClassName(Type.getClass(this)), error, readError);
		}
	}
	
	function executeOnTemporaryDir(cmd:String, setup, ?readError) {
		FileSystem.createDirectory(temporaryDir);
		if (readError == null) readError = function (s:String) { return []; };
		var input 	= '$temporaryDir/input.txt';
		var output 	= '$temporaryDir/output.txt';
		var error 	= '$temporaryDir/error.txt';
		
		var result  = null;
		var args	= setup(input, output);
		
		if (Sys.command(cmd, args.concat(['2>$error'])) == 0) {
			result = read(output);
			remove(temporaryDir);
		} else {
			player.warningFromFile(Type.getClassName(Type.getClass(this)), error, readError);
		}
		
		return result;
	}
	
	function write(output, data) {
		var w = File.write(output);
		w.writeString(data);
		w.flush();
		w.close();
	}
	
	function read(input) {
		var r = File.read(input);
		var data = r.readAll().toString();
		r.close();
		return data;
	}
	
	function remove(file) {
		try {
			if (!FileSystem.exists(file)) return;
			if (FileSystem.isDirectory(file)) {
				for (f in FileSystem.readDirectory(file)) {
					remove(file + "/" + f);
				}
				FileSystem.deleteDirectory(file);
			} else {
				FileSystem.deleteFile(file);
			}
		} catch (d:Dynamic) {
			Sys.print( 'removing $file failed' );
		}
	}
}