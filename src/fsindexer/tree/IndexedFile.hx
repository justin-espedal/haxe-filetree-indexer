package fsindexer.tree;

import fsindexer.util.StringComparator;
import haxe.Int64;
import sys.FileStat;

import fsindexer.util.HashUtils;
import fsindexer.util.Path;

@:allow(fsindexer.tree)
class IndexedFile implements FileState
{
	/** Relative path from project root. */
	public final path:String;
	
	/** The parent of the file on the filesystem, as an IndexedFile.<br/>
	 *  This is null for the root. */
	public final parent:IndexedFile;
	
	/** The immediate children of the file on the filesystem, as IndexedFiles.<br/>
	 *  This is null if the file isn't a folder. */
	private var children:Array<IndexedFile>;
	
	/** The time when this file was last modified in the index */
	private var lastModified:Int64;
	
	/** The hash this file has in the index */
	private var lastHash:String;
	
	/** This is false for dummy files that don't actually exist. */
	private var exists:Bool;
	
	//
	
	public function new(path:String, parent:IndexedFile)
	{
		this.path = path;
		this.parent = parent;
	}
	
	public function loadPreviousState(state:IndexedFileState):Void
	{
		if(state != null)
		{
			lastModified = state.lastModified;
			lastHash = state.lastHash;
		}
	}

	/**
	 * Update cached info in index, returning true if updated, false if data was already up-to-date.
	 */
	public function updateIndexCache(fsPath:Path, attrs:FileStat):Bool
	{
		var mtime = Int64.fromFloat(attrs.mtime.getTime());
		//refresh the hash only if needed
		if(lastHash == null || lastModified != mtime)
		{
			lastHash = HashUtils.hashFileToString(fsPath);
			lastModified = mtime;
			return true;
		}
		
		return false;
	}

	/**
	 * Update cached info in index, returning true if updated, false if data was already up-to-date.
	 */
	public function updateGroupIndexCache(force:Bool):Bool
	{
		//refresh the hash only if needed
		if(force || lastHash == null || lastModified != children.length) //"lastModified" tracks number of children for folders
		{
			lastHash = HashUtils.hashIndexedFolderToString(this);
			lastModified = children.length;
			return true;
		}
		
		return false;
	}
	
	//
	
	public static function compare(a:IndexedFile, b:IndexedFile):Int
	{
		//TODO: use natural order comparison
		return StringComparator.compare(a.path, b.path);
	}
	
	@Override
	public function toString():String
	{
		return path;
	}
	
	@Override
	public function getPath():String
	{
		return path;
	}
	
	@Override
	public function getHash():String
	{
		return lastHash;
	}
	
	public function getChildren():Array<IndexedFile>
	{
		return children;
	}
}

class IndexedFileState
{
	public var lastModified:Int64;
	public var lastHash:String;
	
	public function new(lastModified:Int64, lastHash:String)
	{
		this.lastModified = lastModified;
		this.lastHash = lastHash;
	}
	
	public static function readIndexLine(map:Map<String, IndexedFileState>, line:String):Void
	{
		var parts = line.split(":");
		if(parts.length < 3)
			return;
		
		map.set(parts[0], new IndexedFileState(Int64.parseString(parts[1]), parts[2]));
	}
}