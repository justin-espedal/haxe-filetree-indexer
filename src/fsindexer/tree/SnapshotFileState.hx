package fsindexer.tree;

class SnapshotFileState implements FileState
{
	public var path:String;
	public var hash:String;
	
	public function new(path:String, hash:String)
	{
		this.path = path;
		this.hash = hash;
	}
	
	public static function fromIndexLine(line:String):SnapshotFileState
	{
		var parts = line.split(":");
		if(parts.length < 2)
			return null;
		
		return new SnapshotFileState(parts[0], parts[1]);
	}
	
	public static function fromIndexFile(file:FileState):SnapshotFileState
	{
		return new SnapshotFileState(file.getPath(), file.getHash());
	}
	
	@Override
	public function getPath():String
	{
		return path;
	}
	
	@Override
	public function getHash():String
	{
		return hash;
	}
}
