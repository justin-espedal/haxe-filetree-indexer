package fsindexer.util;

class ArrayUtils
{
    public static function binarySearch<T>(list:Array<T>, find:T, compare:(a:T, b:T)->Int):Int
    {
        var low = 0;
        var high = list.length - 1;

        while(low <= high)
        {
            var mid = (low + high) >>> 1;
            var midVal = list[mid];
            var compareResult = compare(midVal, find);

            if(compareResult < 0)
            {
                low = mid + 1;
            }
            else if(compareResult > 0)
            {
                high = mid - 1;
            }
            else
            {
                return mid;
            }
        }
        return -(low + 1);
    }
}