package ;
import haxe.PosInfos;
import nanotest.NanoTestCase;
import teplay.Teplayer;

/**
 * ...
 * @author shohei909
 */
class TeplayScriptTest extends NanoTestCase{
	public function test() {
		var player = new Teplayer(
			"test/bin/",
			"test/resource/script",
			{
				func : func,
				assertTrue : assertTrue.bind(_),
				assertFalse : assertFalse.bind(_),
				assertEquals : assertEquals.bind(_, _)
			}
		);
		player.play();
	}
	
	public function func(a, b, c) { 
		trace(a, b);
	}
}