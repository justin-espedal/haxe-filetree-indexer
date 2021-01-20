package fsindexer.tree;

import fsindexer.ds.Stack;
import fsindexer.filter.PathFilter;
import fsindexer.filter.PathVisitResult;

class IndexedFileSubTree implements FileTree
{
	private final tree:IndexedFileTree;
	private final filter:PathFilter;
	
	private var version:Int;
	
	private final rootPath:String;
	private var fileMap:Map<String, IndexedFile> = [];
	private var root:IndexedFile;
	
	@:allow(fsindexer.tree.IndexedFileTree)
	function new(tree:IndexedFileTree, rootPath:String, filter:PathFilter)
	{
		this.tree = tree;
		this.rootPath = rootPath;
		this.filter = filter == null ? PathFilters.none() : filter;
	}
	
	@Override
	public function getRoot():IndexedFile
	{
		buildTree();
		return root;
	}
	
	@Override
	public function getFileMap():Map<String, IndexedFile>
	{
		buildTree();
		return fileMap;
	}
	
	/*
	 * SUB TREE BUILDING
	 */
	
	private function buildTree():Void
	{
		if(version != tree.getVersion())
		{
			var stack = new Stack<IndexedFile>();
			
			root = tree.get(rootPath);
			
			fileMap = [];
			if(root == null)
			{
				//nothing
			}
			else if(root.children == null)
			{
				buildVisitFile(stack, root);
			}
			else
			{
				buildVisitDirectory(stack, root);
			}
			
			root = fileMap.get(rootPath);
			version = tree.getVersion();
		}
	}
	
	private function buildInitDirectory(cf:IndexedFile):Void
	{
		if(cf.parent != null)
		{
			if(cf.parent.children == null)
				buildInitDirectory(cf.parent);
			cf.parent.children.push(cf);
		}
		
		cf.children = [];
		fileMap.set(cf.path, cf);
	}

	private function buildVisitDirectory(stack:Stack<IndexedFile>, file:IndexedFile):Void
	{
		var knownInclusion = filter.preVisitDirectory(file.path) == PathVisitResult.INCLUDE;
		
		if(!knownInclusion && !filter.requiresTraversal())
		{
			return;
		}
		
		var cf = new IndexedFile(file.path, stack.isEmpty() ? null : stack.peek());
		cf.exists = true;
		cf.lastHash = file.lastHash;
		cf.lastModified = file.lastModified;
		if(knownInclusion)
		{
			buildInitDirectory(cf);
		}
		stack.push(cf);
		
		for(child in file.children)
		{
			if(child.children == null)
				buildVisitFile(stack, child);
			else
				buildVisitDirectory(stack, child);
		}
		
		filter.postVisitDirectory(stack.peek().path);
		
		if(cf.children != null)
		{
			cf.children.sort(IndexedFile.compare);
			cf.updateGroupIndexCache(true);
		}
	}

	private function buildVisitFile(stack:Stack<IndexedFile>, file:IndexedFile):Void
	{
		if(filter.visitFile(file.path) == PathVisitResult.INCLUDE)
		{
			var cf = new IndexedFile(file.path, stack.isEmpty() ? null : stack.peek());
			cf.exists = true;
			cf.lastHash = file.lastHash;
			cf.lastModified = file.lastModified;
			if(cf.parent != null)
			{
				if(cf.parent.children == null)
					buildInitDirectory(cf.parent);
				cf.parent.children.push(cf);
			}
			fileMap.set(cf.path, cf);
		}
	}
}
