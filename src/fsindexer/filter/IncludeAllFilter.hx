package fsindexer.filter;

class IncludeAllFilter implements PathFilter
{
	public function new()
	{
		
	}
	
	@Override
	public function preVisitDirectory(path:String):PathVisitResult
	{
		return PathVisitResult.INCLUDE;
	}

	@Override
	public function visitFile(path:String):PathVisitResult
	{
		return PathVisitResult.INCLUDE;
	}

	@Override
	public function postVisitDirectory(path:String):Void
	{
	}
	
	@Override
	public function requiresTraversal():Bool
	{
		return false;
	}
}
