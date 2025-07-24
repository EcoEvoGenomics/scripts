## The EcoEvoGenomics `scripts` repository

>**Note to external visitors:** Hello and welcome! If you have happened upon this repository from outside the UiO EcoEvoGenomics group, you are still very welcome to use the resources you find here if you find them helpful. But please keep in mind that the resources are mostly practical and shared for in-house use (including using in-house resources by default), and we may not be able to provide support.

### Introduction
Welcome to our `scripts` repository, which holds simple, general-purpose scripts so we can easily share them between ourselves. These are, again, first and foremost *utilities*: because the scripts here are general-purpose, they cannot be fully reproducible for any formal analyses, so for your analyses you should probably make a stand-alone reproducible repository or use a fully reproducible analysis from elsewhere. For ease of organisation, the repository is split into two base folders:

- `archive` holds *outdated* scripts for reference.
- `scripts` holds *current* scripts, organised in topical subfolders.

You can find more information on the contents of each folder in the `README.md` of each subfolder, which should be maintained as an index and documentation of their contents.

### Using scripts from the repository
If you use any of the scripts here, you are likely to do so on a computing cluster such as the Saga HPC. If you want only a single script you can of course download it from here and transfer it to saga as you see prefer. More likely, though, the easiest way to access these scripts is to simply clone the entire repository to wherever you will use them:

```bash
git clone https://github.com/EcoEvoGenomics/scripts
```
This command, `git clone`, downloads the entire repository to your current working directory into a folder named `scripts`.

### Contributing scripts to the repository
If you have written a script you wish to share with the group, that's great - that spares everybody else from reinventing the wheel! We wish to promote a certain workflow here, to keep track of changes and encourage a traceable conversation about our scripts. When we share scripts with our colleagues we need to ensure the scripts do what we expect them to do, and avoid changes made without review. The workflow we wish to encourage broadly revolves around some features of GitHub that may (or may not - that's fine too!) already be familiar to you. If you are not very familiar with GitHub, you're encouraged to read on below!

#### A basic Git and GitHub tutorial
If you are unfamiliar with Git and Github, please refer to the GitHub documentation: https://docs.github.com/en/get-started/start-your-journey/about-github-and-git. The GitHub documentation also covers how to install Git - if you are new to it, the most accessible approach is probably to use GitHub Desktop: https://docs.github.com/en/desktop/installing-and-authenticating-to-github-desktop/installing-github-desktop. Never hesitate to ask for help if you are uncertain!

#### Sharing scripts in the `scripts` folder

>**Important:** This repository is open to the public, and you should not put or refer directly to confidential material like unpublished data or exclusively internal admin resources here.

Let's start simple. You have written a script (or have an idea for a script), `simplify_life.sh`, which you would like to share with the group. Great!
If you've used Git and GitHub a little bit to manage your own projects before, you might be tempted to now clone the repository, put your script in a folder of your choosing, commit the change, and push it to `main`. Please avoid doing this.

Instead, this is how we should work to maintain a record of what we change (and avoid changing what we should not), why we change it, and any conversation we may have around it:

1. Create an `Issue`. On GitHub you will see the tab `Issues` next to `Code` on the top toolband under "EcoEvoGenomics / **scripts**". Click this tab and the green `New Issue` button. The title of your issue should reflect what you think should change in the repository. In this case, something like "Adding script to simplify life". You can provide additional context and description in the text field beneath the title. Before submitting the issue, also complete at least these fields to the left of the text fields on GitHub: `Assignee`, and `Label`. If your plan is to add or change something yourself (which in this example it is), you should self-assign yourself to the issue in the `Assignee` field. Finally label the issue by clicking the `Label`field and choosing a sensible label (like the `new script` label). Please avoid making new labels without discussing this with Mark first - we want to maintain some coherence in the labels. Now you can submit the issue.
2. Once you have submitted the issue, create a branch. If you are looking at your issue, you can do so easily from underneath the `Assignee` and `Labels` fields on the left, under the `Development` header. It is on this branch you should make your changes to the repository, to avoid conflict with any other work going on before your script has been reviewed. For just adding a script this is in practice maybe a little overkill, but it _is_ very good practice to get used to - especially if you start making changes to existing scripts others may be using, instead of just adding new scripts.
3. Working on your new branch, make the changes you want to make. It is good practice to split your changes (commits) into chunks that each do a single thing (but ideally the *whole* single thing). If you have already written the `simplify_life.sh` script, your first commit might be to simply copy this file into a suitable directory in `scripts`. Then in a separate commit, you can update the index section in the `scripts/README.md` file. Once you have made the necessary changes to share your script, it is time to ...
4. Submit a pull request! A pull request is a request to include the changes in your branch on the main branch of the repository (where by default everyone else will be looking for working and complete scripts). A pull request lets you assign a reviewer who can look at the code you have written. By having this code review, we ensure that things that make it the `main` branch are in good shape. To make a pull request, ensure you are looking at your branch (you can select it on GitHub, or in GitHub Desktop - if you know how to do it on the command line, you probably are already comfortable with it!). Got to the `Pull requests` tab and create a new pull request. As with your `Issue`, you can self-assign and add labels. As mentioned, you should also assign a reviewer who will look at your code before it can merge into the `main` branch for everyone to benefit from. If your pull request is approved, your code is shared with the group on `main` and you are done!
5. If you don't do it automatically (and the reviewer forgets), you can close your issue on the issue page and delete your branch. GitHub should tell you when it is safe to do so.

You might notice that both `Issue` and `Pull request` pages are organised like timelines where you can comment. This is a very handy feature for having a traceable conversation about the changes that are made to your code in the process of moving towards merging it into the `main` branch. If the reviewer suggests something you should change before your pull request will be approved, for instance, you can always simply refer to the thread on the pull request!

>**Side-note:** It's strictly speaking not always necessary to make an issue before making a pull request. An issue is generally opened first to describe a problem for someone to solve - so that someone can then develop and pull request a solution to the issue. Or alternatively to show that you are working on the problem! In the example described above, we really had the solution all along (i.e. the finished script `simplify_life.sh`). So as a rule, create an `Issue` if the work is yet to be done - so there is a description of the problem / script you (or someone else) is working on as you work. If you already have a script written and ready to add to the repository, or you are certain it will only take you a short time to do, just make an aptly named branch and pull request. The `Pull request` should then be as descriptive as you would make an `Issue`.


#### Moving something to the archive
If you feel something should be archived, please don't hesitate to act on that feeling - all help is appreciated in keeping the repository up-to-date and tidy. If you want to discuss it first - make an issue named something sensible, like "Archive `scripts/some_dir/specific_file.sh`". If you are confident in the archiving - let's say it's one of your own, and you know it is out of date - simply make an aptly named branch, move the files or directories to the archive on that branch, and issue a pull request to `main` (with a reviewer!). Make sure to move the newly archived folder or file to the appropriate location in the archive. Also update the indices and documentation. As always, never hesitate to ask for directions if you are unsure!

#### Requesting a change or reporting an error in the repository
If you find that a script in the repository e.g. does not work as intended, has poor performance, or uses outdated software, you might want to request a change. Now we can use what we have learned about the `Issues` functionality on GitHub:

1. Make a new `Issue` with a descriptive title and a thorough explanation of what is wrong (as far as you are able). If you know who has the responsibilty for maintaining this script, or who originally wrote it, you can assign them as the `Assignee`. Then add a useful label and submit the issue.
2. If you self-assigned the issue, or found a solution, you can make a branch, change the script as needed, and pull request your solution with (remember to assign a suitable reviewer - **don't change an existing script without at least one review!**).
3. If someone else has to fix the script, you can add additional comments to your issue if you find more information about what is wrong.

> End of README.md - thanks for reading through the documentation!
