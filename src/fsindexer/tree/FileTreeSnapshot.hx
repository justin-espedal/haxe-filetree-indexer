package fsindexer.tree;

import fsindexer.util.Path;

import sys.FileSystem;
import sys.io.File;

class FileTreeSnapshot implements FileStateMapper
{
	private var map:Map<String, SnapshotFileState>;
	
	private function new()
	{
	}
	
	public static function fromFileTreeMap<T:FileState>(fileMap:Map<String, T>):FileTreeSnapshot
	{
		var snapshot = new FileTreeSnapshot();
		snapshot.map = [for(file in fileMap) file.getPath() => SnapshotFileState.fromIndexFile(file)];
		return snapshot;
	}
	
	public static function readFrom(snapshotPath:Path):FileTreeSnapshot
	{
		var snapshot = new FileTreeSnapshot();
		var lines = File.getContent(snapshotPath).split("\n");
		snapshot.map = [];
		for(line in lines)
		{
			var state = SnapshotFileState.fromIndexLine(line);
			snapshot.map.set(state.path, state);
		}
		
		return snapshot;
	}
	
	public static function empty():FileTreeSnapshot
	{
		var snapshot = new FileTreeSnapshot();
		snapshot.map = [];
		return snapshot;
	}
	
	public static function writeSnapshot<T:FileState>(fileMap:Map<String, T>, snapshotPath:Path)
	{
		var sb = new StringBuf();
		
		for(cf in fileMap)
		{
			if(cf.getHash() != null)
			{
				sb.add(cf.getPath());
				sb.add(":");
				sb.add(cf.getHash());
				sb.add("\n");
			}
		}
		
		FileSystem.createDirectory(snapshotPath.getParent());
		File.saveContent(snapshotPath, sb.toString());
	}
	
	@Override
	public function getFileMap():Map<String, SnapshotFileState>
	{
		return map;
	}
	
	public function writeTo(snapshotPath:Path):Void
	{
		var sb = new StringBuf();
		
		for(file in map)
		{
			if(file.hash != null)
			{
				sb.add(file.path);
				sb.add(":");
				sb.add(file.hash);
				sb.add("\n");
			}
		}
		
		FileSystem.createDirectory(snapshotPath.getParent());
		File.saveContent(snapshotPath, sb.toString());
	}
}
