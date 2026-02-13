# Introduction

This is an experiment to understand `git rebase` in the trunk based development (TBD).

TBD:

- You branch.
- You do 3–10 commits.
- Meanwhile trunk moves.
- You rebase.

Mermaid with GitGraph is shaky on Firefox. Android does not render any Github Mermaid.

Instead, I will indicate the git state with a complete list of references by running

```bash
make show-refs
```

See Makefile.

The branch will have only one commit in order not to be repetitive, but the idea is to rebase

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

To go slowly to understand what rebase means.

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

Therefore rebase rewrites feat:

- builds the set of all commits (B, B', ...) in feat not in origin/main.

- detaches HEAD which will be reattached to feat when rebase completes. rebase is transactional, we succeed or git rebase --abort.

- replays (B, B', ...) onto C, oldest first.

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

# The Big Picture

- Keep branches small.

- Rebase frequently.

- Use IDE merge tools, e.g. VSCode merge editor.

Do not heroically resolve 50-commit rebases from two weeks ago.

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

rebased branch is on the remote.

Go to GitHub. Open a PR/MR:

Base: main

Compare: feat

Others can now review your clean, rebased changes.

Update your local main after PR merge (or after other people’s changes).

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
