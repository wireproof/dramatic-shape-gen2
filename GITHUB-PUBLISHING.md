# GitHub publishing notes

## Repository visibility

Create `wireproof/dramatic-shape-gen2` as a **private** repository. The supplied
Dramatic Shape 1.8.0 README prohibits redistribution of post-1.6.0
non-derivative code without permission, and the archive did not include a
license granting public redistribution. `PORT-NOTICE.md` records the split
provenance of this combined tree.

Do not make the repository or a release containing the combined source public
unless Dramatic Shape's copyright holder grants permission covering 1.8.0.

## First push through the GitHub website

1. Sign in to GitHub as `wireproof`.
2. Open <https://github.com/new>.
3. Set the repository name to `dramatic-shape-gen2`.
4. Choose **Private**.
5. Leave README, `.gitignore`, and license initialization unchecked because
   this source already contains its own history and documentation.
6. Select **Create repository**.
7. Follow GitHub's **push an existing repository from the command line**
   instructions from this source directory. Use the branch name
   `dramatic-shape-gen2-1.8.0-gen2.1`.

GitHub will require either GitHub CLI/browser authentication or a credential
manager. Do not paste a personal access token into a chat message or commit it
to this repository.

## Public alternative

A public repository should contain only independently written documentation
and permission-safe patching/installer material that requires each user to
supply their own lawfully obtained 1.8.0 archive. Review that distribution
design before publishing; do not simply copy this combined tree into it.
