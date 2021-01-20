package fsindexer.diff;

enum ChangeType
{
	/** The path was added */
	ADDED;
	
	/** The path was removed */
	REMOVED;
	
	/** The content at the path has changed */
	UPDATED;
}