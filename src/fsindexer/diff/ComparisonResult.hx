package fsindexer.diff;

class ComparisonResult
{
	public final path:String;
	public final change:ChangeType;
	
	public function new(path:String, change:ChangeType)
	{
		this.path = path;
		this.change = change;
	}
}
