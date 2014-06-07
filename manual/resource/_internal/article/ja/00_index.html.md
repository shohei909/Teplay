Teplayは、Haxe製の静的サイトジェネレータです。

Teplayは強力なテンプレートエンジンと、[Redcarpet](https://github.com/vmg/redcarpet)(マークダウン)、[Pygments](http://pygments.org/)(シンタックスハイライト)、[Sass](http://sass-lang.com/)(CSS拡張言語)のプラグインを用意しています。

Teplayでのサイトの制作方法は、以下のとおりです。

* メニューやヘッダー、フッターなどのサイトの枠組みをテンプレートエンジンで記述。
* テキストをMarkdownで記述。
* CSSをSassで記述。
* JavaScriptをHaxeで記述。

そしてTeplayを実行すれば、それらがつなぎ合わさったWebサイトが生成されます。

Teplayを使えば、Webページを作る上でやっかいな多言語化や、メニューやヘッダー、フッターの共通化を簡単に実現できます。

例えば、このページもTeplayによって生成されています。このページがどのようなファイルから生成されているかは、Githubで見ることができます。
<https://github.com/shohei909/teplay/tree/master/manual>

##インストール

###Haxeのインストール
Teplayを始めるにはHaxeのインストールが必要です。Haxeは以下のページからダウンロードしてください。

[ダウンロード - Haxe](http://haxe.org/download)

###Teplayのインストール

Teplayのインストールは非常に簡単です。Haxeのインストール後にコマンドライン上で以下のコマンドを入力してください。

```sh
haxelib install teplay
```

##Teplayプロジェクトを始める

Teplayでのサイト制作では、FlashDevelopなどのHaxeをサポートしている開発環境を使用します。

FlashDevelopを使う場合は、すでにベースプロジェクトが用意してあります。以下にしたがって必要なファイルをインストールすると、実行ボタンを押すだけで簡単にWebサイトが生成可能な環境が整います。

###FlashDevelopのインストール

FlashDevelopは、Haxe, ActionScript3, TypeScript, HTML, CSS, SCSS, Lessなどの入力補完や、シンタックスハイライトをサポートしている統合開発環境です。以下の公式サイトから入手できます。

[FlashDeveleop](http://www.flashdevelop.org/)

インストーラの指示にしたがってインストールをしてください。
	
###FlashDevelop用Teplayプロジェクトのインストール

以下から、最新の.fdzファイルをダウンロードします。

<https://github.com/shohei909/TeplayProject/releases/>

そして、入手したファイルをダブルクリックすることで自動的にFlashDevelopに2つのプロジェクトが追加されます。

* Min - 最低限の設定がされた状態のプロジェクト
* Full - Sassやマークダウンやシンタックスハイライトを利用するための設定がされた状態のプロジェクト

※　Fullのプロジェクトを利用するためには、さらに、redcarpet、pygments、sassのインストールが必要になります。[プラグインのページ](plugin.html)を参考にインストールを行ってください。

###プロジェクトの作成

新規プロジェクトからTeplayのMinプロジェクトを選択します。

プロジェクトが作成されたら、実行ボタンを押してみましょう。HTML, CSS, JavaScriptからなる、Webページが生成されるはずです。


###FlashDevelopの以外の環境で開発する

Teplayは、IntelliJ IDEAなど、FlashDevelopの以外のIDEでも開発が可能です。その場合、以下からhxmlベースのプロジェクトをダウンロードして利用してください。

<https://github.com/shohei909/TeplayProject/releases/>