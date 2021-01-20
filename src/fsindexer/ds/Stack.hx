package fsindexer.ds;

@:forward(push, pop)
abstract Stack<T>(Array<T>) from Array<T> to Array<T>
{
    public function new()
    {
        this = [];
    }

    public function peek():T
    {
        return this.length == 0 ? null : this[this.length - 1];
    }

    public function isEmpty():Bool
    {
        return this.length == 0;
    }

    public function size():Int
    {
        return this.length;
    }

    public function set(i:Int, value:T):Void
    {
        this[i] = value;
    }
}