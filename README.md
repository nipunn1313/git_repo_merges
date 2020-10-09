Scripts and tools for merging git repos into each other while
maintaining version history - developed at Dropbox.

Before using, make sure you read and understand the internals of the
script!

Requirements:
Install the wonderful git-filter-repo https://github.com/newren/git-filter-repo

Can be useful in moving toward a mono-repo without some of the common
pain-points. Git slowness can still be an issue in a large monorepo, but
much of it can be mitigated with some of these techniques.

Features:
- Rewriting commit messages to include past commit hashes
- Merging hg repos into git
- Configurable arguments to git filter-repo, including
  - cleaning out large blobs from commit history.
  - deleting unwanted paths / content

Authors:
- @nipunn1313
- @gnprice
