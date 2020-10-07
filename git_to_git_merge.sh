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

# PreReqs
#
# Clone https://github.com/nipunn1313/git_repo_merges as a sibling repo
# Clone $CHILD and $PARENT as sibling repos
# Install java (apt install default-jre)
# Download https://rtyley.github.io/bfg-repo-cleaner/ as a sibling to the repos
#
# Must manually run from within the $PARENT - once
# > git remote add "${CHILD}" ../"${CHILD}"

# Assumes:
#  - $CHILD is a checkout of the child repo in the cwd
#  - $PARENT is a checkout of the parent repo in the cwd
#  - $PARENT has a remote pointing to $CHILD (create with `git remote add child ../$CHILD`)
# - bfg is installed in ./ (see https://rtyley.github.io/bfg-repo-cleaner/)

this_file="${BASH_SOURCE[0]}"
script_dir=`realpath "${this_file%/*}"`

(
    cd $CHILD

    for BRANCH in $BRANCHES_TO_MERGE; do
        git checkout -f $BRANCH
        git reset --hard origin/$BRANCH
    done

    # From an example in the git-filter-branch documentation:
    #   https://git.github.io/htmldocs/git-filter-branch.html
    #
    # Modified to have a literal tab character in the sed command because:
    #     Note that the only C-like backslash sequences that you can portably
    #     assume to be interpreted are \n and \\; in particular \t is not
    #     portable, and matches a 't' under most implementations of sed, rather
    #     than a tab character.
    index_filter_move_to_subdir='
        git ls-files -s | sed "s-	\"*-&'"$SUBDIR"'/-" |
           GIT_INDEX_FILE=$GIT_INDEX_FILE.new \
               git update-index --index-info &&
        mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"
    '

    # Add original commit IDs to commit messages,
    # and rewrite paths to move into $SUBDIR.
    git filter-branch -f \
      --msg-filter "python ${script_dir}/add_original_commits_filter.py $CHILD" \
      --index-filter "$index_filter_move_to_subdir" \
      -- --all

    # Strip out large blobs
    java -jar ../bfg-1.13.0.jar --strip-blobs-bigger-than 512K

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
