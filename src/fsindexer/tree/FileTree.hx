package fsindexer.tree;

import fsindexer.ds.Stack;
import fsindexer.util.Path;

interface FileTree extends FileStateMapper
{
	public function getRoot():IndexedFile;
	public function getFileMap():Map<String, IndexedFile>;
}

class FileTreeExtension
{
	public static function snapshot(tree:FileTree):FileTreeSnapshot
	{
		return FileTreeSnapshot.fromFileTreeMap(tree.getFileMap());
	}
	
	public static function writeSnapshot(tree:FileTree, snapshotPath:Path):Void
	{
		FileTreeSnapshot.writeSnapshot(tree.getFileMap(), snapshotPath);
	}

	public static function walkFromRoot
	(
		tree:FileTree,
		cf:IndexedFile,
		fileVisitor:(IndexedFile)->Void,
		preDirectoryVisitor:(IndexedFile)->Void,
		postDirectoryVisitor:(IndexedFile)->Void
	):Void
	{
		if(cf.children == null)
			fileVisitor(cf);
		else
		{
			preDirectoryVisitor(cf);
			for(child in cf.children)
				walkFromRoot(tree, child, fileVisitor, preDirectoryVisitor, postDirectoryVisitor);
			postDirectoryVisitor(cf);
		}
	}
	
	public static function walk
	(
		tree:FileTree,
		fileVisitor:(IndexedFile)->Void,
		preDirectoryVisitor:(IndexedFile)->Void,
		postDirectoryVisitor:(IndexedFile)->Void
	):Void
	{
		walkFromRoot(tree, tree.getRoot(), fileVisitor, preDirectoryVisitor, postDirectoryVisitor);
	}
	
	public static function simpleWalkFromRoot(tree:FileTree, cf:IndexedFile, visitor:(IndexedFile)->Void):Void
	{
		visitor(cf);
		if(cf.children != null)
			for(child in cf.children)
				simpleWalkFromRoot(tree, child, visitor);
	}
	
	public static function simpleWalk(tree:FileTree, visitor:(IndexedFile)->Void):Void
	{
		simpleWalkFromRoot(tree, tree.getRoot(), visitor);
	}
}

class FileTreeDepthFirstIterator
{
	var directoryStack = new Stack<IndexedFile>();
	var positionStack = new Stack<Int>();
	var _next:IndexedFile;
	
	public function new(root:IndexedFile)
	{
		_next = root;
	}
	
	@Override
	public function hasNext():Bool
	{
		return _next != null;
	}

	@Override
	public function next():IndexedFile
	{
		var toReturn = _next;
		
		if(_next.children != null && _next.children.length != 0)
		{
			directoryStack.push(_next);
			positionStack.push(0);
		}
		
		_next = null;
		while(_next == null && !directoryStack.isEmpty())
		{
			var parent = directoryStack.peek();
			var childIndex = positionStack.pop();
			if(parent.children.length <= childIndex)
			{
				directoryStack.pop();
			}
			else
			{
				_next = parent.children[childIndex];
				positionStack.push(childIndex + 1);
			}
		}
		
		return toReturn;
	}
}