# filetree-indexer

This library can be used to take a snapshot of the files in a folder at a
specific time, and compare the files later to get a course view of what
files have been added, removed, or changed.

There are two concepts here: The "index", which is used to hash all files
in a tree, and "snapshots", which save the state of the files in the index.

The index is updated every time it's accessed, re-hashing any file which
has been modified since it was last accessed.

Whenever we need to see if the file has changed, we check modification time
to see if the current hash is up to date. Then we can compare the current
hash with the original hash.

## `index` File Structure

Each line is an individual file, with the following format:
`path/to/file:time:hash`

Example (split into multiple lines):

```
engine/lib/hxcpp/hxcpp/bin/Android/libmysql5.so:
1487109988000:
ab30ecc12e7210a1625d5544af87432a22782ae7
```

`path` is the relative path from the git root to the file.
`time` is the modification time associated with hash.
`hash` is the sha-1 of the file content in its state at `time`.

If the file's time changes, hash is updated along with the new time.

## `snapshot` File Structure

Similar to the index file, except we only save the file name and hash:

`path/to/file:hash`

Snapshots may include a subset of the files in the `index` file.
