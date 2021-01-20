package fsindexer.util;

class StringComparator
{
    //http://old.haxe.org/forum/thread/1841
    public static function compare(s0:String, s1:String):Int
    {
        var cc0, cc1;
        for (i in 0...cast Math.min(s0.length, s1.length))
        {
            cc0 = s0.charCodeAt(i);
            cc1 = s1.charCodeAt(i);
            if (cc0 != cc1) return cc0 - cc1;
        }
        return s0.length - s1.length;
    }
}