# Contributing Guidelines

If you're thinking about making a contribution to this project, then you're in the right place.
First, thank you for taking the time to contribute! Please give everything below a read before
attempting to contribute, as it may save you some time and energy when it comes time to submit
your awesome new feature, fix, or bug report!

The following contributions to Restivus are greatly appreciated:
- Code (via pull request)
  - New or updated features
  - Bug fixes
  - Automated tests 
- Documentation updates (currently via README)
- Bug reports (via GitHub Issues)
- Feature requests and voting (via GitHub Issues)

[GitHub Issues](https://github.com/kahmali/meteor-restivus/issues) are used for all bug and feature 
tracking. [Milestones](https://github.com/kahmali/meteor-restivus/milestones) will be created for 
each release version (e.g., `v1.0.0`), and any associated Issues or [Pull Requests]
(https://github.com/kahmali/meteor-restivus/pulls?q=is%3Aopen+is%3Apr) will be added to the 
corresponding milestone. 


## Code Contributions

Contributing code to an open source project can be fun and rewarding, especially when it's done
right. Check out the guidelines below for more information on getting your changes merged into a
release.

### Coding Conventions

Please adhere to the [Meteor Style Guide](https://github.com/meteor/meteor/wiki/Meteor-Style-Guide) 
for all conventions not specified here:

1. 100 character line limit for all code, comments, and documentation files


### Pull Requests

All code contributions can be submitted via GitHub Pull Requests. Here are a few guidelines you
must adhere to when contributing to this project:

1. **All pull requests should be made on the `devel` branch, unless intended for a specific release! 
   In that case, they can be made on the branch matching the release version number (e.g., 
   `1.0.0`)** If you're not familiar with [forks](https://help.github.com/articles/fork-a-repo/) and 
   [pull requests](https://help.github.com/articles/using-pull-requests/), please check out those 
   resources for more information.
1. Begin your feature branches from the latest version of `devel`.
1. Before submitting a pull request:
   1. Rebase to the latest version of `devel`
   1. Add automated tests to the `/tests` directory for any new features 
   1. Ensure all automated tests are passing by running `meteor test-packages ./` from the root
      directory of the project and viewing the Tinytest output at `http://localhost:3000`
   1. Update the [README](https://github.com/kahmali/meteor-restivus/blob/devel/README.md) and 
      [change log](https://github.com/kahmali/meteor-restivus/blob/devel/CHANGELOG.md) with any 
      corresponding changes
     - Please follow the existing conventions within each document until detailed conventions can 
       be formalized for each

### Committing

Limit commits to one related set of changes. If you’ve worked on several without committing, use
[`git add -p`](http://nuclearsquid.com/writings/git-add/) to break it up into multiple commits.

Try to start and finish one related set of changes in a commit. If your set of changes spans
multiple commits, use interactive rebase [`git rebase -i`]
(https://www.atlassian.com/git/tutorials/rewriting-history/git-rebase-i) to squash the commits
together.

### Commit Messages

Please follow these guidelines for commit messages:

1. Separate subject from body with a blank line
1. Limit the subject line to 72 characters (shoot for 50 to keep things concise, but use 72 as the 
   hard limit)
1. Capitalize the subject line
1. Do not end the subject line with a period
1. Use the imperative mood in the subject line
1. Wrap the body at 72 characters
1. Use the body to explain what and why vs. how
  - _Note: Rarely, only the subject line is necessary_

For a detailed explanation, please see [How to Write a Git Commit Message]
(http://chris.beams.io/posts/git-commit/#seven-rules).


## Bug Reports

Please file all bug reports, no matter how big or small, as [GitHub Issues]
(https://github.com/kahmali/meteor-restivus/issues). Please provide details, and, if possible,
include steps to reproduce the bug, a sample GitHub repo with the bug reproduced, or sample code.


## Feature Requests

Restivus is still a work in progress. Feature requests are welcome, and can be created and voted on
using [GitHub Issues](https://github.com/kahmali/meteor-restivus/issues)!