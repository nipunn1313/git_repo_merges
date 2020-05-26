import sys
import os

repo_name = sys.argv[1]

print(
    "%s\nOriginal %s Repo Git Commit: %s"
    % (sys.stdin.read(), repo_name, os.environ.get("GIT_COMMIT"))
)
