> The word is about, there's something evolving  
> Whatever may come, the world keeps revolving  
> They say the next big thing is here  
> That the revolution's near  
> But to me, it seems quite clear  
> That it's all just a little bit of history repeating
>
> [Propellerheads feat: Miss Shirley Bassey - History Repeating](https://www.youtube.com/watch?v=yzLT6_TQmq8&list=RDyzLT6_TQmq8&start_radio=1)

# Introduction

This is an experiment to understand `git rebase` in the trunk based development (TBD).

TBD:

- Branch.
- Do 3 - 10 commits.
- Meanwhile trunk moves.
- Rebase.

I will indicate the git state with a complete list of references by running

```bash
make show-refs
```

See Makefile.

Showing more figures would be great, but Mermaid with GitGraph is shaky on Firefox. Android does not render any Github Mermaid. See [Git MERGE and REBASE: The Definitive Guide.](https://www.youtube.com/watch?v=zOnwgxiC0OA&list=PLfU9XN7w4tFzW200TaCP1W9RTE8jRSHU5&index=4) for amazing visual explanation.

This repo is an actual demo that does a real rebase. It supplements that visual explanation with a complete precise sequence of git commands. It also explores a bit more the space of git actions from the branch to the trunk.

The branch will have only one commit for the sake of simplicity, but the idea of rebase is to turn

```bash
A ── C                    (origin/main)
 \
  B1 ── B2 ── B3          (feat, HEAD)
```

into

```bash
A ── C                    (origin/main)
      \
       B1' ── B2' ── B3'  (feat, HEAD)
```

This means rewriting history, matching the B-line to the updated trunk (A-C).

# Preparing Merge Conflict

## Stage 0: Clone the empty remote, rm/add remote

```bash
git clone https://github.com/aabbtree77/git-rebase-lab.git
cd ~/git-rebase-lab
```

```bash
HEAD → refs/heads/main
refs/heads/main → 369da27 (Initial commit)
refs/remotes/origin/HEAD → 369da27 (Initial commit)
refs/remotes/origin/main → 369da27 (Initial commit)
```

In order to avoid

"remote: Invalid username or token. Password authentication is not supported for Git operations."

set up Github tokens and run:

```bash
git remote rm origin
git remote add origin https://aabbtree77:$GITHUB_ACCESS_TOKEN@github.com/aabbtree77/git-rebase-lab.git
git remote show origin
```

```bash
HEAD → refs/heads/main
refs/heads/main → 369da27 (Initial commit)
```

The initial commit comes from github and is no commit:

```bash
git status
```

```bash
On branch main
nothing to commit, working tree clean
```

## Stage 1: Create first commit (A)

```bash
echo A > file.txt
git add file.txt
git commit -m "A"
```

```bash
HEAD → refs/heads/main
refs/heads/main → 55d14ba (A)
```

```bash
git push origin main
```

```bash
HEAD → refs/heads/main
refs/heads/main → 55d14ba (A)
refs/remotes/origin/main → 55d14ba (A)
```

## Stage 2: Create feature branch (feat)

```bash
git checkout -b feat
```

```bash
HEAD → refs/heads/feat
refs/heads/feat → 55d14ba (A)
refs/heads/main → 55d14ba (A)
refs/remotes/origin/main → 55d14ba (A)
```

## Stage 3: Create commit B on feat

```bash
echo B >> file.txt
git commit -am "B"
```

```bash
HEAD → refs/heads/feat
refs/heads/feat → aaba28c (B)
refs/heads/main → 55d14ba (A)
refs/remotes/origin/main → 55d14ba (A)
```

## Stage 4: Simulate another developer (dev2)

Open a new terminal.

```bash
git clone https://github.com/aabbtree77/git-rebase-lab.git dev2
cd dev2
cp ~/git-rebase-lab/Makefile ./
```

```bash
HEAD → refs/heads/main
refs/heads/main → 55d14ba (A)
refs/remotes/origin/HEAD → 55d14ba (A)
refs/remotes/origin/main → 55d14ba (A)
```

dev2 is behind local feat branch because B was never pushed to main.

## Stage 5: dev2 creates commit C on main

In dev2:

```bash
echo C >> file.txt
git commit -am "C"
```

```bash
HEAD → refs/heads/main
refs/heads/main → 02bf132 (C)
refs/remotes/origin/HEAD → 55d14ba (A)
refs/remotes/origin/main → 55d14ba (A)
```

Again, before pushing, in order to avoid

"remote: Invalid username or token. Password authentication is not supported for Git operations."

from dev2 run:

```bash
git remote rm origin
git remote add origin https://aabbtree77:$GITHUB_ACCESS_TOKEN@github.com/aabbtree77/git-rebase-lab.git
git remote show origin
```

```bash
git push origin main
```

```bash
HEAD → refs/heads/main
refs/heads/main → 02bf132 (C)
refs/remotes/origin/main → 02bf132 (C)
```

dev2 is done, it updated the remote. Remote main now points to commit C.

## Stage 6: Back to dev1

Switch back the previous tab or
cd ~/git-rebase-lab

```bash
HEAD → refs/heads/feat
refs/heads/feat → aaba28c (B)
refs/heads/main → 55d14ba (A)
refs/remotes/origin/main → 55d14ba (A)
```

origin/main still points to A locally on dev1.

Even though remote main is now C.

## Stage 7: Fetch in dev1

```bash
git fetch origin
```

```bash
HEAD → refs/heads/feat
refs/heads/feat → aaba28c (B)
refs/heads/main → 55d14ba (A)
refs/remotes/origin/main → 02bf132 (C)
```

This is the first real divergence. Local (dev1) main is still stuck at A. Nothing merged.
Nothing rebased. Just remote-tracking ref moved.

## Stage 8: Rebase feat onto origin/main in dev1

With rebase, we want to rewrite local branch feat. Rebase is a local history rewrite. It moves local branch pointer. Remote is not touched. dev2 is not touched.

```bash
git rebase origin/main
```

```bash
Auto-merging file.txt
CONFLICT (content): Merge conflict in file.txt
error: could not apply aaba28c... B
hint: Resolve all conflicts manually, mark them as resolved with
hint: "git add/rm <conflicted_files>", then run "git rebase --continue".
hint: You can instead skip this commit: run "git rebase --skip".
hint: To abort and get back to the state before "git rebase", run "git rebase --abort".
Could not apply aaba28c... B
```

```bash
fatal: ref HEAD is not a symbolic ref
HEAD →
refs/heads/feat → aaba28c (B)
refs/heads/main → 55d14ba (A)
refs/remotes/origin/main → 02bf132 (C)
```

This is not an error. This is the interesting part. Merge conflict.

```bash
git status
```

```bash
interactive rebase in progress; onto 02bf132
Last command done (1 command done):
   pick aaba28c B
No commands remaining.
You are currently rebasing branch 'feat' on '02bf132'.
  (fix conflicts and then run "git rebase --continue")
  (use "git rebase --skip" to skip this patch)
  (use "git rebase --abort" to check out the original branch)

Unmerged paths:
  (use "git restore --staged <file>..." to unstage)
  (use "git add <file>..." to mark resolution)
	both modified:   file.txt
...
```

# Resolving Merge Conflict

## What rebase does

rebase acts where HEAD is pointing and in the end of Stage 7 it is

HEAD → refs/heads/feat

rebase then rewrites feat:

- constructs a unique set of commits which is just B in this special case of a single commit on feat,

- detaches HEAD,

- replays that unique set (B) onto C, oldest commits in the set first.

Replaying B onto C is not merge. Git:

- Takes B.

- Looks at B’s parent = A.

- Computes patch(A → B).

- Applies that patch onto C.

- Creates a brand new commit. Call it D.

This new commit D (B rewritten):

- Has parent = C.

- Has same commit message "B".

- Has new hash.

- Has new timestamp.

Old B still exists in the object database, but is no longer referenced. Eventually garbage collected.

- Git moves refs/heads/feat → D.

- HEAD reattaches to feat.

## Where it stops midway

It stops at "Applies that patch onto C".

C is what dev2 did: echo C >> file.txt:

dev2:

```bash
cat file.txt
A
C
```

dev1 did echo B >> file.txt:

dev1:

```bash
cat file.txt
A
B
```

patch(A → B) is +B. Git applies the patch to C commit which has +C w.r.t. A already:

```bash
CONFLICT (content): Merge conflict in file.txt
```

After git rebase origin/main,

dev1:

```bash
cat file.txt
A
<<<<<<< HEAD
C
=======
B
>>>>>>> aaba28c (B)
```

## Stage 9: Resolving Conflict

Let dev1 accept what dev2 did, and then append "B" to file.txt. This models conflict resolution with content modification by dev1 in its files.

Modify file.txt:

dev1:

```bash
cat file.txt
A
C
B
```

```bash
git add .
git rebase --continue
```

It will show the prompt in nano with B commit's message. The best is to leave it as it is. We are not creating a new B, we are recreating it with a rewritten feat branch history.

ctrl+O ~/git-rebase-lab/.git/COMMIT_EDITMSG
ctrl+X

```bash
[detached HEAD 4e45f17] B
 1 file changed, 1 insertion(+)
Successfully rebased and updated refs/heads/feat.
```

The references now:

```bash
HEAD → refs/heads/feat
refs/heads/feat → 4e45f17 (B)
refs/heads/main → 55d14ba (A)
refs/remotes/origin/main → 02bf132 (C)
```

Old commit aaba28c is no longer referenced.

New commit 4e45f17 exists.

New commit parent = C.

If multiple commits are present in feat, this does not end, but moves from B' to B''... with resolving, `git add .`, and `git rebase --continue`, one commit at a time. Conflict markers appear only in files touched by the current commit being replayed.

If something breaks mid-rebase:

git rebase --abort

returns you to exact pre-rebase state.

# Fin.

Not really. We have rebased, but now we need to submit our work.

```bash
git push --force-with-lease origin feat
```

`--force-with-lease` overwrites the remote branch only if it hasn’t changed since you last fetched. Safer than plain --force.

```bash
HEAD → refs/heads/feat
refs/heads/feat → 4e45f17 (B)
refs/heads/main → 55d14ba (A)
refs/remotes/origin/feat → 4e45f17 (B)
refs/remotes/origin/main → 02bf132 (C)
```

Summary:

- HEAD → refs/heads/feat: Your current checkout cursor; all operations affect this branch.

- refs/heads/feat → commit 4e45f17 (B): Local feature branch, rebased on top of C.

- refs/remotes/origin/feat → 4e45f17 (B): Remote tracking branch for feat — now synchronized via force push.

- refs/heads/main → 55d14ba (A): Local main — hasn’t been updated yet.

- refs/remotes/origin/main → 02bf132 (C): Remote main — trunk, includes commit C that your feature was rebased onto.

Rebased branch is on the remote.

Go to GitHub. Open a PR/MR:

Base: main

Compare: feat

Others (or just me) can now review your clean, rebased changes.

After your PR is merged into main (created PR and self accepted it):

```bash
git checkout main
git pull origin main
```

Now local main is up-to-date with the trunk.

Finally, update README.md and make the release for the public:

```bash
git add .
git commit -m "Final Makefile and README"
git push origin main
```

```bash
HEAD → refs/heads/main
refs/heads/feat → 4e45f17 (B)
refs/heads/main → 037bd00 (Final Makefile and README)
refs/remotes/origin/feat → 4e45f17 (B)
refs/remotes/origin/main → 037bd00 (Final Makefile and README)
```

# After rebase, what happens if we `git push origin main`?

Suppose

```bash
A ── C (origin/main)
\
 D1 ── D2 ── D3 (feat, HEAD)
```

```bash
refs/heads/feat → D3
refs/remotes/origin/main → C
refs/heads/main → A (or maybe C if pulled later)
HEAD → feat
```

```bash
git push origin main
```

What happens?

Git tries to update the remote main branch to your local main.

If local main has not moved beyond remote, this is a fast-forward.

In our current example:

local main → A
origin/main → C

Local main is behind origin/main.

Git will reject push by default, because a non-fast-forward push is dangerous.

```bash
! [rejected] main -> main (non-fast-forward)
```

Unless you use:

```bash
git push --force origin main
```

Force push will overwrite origin/main to point to your local main.

This is dangerous if other people depend on that remote branch.

# After rebase, what happens if we `git push origin feat`?

```bash
git push origin feat
```

Remote origin/feat still points to old B chain.

Your local feat has rewritten commits D1 → D2 → D3.

Git sees that remote history diverged.

Push will be rejected unless you force:

git push --force origin feat

This is normal after rebase.

Key points:

- Rewriting history changes commit hashes.

- Remote still has old commits.

- Force push is necessary to synchronize.

# Safe flow after rebase

Update local remote refs:

```bash
git fetch origin
```

Rebase local feat onto main (latest trunk):

```bash
git rebase origin/main
```

Resolve conflicts, continue:

```bash
git rebase --continue
```

Force push feature branch:

```bash
git push --force-with-lease origin feat
```

--force-with-lease ensures you don’t overwrite someone else’s work accidentally.

```bash
A ── C ── 4e45f17         (origin/feat)
        \
         ...                (other trunk commits)
```

Everyone sees your rebased commit as if it was created on top of the latest main — no messy merge commits.

Old commit aaba28c disappears from active refs, only exists in history temporarily.

Open PR (if using GitHub, GitLab, etc.), others review, merge.

Remote now sees the rewritten commits.

Update your local trunk:

```bash
git checkout main
git pull origin main
```

# Final advice by ChatGPT5:

- Keep branches small.

- Rebase frequently.

- Use IDE merge tools, e.g. VSCode merge editor.

- Do not heroically resolve 50-commit rebases from two weeks ago.

- Never rebase a branch that others are actively working on (unless coordinated).

- For trunk-based development, feature branches are short-lived; force push is safe.

- For shared long-lived branches, you generally avoid force pushes.

# References

[Git MERGE and REBASE: The Definitive Guide](https://www.youtube.com/watch?v=zOnwgxiC0OA&list=PLfU9XN7w4tFzW200TaCP1W9RTE8jRSHU5&index=4)

# Appendix: Graph Theory

Rebase is a beautiful complex machinery and Sect. What rebase does is just a sketch which does not mention the important math surrounding it:

- The replay (patching) is `merge-base` and `diff3` algorithms.

- The unique set of commits to replay on C (which was just B), is some reachability theory implemented by

  ```bash
  git rev-list origin/main..feat
  ```

History rewriting is tricky...
