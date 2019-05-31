WORK IN PROGRESS

Print a NUL-separated list of versioned files, or directories ordered from the
most to the least recently changed.

E.g.:
```
# Print files under the current directory and below ordered by the recency of changes.
% git-newest.sh

# Print directories under tests/ and below ordered by the recency of changes to the files in them.
% git-newest.sh -d tests

# Print directories directly under foo/bar/ matching the *-tests pattern ordered
# by the recency of changes to the files in them and their subdirectories.
% git-newest.sh -d --max-depth 3 foo/bar/*-tests

# Replace NULs with newlines.
% git-newest.sh ...|tr '\0' '\n'
```

The original purpose of this script was to optimize the order of long-running
sequential tests.

Tests that have changed recently are the most likely to fail and should be run
first, so that if they fail, they fail as fast, as possible.

The script has to be run from a git checkout and only uses the author dates
(%at) from git.
