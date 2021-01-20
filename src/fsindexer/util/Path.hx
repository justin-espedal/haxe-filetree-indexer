package fsindexer.util;

import sys.FileSystem;
import sys.io.File;

using StringTools;

abstract Path(String) from String to String
{
    public function new(s:String)
    {
        this = s;
    }

    public function getParent():Path
    {
        var lastSlash = this.lastIndexOf("/");
        if(lastSlash == -1) return "";
        else return this.substring(0, lastSlash);
    }

    public function toAbsolutePath():Path
    {
        return FileSystem.fullPath(this);
    }

    public function toUnixPath():Path
    {
        return this.replace("\\", "/");
    }

    public function noEndingSeperator():Path
    {
        return this.endsWith("\\") || this.endsWith("/") ?
			this.substring(0, this.length - 1) :
			this;
    }

    public static final ignoredOSFilenames:Map<String,String> = [
		".DS_Store" => "",
		".Trashes" => "",
		"ehthumbs.db" => "",
		"Thumbs.db" => ""
	];
	
	public static function forThisAndAllAncestors(path:Path, accept:(Path)->Void):Void
	{
		accept(path);
		
		var parentFolder = path;
		var lastSlash:Int;
		while((lastSlash = (parentFolder:String).lastIndexOf('/')) != -1)
		{
			parentFolder = (parentFolder:String).substring(0, lastSlash);
			accept(parentFolder);
		}
	}
}