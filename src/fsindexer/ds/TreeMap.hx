package fsindexer.ds;

class TreeMap<K, V> extends haxe.ds.BalancedTree<K, V> implements haxe.Constraints.IMap<K, V>
{
    private var comparator:(k1:K, k2:K)->Int;

    public function new(comparator:(k1:K, k2:K)->Int)
    {
        super();
        this.comparator = comparator;
    }

    override function compare(k1:K, k2:K):Int
    {
        return comparator(k1, k2);
    }
}