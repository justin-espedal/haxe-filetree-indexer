package fsindexer.filter;

class PredicatePathFilter implements PathFilter
{
	private final includePattern:(String)->Bool;
	private final _requiresTraversal:Bool;
	
	public function new(includePattern:(String)->Bool, requiresTraversal:Bool)
	{
		this.includePattern = includePattern;
		this._requiresTraversal = requiresTraversal;
	}

	@Override
	public function preVisitDirectory(path:String):PathVisitResult
	{
		return includePattern(path) ? PathVisitResult.INCLUDE : PathVisitResult.EXCLUDE;
	}

	@Override
	public function visitFile(path:String):PathVisitResult
	{
		return includePattern(path) ? PathVisitResult.INCLUDE : PathVisitResult.EXCLUDE;
	}

	@Override
	public function postVisitDirectory(path:String):Void
	{
	}
	
	@Override
	public function requiresTraversal():Bool
	{
		return _requiresTraversal;
	}
}