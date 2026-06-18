**User:** lucus@dhcp-9-16-46-248 bob-validation-mode % git add .bob/skills/bob-council 
lucus@dhcp-9-16-46-248 bob-validation-mode % git commit -m "bob council skill"
[lucuskim 79fd2c3] bob council skill
 1 file changed, 409 insertions(+)
 create mode 100644 .bob/skills/bob-council/SKILL.md
lucus@dhcp-9-16-46-248 bob-validation-mode % git push
fatal: The current branch lucuskim has no upstream branch.
To push the current branch and set the remote as upstream, use

    git push --set-upstream origin lucuskim

To have this happen automatically for branches without a tracking
upstream, see 'push.autoSetupRemote' in 'git help config'.

---

**Bob:** Calling tools

---

---

**Bob:** Branch pushed. `lucuskim` is now tracking `origin/lucuskim`. You can open a PR at the link above if you're ready to merge.

---

**User:** Im just merged my branch and added bob council. Now i want to checkout main but i  cant seem to:lucus@dhcp-9-16-46-248 bob-validation-mode % git pull
remote: Enumerating objects: 81, done.
remote: Counting objects: 100% (81/81), done.
remote: Compressing objects: 100% (53/53), done.
remote: Total 74 (delta 11), reused 62 (delta 7), pack-reused 0 (from 0)
Unpacking objects: 100% (74/74), 78.28 KiB | 1.57 MiB/s, done.
From github-personal:ajbozarth/bob-validation-mode
 * [new branch]      confidenceScore               -> origin/confidenceScore
   df1c275..0d36c80  main                          -> origin/main
 * [new branch]      task/requirements-cross-check -> origin/task/requirements-cross-check
Your configuration specifies to merge with the ref 'refs/heads/lucuskim'
from the remote, but no such ref was fetched.
lucus@dhcp-9-16-46-248 bob-validation-mode % git checkout main
error: Your local changes to the following files would be overwritten by checkout:
        .bob/custom_modes.yaml
Please commit your changes or stash them before you switch branches.
Aborting
lucus@dhcp-9-16-46-248 bob-validation-mode % git stash
Saved working directory and index state WIP on lucuskim: 79fd2c3 bob council skill
lucus@dhcp-9-16-46-248 bob-validation-mode % git pull
Your configuration specifies to merge with the ref 'refs/heads/lucuskim'
from the remote, but no such ref was fetched.
lucus@dhcp-9-16-46-248 bob-validation-mode % git fetch origin main
From github-personal:ajbozarth/bob-validation-mode
 * branch            main       -> FETCH_HEAD

---

**Bob:** You're almost there. Just checkout main and reset it to the fetched remote:

---

---
