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
: ${FILTER_REPO_ARGS}

# PreReqs
#
# Clone https://github.com/nipunn1313/git_repo_merges as a sibling repo
# Clone $CHILD and $PARENT as sibling repos
# Install git-filter-repo https://github.com/newren/git-filter-repo
#   this script will require https://github.com/newren/git-filter-repo/pull/162
#
# Must manually run from within the $PARENT - once
# > git remote add "${CHILD}" ../"${CHILD}"

# Assumes:
#  - $CHILD is a checkout of the child repo in the cwd
#  - $PARENT is a checkout of the parent repo in the cwd
#  - $PARENT has a remote pointing to $CHILD (create with `git remote add child ../$CHILD`)

this_file="${BASH_SOURCE[0]}"
script_dir=`realpath "${this_file%/*}"`

(
    cd $CHILD

    for BRANCH in $BRANCHES_TO_MERGE; do
        git checkout -f $BRANCH
        git reset --hard origin/$BRANCH || git reset --hard $BRANCH
    done

    git filter-repo \
        $FILTER_REPO_ARGS \
        --to-subdirectory-filter $SUBDIR \
        --message-callback '
assert os.environ.get("GIT_COMMIT") is not None
return message + "\nOriginal '$CHILD' Repo Git Commit: {}".format(os.environ.get("GIT_COMMIT")).encode("utf-8")
'

    git reflog expire --expire=now --all
    git gc --prune=now --aggressive
)

(
    cd $PARENT
    git fetch $CHILD
    ORIG_MASTER=`git rev-parse master`

    for BRANCH in $BRANCHES_TO_MERGE; do
        git checkout -B $BRANCH $ORIG_MASTER  # New branch will have the same name as the original child branch
        git merge --allow-unrelated-histories \
          -m "Merge $CHILD into $PARENT" $CHILD/${BRANCH}
    done
)
