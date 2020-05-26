set -x

# Merges CHILD into PARENT in the subdir $PARENT/SUBDIR
CHILD=child_git_repo
PARENT=main_git_repo
SUBDIR=child_dir
BRANCHES_TO_MERGE="master"  # Space separated list of branches

# Assumes:
#  - $CHILD is a checkout of the child repo in the cwd
#  - $PARENT is a checkout of the parent repo in the cwd
#  - $PARENT has a remote pointing to $CHILD (create with `git remote add child ../$CHILD`)
# - bfg is installed in ./ (see https://rtyley.github.io/bfg-repo-cleaner/)

(
    cd $CHILD

    for BRANCH in $BRANCHES_TO_MERGE; do
        git checkout -f $BRANCH
        git reset --hard origin/$BRANCH
    done

    # Strip out large blobs and update commit messages with new commit-id
    java -jar ../bfg-1.12.3.jar --strip-blobs-bigger-than 512K
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive

    # Update index to prepend $CHILD/
    # http://git-scm.com/docs/git-filter-branch
    # Modified to have a literal tab character in the sed command because:
    #     Note that the only C-like backslash sequences that you can portably
    #     assume to be interpreted are \n and \\; in particular \t is not
    #     portable, and matches a 't' under most implementations of sed, rather
    #     than a tab character.
    git filter-branch -f --index-filter \
        'git ls-files -s | sed "s-	\"*-&$SUBDIR/-" |
            GIT_INDEX_FILE=$GIT_INDEX_FILE.new \
                git update-index --index-info &&
         mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"' -- --all

    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
)

(
    cd $PARENT
    git fetch $CHILD
    ORIG_MASTER=`git rev-parse master`

    for BRANCH in $BRANCHES_TO_MERGE; do
        git checkout -B $BRANCH $ORIG_MASTER  # New branch will have the same name as the original child branch
        git merge -m "Merge $CHILD into $PARENT" $CHILD/${BRANCH}
    done
)
