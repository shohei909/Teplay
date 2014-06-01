##プラグイン

Teplayのすべての機能を使用するには、以下のRedcarpet、Pygments、Sassをインストールする必要があります。

###Redcarpet
Redcarpetは、Githubでも使用されているマークダウンライブラリです。

####Rubyのインストール
Redcarpetを利用するには、Rubyのインストールが必要です。

[ダウンロード - RubyInstaller for Windows](http://rubyinstaller.org/downloads/)

####DevKitのインストール
RubyのアドオンであるDevKitも必要なので、以下からダウンロードしてください

[ダウンロード - RubyInstaller for Windows](http://rubyinstaller.org/downloads/)

DevKitをダウンロードしたDevKitを展開したら以下のコマンドを入力してください。

```sh
cd　'DevKitを展開したディレクトリ'
ruby dk.rb init
ruby dk.rb install
```

####Redcarpetのインストール
コマンドライン上で以下のコマンドを入力してください。

```sh
gem install redcarpet
```

###Pygments
PygmentsはGithubやQiitaでも使用されている、Pythonで書かれたシンタックスハイライトのライブラリです。Pygmentsの魅力は、なんといっても[対応している言語](http://pygments.org/docs/lexers/)の多さです。JavaScriptやJava、C#、C++のようなメジャーで歴史ある言語だけでなく、Haxeやhxml、TypeScript、Kotlin、Rust、Ceylon、Nemerleなどのような新しい言語についてもサポートをしています。

TeplayのPygmentsのプラグインを使用すると、出力された```.html```ファイルから、```<code class="言語名:タイトル">...</code>```という記述を見つけ出して言語ごとのシンタックスハイライトを適用してくれます。

####Pythonのインストール
以下のページから、Pythonのインストーラをダウンロードできます。

[ダウンロード - Python Japan](http://www.python.jp/download/)

####Pygmentsのインストール
コマンドライン上で以下のコマンドを入力してください。

```
pip install pygments
```

###Sass
Redcarpetと同様に、RubyとDevKitが必要です。RubyとDevKitのインストール後にSassをインストールしてください。

####Sassのインストール
コマンドライン上で以下のコマンドを入力してください。

```sh
gem install sass
```

####FlashDevelopでSCSSを扱う場合の注意
FlashDevelopにはSCSSを保存時に自動でコンパイルする機能がありますが、TeplayでSCSSを扱う場合はこの機能をOFFにしてください。

環境設定 > CssCompletion > Disable Compile to CSS on Save を Trueに設定することでこの機能をOFFにすることができます。

###Teplayで各プラグインを利用する。

```hx:Main.hx
import teplay.Teplayer;
import teplay.plugin.RedcarpetPlugin;
import teplay.plugin.PygmentsPlugin;
import teplay.plugin.SassPlugin;

class Main {
	static function main() {
		var player = new Teplayer("bin", "resource", {});
		
		//各プラグインの追加
		player.addPlugin( new RedcarpetPlugin("Rubyのパス", [/*コマンド引数*/]) );
		player.addPlugin( new PygmentsPlugin("Pythonのパス") );
		player.addPlugin( new SassPlugin("Rubyのパス", [/*コマンド引数*/]) );
		
		//その他の設定...
		
		player.play();
	}
}
```

Rubyのパス、Pythonのパスは"C:\\Ruby193"、"C:\\Python34"のようなパスをインストールしたディレクトリにしたがって渡してください。
