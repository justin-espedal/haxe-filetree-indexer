package fsindexer.util;

import haxe.crypto.Sha1;
import haxe.io.BytesBuffer;
import sys.io.*;

import fsindexer.tree.IndexedFile;

class HashUtils
{
	public static function hashFileToString(path:Path):String
	{
		//TODO: handle symlinks (don't follow link, just hash the target path)
		return Sha1.make(File.getBytes(path)).toHex();
	}
	
	public static function hashIndexedFolderToString(cf:IndexedFile):String
	{
		var bb = new BytesBuffer();
		
		var relativePathStart = cf.path.length + 1;
		function getEntryName(entry:IndexedFile) return entry.path.substring(relativePathStart);
		
		for(child in cf.getChildren())
		{
			bb.addString(getEntryName(child));
			bb.addString(child.getHash());
		}
		
		return Sha1.make(bb.getBytes()).toHex();
	}
}