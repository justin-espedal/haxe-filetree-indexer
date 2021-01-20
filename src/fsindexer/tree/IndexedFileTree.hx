package fsindexer.tree;

import haxe.Int64;
import sys.*;
import sys.io.*;

import fsindexer.ds.Stack;
import fsindexer.filter.PathFilter;
import fsindexer.filter.PathVisitResult;
import fsindexer.tree.IndexedFile.IndexedFileState;
import fsindexer.util.ArrayUtils;
import fsindexer.util.Files;
import fsindexer.util.Path;

using fsindexer.tree.FileTree.FileTreeExtension;
using StringTools;

class IndexedFileTree implements FileTree
{
	//relativization
	private final relativePathStart:Int;
	
	/** The root path of this tree */
	private final rootPath:Path;
	
	/** The filter used in determining which files to include in the tree */
	private final filter:PathFilter;
	
	/** The file holding cached timestamps and hashes for efficient monitoring of changes */
	private final indexFile:Path;
	
	private var fileMap:Map<String, IndexedFile> = [];
	private var root:IndexedFile;
	private var version:Int = 0;
	
	private function new(rootPath:Path, indexFile:Path, filter:PathFilter)
	{
		this.rootPath = rootPath.toAbsolutePath().toUnixPath();
		this.indexFile = indexFile;
		this.filter = filter;
		
		relativePathStart = (rootPath:String).length + 1;
		
		var index:Map<String, IndexedFileState> = readIndex();
		
		var fileVisitor:CacheBuildingFileVisitor = new CacheBuildingFileVisitor(this, filter, index);
		Files.walkFileTree(rootPath, fileVisitor);
		
		++version;
		this.root = fileMap.get("");
		
		if(fileVisitor.refreshedFiles)
		{
			writeIndex();
		}
	}
	
	public static function load(rootPath:Path, indexFile:Path):IndexedFileTree
	{
		return new IndexedFileTree(rootPath, indexFile, PathFilters.none());
	}
	
	public static function loadWithFilter(rootPath:Path, indexFile:Path, filter:PathFilter):IndexedFileTree
	{
		return new IndexedFileTree(rootPath, indexFile, filter);
	}
	
	@Override
	public function getRoot():IndexedFile
	{
		return root;
	}
	
	/**
	 * <p>Get the relative path to the given Path object, from {@link #rootFile}.</p>
	 * 
	 * <p>This is faster than using {@link Path#relativize(Path)}, but assumes only actual
	 * descendants will be passed to this method.</p>
	 */
	private function relativize(path:Path):String
	{
		if((path:String).length < relativePathStart)
			return "";
		return (path:String).substr(relativePathStart);
	}
	
	/**
	 * Returns a map (filepath -> attributes), read from an index file of the following format:<br/><br/>
	 * filePath:fileModificationTime:lastHash
	 */
	private function readIndex():Map<String, IndexedFileState>
	{
		if(!FileSystem.exists(indexFile))
			File.saveContent(indexFile, "");
		
		var lines = File.getContent(indexFile).split("\n");
		var index:Map<String, IndexedFileState> = [];
		for(line in lines)
		{
			IndexedFileState.readIndexLine(index, line);
		}
		
		return index;
	}
	
	private function writeIndex():Void
	{
		var sb = new StringBuf();
		
		this.simpleWalkFromRoot(root, cf -> {
			if(cf.lastHash != null)
			{
				sb.add(cf.path);
				sb.add(":");
				sb.add(Int64.toStr(cf.lastModified));
				sb.add(":");
				sb.add(cf.lastHash);
				sb.add("\n");
			}
		});
		
		File.saveContent(indexFile, sb.toString());
	}
	
	@Override
	public function getFileMap():Map<String, IndexedFile>
	{
		return fileMap;
	}
	
	public function get(path:String):IndexedFile
	{
		return fileMap.get(path);
	}
	
	public function computeIfAbsent(path:String):IndexedFile
	{
		var cf = fileMap.get(path);
		if(cf == null) {
			cf = createDummy(path);
			fileMap.set(path, cf);
		}
		return cf;
	}
	
	/**
	 * <p>Creates a representation of an IndexedFile that no longer exists on the filesystem.</p>
	 * 
	 * <p>This can be useful if you want to walk over the tree, including files that don't
	 * exist.</p>
	 */
	private function createDummy(filepath:String):IndexedFile
	{
		var parent:IndexedFile = null;
		
		if(filepath.contains("/"))
		{
			filepath = filepath.substring(0, filepath.lastIndexOf("/"));
			parent = fileMap.get(filepath);
			if(parent == null) parent = createDummy(filepath);
		}
		else
		{
			parent = root;
		}
		
		var cf:IndexedFile = new IndexedFile(filepath, parent);
		
		if(parent.children == null)
		{
			parent.children = [];
			parent.children.push(cf);
		}
		else
		{
			var insertAt:Int = ArrayUtils.binarySearch(parent.children, cf, IndexedFile.compare);
			if(insertAt < 0)
				parent.children.insert(-(insertAt+1), cf);
		}
		
		return cf;
	}
	
	public function rescan():Void
	{
		var cachedFileMap:Map<String, IndexedFile> = fileMap;
		fileMap = [];
		
		var index = readIndex();
		var fileVisitor = new CacheBuildingFileVisitor(this, filter, index);
		Files.walkFileTree(rootPath, fileVisitor);
		
		if(fileVisitor.refreshedFiles)
		{
			++version;
			this.root = fileMap.get("");
			writeIndex();
		}
		else
		{
			fileMap = cachedFileMap;
		}
	}
	
	@:allow(fsindexer.tree)
	private function getVersion():Int
	{
		return version;
	}
	
	public function subTree(?subTreeRoot:String = "", ?filter:PathFilter):IndexedFileSubTree
	{
		if(filter == null) filter = PathFilters.none();
		return new IndexedFileSubTree(this, subTreeRoot, filter);
	}
}


@:allow(fsindexer.tree.IndexedFileTree)
@:access(fsindexer.tree.IndexedFileTree)
class CacheBuildingFileVisitor implements FileVisitor<Path>
{
	var tree:IndexedFileTree;
	var filter:PathFilter;
	var stack = new Stack<IndexedFile>();
	var refreshStack = new Stack<Bool>();
	var index:Map<String, IndexedFileState>;
	var refreshedFiles:Bool;
	
	public function new(tree:IndexedFileTree, filter:PathFilter, index:Map<String, IndexedFileState>)
	{
		this.tree = tree;
		this.filter = filter;
		this.index = index;
	}
	
	private function initDirectory(cf:IndexedFile):Void
	{
		if(cf.parent != null)
		{
			if(cf.parent.children == null)
				initDirectory(cf.parent);
			cf.parent.children.push(cf);
		}
		
		cf.loadPreviousState(index.get(cf.path));
		cf.children = [];
		tree.fileMap.set(cf.path, cf);
	}

	@Override
	public function preVisitDirectory(dir:Path, attrs:FileStat):FileVisitResult
	{
		var relativePath = tree.relativize(dir);
		
		var knownInclusion = filter.preVisitDirectory(relativePath) == PathVisitResult.INCLUDE;
		
		if(!knownInclusion && !filter.requiresTraversal())
		{
			return FileVisitResult.SKIP_SUBTREE;
		}
		
		var cf = new IndexedFile(relativePath, stack.isEmpty() ? null : stack.peek());
		cf.exists = true;
		if(knownInclusion)
		{
			initDirectory(cf);
		}
		stack.push(cf);
		refreshStack.push(false);
		return FileVisitResult.CONTINUE;
	}

	@Override
	public function visitFile(file:Path, attrs:FileStat):FileVisitResult
	{
		var relativePath = tree.relativize(file);
		
		if(filter.visitFile(relativePath) == PathVisitResult.INCLUDE)
		{
			var cf = new IndexedFile(relativePath, stack.peek());
			cf.exists = true;
			cf.loadPreviousState(index.get(relativePath));
			if(cf.updateIndexCache(file, attrs) && !refreshStack.peek())
				refreshStack.set(refreshStack.size() - 1, true);
			if(cf.parent.children == null)
				initDirectory(cf.parent);
			cf.parent.children.push(cf);
			tree.fileMap.set(relativePath, cf);
		}
		
		return FileVisitResult.CONTINUE;
	}

	@Override
	public function postVisitDirectory(dir:Path):FileVisitResult
	{
		var cf = stack.pop();
		var refreshed = refreshStack.pop();
		if(cf.children != null)
		{
			filter.postVisitDirectory(cf.path);
			cf.children.sort(IndexedFile.compare);
			refreshed = cf.updateGroupIndexCache(refreshed) || refreshed;
		}
		if(refreshStack.isEmpty())
			refreshedFiles = refreshed;
		else if(!refreshStack.peek())
			refreshStack.set(refreshStack.size() - 1, refreshed);
		
		return FileVisitResult.CONTINUE;
	}
}