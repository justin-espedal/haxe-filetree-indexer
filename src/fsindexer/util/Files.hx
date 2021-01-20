package fsindexer.util;

import sys.FileSystem;
import sys.FileStat;

//API based on the one from Java's standard library

interface FileVisitor<T>
{
	public function preVisitDirectory(dir:T, attrs:FileStat):FileVisitResult;
	public function postVisitDirectory(dir:T):FileVisitResult;
	public function visitFile(file:T, attrs:FileStat):FileVisitResult;
}

enum FileVisitResult
{
	CONTINUE;
	SKIP_SUBTREE;
}

class Files
{
    public static function walkFileTree(path:Path, visitor:FileVisitor<Path>):Void
    {
        path = path.toUnixPath();
        if(FileSystem.exists(path))
        {
            var result = visitor.preVisitDirectory(path, FileSystem.stat(path));
            if(result == SKIP_SUBTREE) return;
            for(filename in FileSystem.readDirectory(path))
            {
                var filepath = path + "/" + filename;
                if(FileSystem.isDirectory(filepath))
                    walkFileTree(filepath, visitor);
                else
                    visitor.visitFile(filepath, FileSystem.stat(filepath));
            }
            visitor.postVisitDirectory(path);
        }
    }
}