## The EcoEvoGenomics `scripts` repository
A repository for scripts within the lab - for sharing and as a resource! 

### Folder structure
For ease of organisation, the repository is separated into four base folders:

- `0-admin` holds only administrative files
- `1-resources` holds re-usable general purpose scripts for sharing between projects, organised in topical subfolders
- `2-projects` holds bespoke per-project scripts for *ongoing* projects, organised in project subfolders
- `3-archive` holds subfolders for *completed* projects, which should be moved here, as well as *outdated* resources

You can find more information on the `README.md` of each subfolder, which should be maintained as an index of the contents in each folder.

### How to work with the repository
To keep track of changes and encourage a traceable conversation about our work, we want to promote a template workflow here.
That workflow broadly revolves around some features of GitHub that may (or may not - that's fine too!) already be familiar to you.

The `0-admin` folder should be fairly static and not a part of our day-to-day workflow. For each of the other subfolders, though, the following is how we should use the many facilities that GitHub offers. If you are not very familiar with GitHub, you're encouraged to read all of this!

#### A basic Git and GitHub tutorial
To be added ...

#### Sharing general-use scripts in the `1-resource` folder
Let's start simple. You have written a script (or have an idea for a script), `simplify_life.sh`, which you would like to share with the group. Great!
If you've used Git and GitHub a little bit to manage your own projects before, you might be tempted to now clone the repository, put your script in a folder of your choosing, commit the change, and push it to `main`. Please avoid doing this.

Instead, this is how we should work to maintain a record of what we change (and avoid changing what we should not), why we change it, and any conversation we may have around it:

1. Create an `Issue`. On GitHub you will see the tab `Issues` next to `Code` on the top toolband under "EcoEvoGenomics / **scripts**". Click this tab and the green `New Issue` button. The title of your issue should reflect what you think should change in the repository. In this case, something like "Adding script to simplify life". You can provide additional context and description in the text field beneath the title. Before submitting the issue, also complete at least these fields to the left of the text fields on GitHub: `Assignee`, and `Label`. If your plan is to add or change something yourself (which in this example it is), you should self-assign yourself to the issue in the `Assignee` field. Finally label the issue by clicking the `Label`field and choosing a sensible label (like the `new script` label). Please avoid making new labels without discussing this with Mark first - we want to maintain some coherence in the labels. Now you can submit the issue.
2. Once you have submitted the issue, create a branch. If you are looking at your issue, you can do so easily from underneath the `Assignee` and `Labels` fields on the left, under the `Development` header. It is on this branch you should make your changes to the repository, to avoid conflict with any other work going on before your script has been reviewed. For just adding a script this is in practice maybe a little overkill, but it _is_ very good practice to get used to - especially if you start making changes to existing scripts others may be using, instead of just adding new scripts.
3. Working on your new branch, make the changes you want to make. It is good practice to split your changes (commits) into chunks that each do a single thing. If you have already written the `simplify_life.sh` script, your first commit might be to simply copy this file into a suitable folder in `1-resource`. Then in a separate commit, you can write an entr about your script in the index section of the `1-resource/README.md` file. Once you have made the necessary changes to share your script, it is time to ...
4. Submit a pull request! A pull request is a request to include the changes in your branch on the main branch of the repository (where by default everyone else will be looking for working and complete scripts, etc.). A pull request lets you assign a reviewer who can look at the code you have written, where in the repository you have placed it, etc. By having this code review, we ensure that things that make it the `main` branch are in good shape. To make a pull request, ensure you are looking at your branch (you can select it on GitHub, or in GitHub Desktop - if you know how to do it on the command line, you probably are already comfortable with it!). Got to the `Pull requests` tab and create a new pull request. As with your `Issue`, you can self-assign and add labels. As mentioned, you should also assign a reviewer who will look at your code before it can merge into the `main` branch for everyone to benefit from. If your pull request is approved, your code is shared with the group on `main` and you are done!
5. If you don't do it automatically (and the reviewer forgets), you can close your issue on the issue page and delete your branch. GitHub should tell you when it is safe to do so.

You might notice that both `Issue` and `Pull request` pages are organised like timelines where you can comment. This is a very handy feature for having a traceable conversation about the changes that are made to your code in the process of moving towards merging it into the `main` branch. If the reviewer suggests something you should change before your pull request will be approved, for instance, you can always simply refer to the thread on the pull request!

Side-note: It's strictly speaking not always necessary to make an issue before making a pull request. An issue is generally opened first to describe a problem for someone to solve - so that someone can then develop and pull request a solution to the issue. In the example described above, we really had the solution all along (i.e. the finished script `simplify_life.sh`). More about this later.

#### Adding your project to the `2-projects` folder
If you are new in the group or have a new project, you can add a new subfolder under `2-projects` to keep bespoke scripts that are not (readily) useful to other users. The benefit of having them here is (as discussed above) the traceable and convenient history of changes Git and GitHub offers us. You probably (actually - definitely) shouldn't keep everything here, but scripts that you can share publicly and want to discuss and co-develop with e.g. Mark are very handy to have in a GitHub repository. **Remember that this repository is open to the public, and you should not put confidential material like unpublished data or exclusively internal admin resources here.** To add your folder, simply use the approach described above - create an issue (e.g. "Adding a new folder for (project name here)"), make a branch and add your folder containing at least one file (for technical reasons), commit this and pull request the addition of your project folder to the `main` branch. After that you can use the same approach as described for adding a general-use script above!

#### Moving something to the archive
To be added ...

#### Requesting a change or reporting an error in the repository
If you find that a script in the repository e.g. does not work as intended, has poor performance, or uses outdated software, you might want to request a change. Now we can use what we have learned about the `Issues` functionality on GitHub:

1. Make a new `Issue` with a descriptive title and a thorough explanation of what is wrong (as far as you are able). If you know who has the responsibilty for maintaining this script, or who originally wrote it, you can assign them as the `Assignee`. Then add a useful label and submit the issue.
2. If you self-assigned the issue, or found a solution, you can make a branch, change the script as needed, and pull request your solution with (remember to assign a suitable reviewer - **don't change an existing script without at least one review!**).
3. If someone else has to fix the script, you can add additional comments to your issue if you find more information about what is wrong.

> End of README.md
