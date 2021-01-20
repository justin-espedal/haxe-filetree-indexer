package fsindexer.filter;

using StringTools;

//https://github.com/bndtools/bnd/blob/master/LICENSE (Apache-2.0 OR EPL-2.0)
//https://github.com/bndtools/bnd/blob/master/aQute.libg/src/aQute/libg/glob/AntGlob.java
class AntGlob
{
	public static final ALL:AntGlob = fromPattern("**");

	private final glob:String;
	private final pattern:EReg;
	
	public static function fromPattern(globString:String):AntGlob
	{
		return fromPatternWithFlag(globString, "");
	}

	public static function fromPatternWithFlag(globString:String, flags:String):AntGlob
	{
		return new AntGlob(globString, toPatternWithFlag(globString, flags));
	}

	function new(globString:String, pattern:EReg)
	{
		this.glob = globString;
		this.pattern = pattern;
	}

	public function getGlob():String
	{
		return glob;
	}

	public function getPattern():EReg
	{
		return pattern;
	}

	public static function toPattern(line:String):EReg
	{
		return toPatternWithFlag(line, "");
	}

	public static function toPatternWithFlag(line:String, flags:String):EReg {
		line = line.trim();
		var strLen = line.length;
		var sb = new StringBuf();
		var i = 0;
		while(i < strLen) {
			var currentChar = line.charCodeAt(i);
			switch (currentChar) {
				case '*'.code :
					var j:Int, k:Int;
					if (i == 0 && //
						((j = i + 1) < strLen && line.charCodeAt(j) == '*'.code) && //
						((k = j + 1) == strLen || line.charCodeAt(k) == '/'.code)) {
						if (k < strLen) { // line starts with "**/"
							sb.add("(?:.*/|)");
							i = k;
						} else {
							sb.add(".*");
							i = j;
						}
					} else {
						sb.add("[^/]*");
					}
				case '?'.code :
					sb.add("[^/]");
				case '/'.code, '\\'.code :
					if (i + 1 == strLen) {
						// ending with "/" is shorthand for ending with "/**"
						sb.add("(?:/.*|)");
					} else {
						if(i + 3 <= strLen &&
							(line.charCodeAt(i + 1) == '*'.code) &&
							(line.charCodeAt(i + 2) == '*'.code) &&
							(i + 3 == strLen || line.charCodeAt(i + 3) == '/'.code)) {
								sb.add("(?:/.*|)");
								i += 2;
						} else {
							sb.add("/");
						}
					}
				case '.'.code, '('.code, ')'.code, '['.code, ']'.code, '{'.code, '}'.code, '+'.code, '|'.code, '^'.code, '$'.code :
					sb.add('\\');
					sb.add(currentChar);
				default :
					sb.add(currentChar);
			}
			++i;
		}
		return new EReg(sb.toString(), flags);
	}
}