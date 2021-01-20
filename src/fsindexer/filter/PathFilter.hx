package fsindexer.filter;

interface PathFilter
{
	/**
	 * Whether this filter requires traversing through the full file tree
	 * in order to determine which files to include.
	 */
	function requiresTraversal():Bool;
	
	/** Determine whether to include or exclude the given directory */
	function preVisitDirectory(path:String):PathVisitResult;
	
	/** Determine whether to include or exclude the given file */
	function visitFile(path:String):PathVisitResult;
	
	function postVisitDirectory(path:String):Void;
}

class PathFilters
{
	public static function fromAntGlob(glob:String):PathFilter
	{
		return PatternFilter.fromAntGlob(AntGlob.fromPattern(glob));
	}
	
	public static function fromPattern(pattern:EReg):PathFilter
	{
		return new PatternFilter(pattern);
	}
	
	public static function fromIncludePredicate(includePattern:(String) -> Bool):PathFilter
	{
		return new PredicatePathFilter(includePattern, true);
	}
	
	public static function fromExcludePredicate(excludePattern:(String) -> Bool):PathFilter
	{
		return new PredicatePathFilter((s) -> !excludePattern(s), false);
	}
	
	public static function none():PathFilter
	{
		return new IncludeAllFilter();
	}
}