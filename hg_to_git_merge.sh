# Converts CHILD into an hg repo
# uses https://github.com/frej/fast-export

CHILD=child_hg_repo
CHILD_GIT=${CHILD}_git

(
    mkdir $CHILD_GIT
    cd $CHILD_GIT

    time ../fast-export/hg-fast-export.sh -r ../$CHILD
    git reset --hard master
)
