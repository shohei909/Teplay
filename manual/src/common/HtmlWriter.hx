package common;

/**
 * ...
 * @author shohei909
 */
class HtmlWriter {
	
	static public function script( file:String ) {
		return '<script type="text/javascript" src="$file"></script>';
	}
	
	static public function styleSheet( file:String ) {
		return '<link rel="stylesheet" type="text/css" href="$file" />';
	}

	static public function title (title:String, ?subTitle:String) {
		return if (subTitle == null) title else subTitle + " | " + title;
	}
	
	static public function menu(dir:String, currentPage:String, lang:String) {
		var strings = Config.localizedStrings[lang];
		
		function cell(page) {
			var title = Reflect.field(strings, page.page);
			
			if (page.page == currentPage) {
				return '<div class="main_menu_item active">$title</div>';
			} else {
				var link = page.link;
				if (! Config.httpEreg.match(link) ) {
					link = dir + "/" + link;
				}
				return '<div class="main_menu_item"><a href="$link">$title</a></div>';
			}
		}
		
		var cells = [for (page in Config.menu) cell(page)].join("");
		return '<div id="main_menu">$cells</div>';
	}
	
	static public function pageLink(dir:String, lang:String, current:String) {
		var c = -1;
		var pages = [];
		
		for (i in 0...Config.menu.length) {
			var page = Config.menu[i];
			var link = page.link;
			if (page.page == current) c = pages.length;
			
			if (! Config.httpEreg.match(link) ) {
				pages.push(page);
			}
		}
		
		if (c == -1) return "";
		
		var strings = Config.localizedStrings[lang];
		var prev = if (c == 0) {
			strings.firstPage;
		} else {
			var page = pages[c - 1];
			var link = dir + "/" + page.link;
			var title = Reflect.field(strings, page.page);
			'<a href="$link">${strings.prev} $title</a>';
		}
		
		var next = if (c == pages.length - 1) {
			strings.lastPage;
		} else {
			var page = pages[c + 1];
			var link = dir + "/" + page.link;
			var title = Reflect.field(strings, page.page);
			'<a href="$link">${strings.next} $title</a>';
		}
		
		return '<div id="page_link"><div id="prev_link">$prev</div> <div id="next_link">$next</div></div>';
	}
}