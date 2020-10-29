#!/bin/bash
set -euo pipefail

set -ex

# CONFIGURATION VARIABLES
#  - caller should set these variables
#   - these are the defaults
# Merges CHILD into PARENT in the subdir $PARENT/SUBDIR
: ${CHILD:=please_set_the_CHILD_env_variable}
: ${PARENT:=please_set_the_PARENT_env_variable}
: ${SUBDIR:=please_set_the_SUBDIR_env_variable}
: ${BRANCHES_TO_MERGE:="master"}  # Space separated list of branches. Should include master explicitly.
: ${REFS_PREFIX:="$SUBDIR/"}  # What to prefix branch/tag names with. Default to $SUBDIR/
: ${FILTER_REPO_ARGS}

# PreReqs
#
# Clone https://github.com/nipunn1313/git_repo_merges as a sibling repo
# Clone $CHILD and $PARENT as sibling repos
# Install git-filter-repo https://github.com/newren/git-filter-repo
#
# Must manually run from within the $PARENT - once
# > git remote add "${CHILD}" ../"${CHILD}"

# Assumes:
#  - $CHILD is a checkout of the child repo in the cwd
#  - $PARENT is a checkout of the parent repo in the cwd
#  - $PARENT has a remote pointing to $CHILD (create with `git remote add child ../$CHILD`)

this_file="${BASH_SOURCE[0]}"
script_dir=`realpath "${this_file%/*}"`

# Make sure that the child is set as a remote
echo "Verify that $PARENT has $CHILD set as a remote"
git -C $PARENT remote get-url $CHILD

echo "Verifying working directories are clean"
git -C $PARENT diff --quiet --exit-code
git -C $CHILD diff --quiet --exit-code

(
    cd $CHILD

    for BRANCH in $BRANCHES_TO_MERGE; do
        git checkout -f $BRANCH
        git reset --hard origin/$BRANCH || git reset --hard $BRANCH
    done

    # Eval so that $FILTER_REPO_ARGS can escape strings w/ spaces
    eval git filter-repo \
        $FILTER_REPO_ARGS \
        --to-subdirectory-filter $SUBDIR \
        --commit-callback "'"'
            commit.message = commit.message + b"\nOriginal '$CHILD' Repo Git Commit: " + commit.original_id
        '"'"
        --refname-callback "'"'
            parts = refname.split(b\"/\") ;
            return b\"/\".join(parts[0:2] + [b\"'$REFS_PREFIX'\" + parts[2]] + parts[3:])
        '"'"

    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
)

(
    cd $PARENT
    git fetch $CHILD
    ORIG_MASTER=`git rev-parse master`

    for BRANCH in $BRANCHES_TO_MERGE; do
        git checkout -B ${REFS_PREFIX}$BRANCH $ORIG_MASTER  # New branch will have the same name as the original child branch
        git merge --allow-unrelated-histories \
          -m "Merge $CHILD into $PARENT" $CHILD/${REFS_PREFIX}${BRANCH}
    done
)
