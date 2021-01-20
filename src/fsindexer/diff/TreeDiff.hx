package fsindexer.diff;

import fsindexer.util.StringComparator;
import fsindexer.ds.TreeMap;
import fsindexer.tree.FileStateMapper;

class TreeDiff
{
	public final results:TreeMap<String, ComparisonResult>;
	
	private function new(results:TreeMap<String, ComparisonResult>)
	{
		this.results = results;
	}
	
	public static function compare(leftTree:FileStateMapper, rightTree:FileStateMapper):TreeDiff
	{
		var results = new TreeMap<String, ComparisonResult>(StringComparator.compare);
		
		var leftFiles = leftTree.getFileMap();
		var rightFiles = rightTree.getFileMap();
		
		var mergedPaths:Map<String,String> = [];
		for(path in leftFiles.keys()) mergedPaths.set(path, "");
		for(path in rightFiles.keys()) mergedPaths.set(path, "");
		
		for(path in mergedPaths)
		{
			var left = leftFiles.get(path);
			var right = rightFiles.get(path);
			
			if(left == null)
				results.set(path, new ComparisonResult(path, ChangeType.ADDED));
			else if(right == null)
				results.set(path, new ComparisonResult(path, ChangeType.REMOVED));
			else if(left.getHash() != null && right.getHash() != null && left.getHash() != right.getHash())
				results.set(path, new ComparisonResult(path, ChangeType.UPDATED));
		}
		
		return new TreeDiff(results);
	}
}
