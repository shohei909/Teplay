package ;
import nanotest.NanoTestRunner;
import neko.Lib;

/**
 * ...
 * @author shohei909
 */

class TestMain{
	static public function main() {
		var runner = new NanoTestRunner();
		runner.add(new TeplayScriptTest());
		runner.run();
	}
}