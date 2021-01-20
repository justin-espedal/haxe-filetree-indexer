package fsindexer.filter;

class PatternFilter implements PathFilter
{
	private final pattern:EReg;
//	private final requiresTraversal:Bool;
	
	public function new(pattern:EReg)
	{
		this.pattern = pattern;
	}

	public static function fromAntGlob(glob:AntGlob):PatternFilter
	{
		return new PatternFilter(glob.getPattern());
//		requiresTraversal = glob.getGlob().contains("**");
	}

	@Override
	public function preVisitDirectory(path:String):PathVisitResult
	{
		return pattern.match(path) ? PathVisitResult.INCLUDE : PathVisitResult.EXCLUDE;
	}

	@Override
	public function visitFile(path:String):PathVisitResult
	{
		return pattern.match(path) ? PathVisitResult.INCLUDE : PathVisitResult.EXCLUDE;
	}

	@Override
	public function postVisitDirectory(path:String):Void
	{
	}

	@Override
	public function requiresTraversal():Bool
	{
		return true;
	}
}
