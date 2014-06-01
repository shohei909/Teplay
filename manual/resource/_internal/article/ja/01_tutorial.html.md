## Teplayチュートリアル

このページではTeplayでのWebページ制作の方法を説明していきます。

##Teplayの実行方法

Teplayでは、Haxeのコンパイルを実行することでWebページが生成されます。

###1. サイト生成用のHaxeの記述

サイト生成用のプログラムは、Haxeのコードから呼び出します。srcディレクトリに以下のようなHaxeのコードを配置します。

```hx:BuildMain.hx
import teplay.Teplayer;

class BuildMain {
	static function main() {
		var player = new Teplayer(
			"bin", //サイトの出力先のディレクトリ
			"resource",  //テンプレートなどを配置するディレクトリ
			{ // テンプレートエンジンで使用する変数や関数の指定
            	hello : "Hello",
                world : function() { return "World!!"; },
            }
		);
		
		player.play();
	}
}
```

###2. テンプレートの記述
resourceフォルダにindex.html.tpltという名前のテンプレートを配置します

```html:index.html.tplt
<!DOCTYPE html>
<title>Hello World</title>
%%hello + " " + world()%%
```

この```%%```で囲った部分のコードが、BuildMain.hxで指定した変数と関数を呼び出しています。

###3. hxmlの記述
ビルドの設定ファイルを記述します。

```:build.hxml
-cp src
-lib teplay
-macro BuildMain.main();
```

###4. コンパイルの実行

コンソール上で以下のコマンドを実行します。

```
haxe build.hxml
```

###結果
binフォルダが生成されて、以下のHTMLが作成されます。

```html:index.html
<!DOCTYPE html>
<title>Hello World</title>
Hello World!!
```

##Teplayで利用するファイル

###Teplayテンプレート(.tplt)
Teplay独自のテンプレートファイルのファイル形式です。Haxeに近い文法の繰り返し処理や、条件分岐、関数呼び出しなどを記述することで、メニューやヘッダー、フッターの共通化を実現できます。

詳しくは[テンプレートエンジンのページ](tplt.html)を参照してください。

###マークダウン(.md)
[マークダウン](http://ja.wikipedia.org/wiki/Markdown)は文書を記述するための軽量マークアップ言語です。[Redcarpet](https://github.com/vmg/redcarpet)を利用してHTMLに変換されます。

例えば、

```:sample.html.md
# タイトル
文章。[Googleへのリンク](http://google.com)。**太字**。
```

というファイルが以下に変換されます

```html:sample.html
<h1>タイトル</h1>
<p>文章。<a href="http://google.com">Googleへのリンク</a>。<strong>太字</strong>。</p>
```

Teplayでマークダウンを利用するには、Redcarpetプラグインを有効にする必要があります。

詳しくは、[プラグインのページ](plugin.html)を参照してください。

###Sass(.sass, .scss)
[Sass](http://ja.wikipedia.org/wiki/Sass)はCSS拡張メタ言語です。より豊富な文法を使ってCSSを記述することが可能になります。Teplayでは.sassと.scssの両方のファイル形式が利用可能です。

Sassのファイルはtpltやmdとは異なり、ファイルが出力先フォルダに出力された後に出力フォルダ上でSassによるコンパイルが実行されます。ですから、Sassのファイルから外部のファイルの参照を行う場合は、出力先フォルダのパスを基準にして指定してください。

Teplayで利用するには、Sassプラグインを有効にする必要があります。

##Teplayのファイル変換規則

Teplayはリソースフォルダに配置されたファイルの拡張子に応じてファイルの変換を行って、Webページを出力します

Teplayのファイル変換では、同じファイルに対して複数の変換処理を加えることができます。例えば、sample.html.tplt.mdというファイルを作れば、マークダウンからHTMLの変換が行った後にテンプレートを展開してsample.htmlを生成します。逆に、sample.html.md.tpltであればテンプレートが展開してmdを生成した後にhtmlに変換をします。

##ファイル出力後のタスク

Teplayには、ファイルの出力後に、ファイルの削除を行ったり、追加の変換を行ったりすることができます。

例えば、Sassプラグインは出力されたscssファイルとsassファイルに対してコンパイルを行ってcssファイルを出力していきます。

##特殊なファイルとフォルダ
リソースのファイルやフォルダは、最初の文字の指定によって、特別な挙動をさせることができます。

####\_フォルダ
```_``` から始まるフォルダからは、出力フォルダへのファイル生成がされません

####$フォルダ, $ファイル
```$``` から始まるフォルダとファイルは、条件による分岐を使うことができます。 
例えば、```$lang```フォルダを作った場合、ビルド時に以下のような設定をすることで、英語のフォルダ(en)と日本語のフォルダ(ja)の両方を別々のリソースを利用して出力できます。

```hx:BuildMain.hx
import teplay.Teplayer;

class BuildMain {
	static function main() {
		var player = new Teplayer("bin", "resource");
		
		player.addBranch( 
			"lang", 
			{
				ja : { hello : "こんにちは!!" },
				en : { hello : "Hello!!" },
			}
		);
		
		player.play();
	}
}
```

そして、テンプレートファイルを以下のように記述した場合、

```:$lang/index.txt.tplt
%%branch.lang%%
%%hello%%
```

以下の2つのテキストファイルが出力されます

```:ja/index.txt
ja
こんにちは!!
```

```:en/index.txt
en
Hello!!
```