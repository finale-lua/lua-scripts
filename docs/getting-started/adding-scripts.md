# Adding Scripts

> To add scripts, you'll need a GitHub account. If you don't have one, you can [sign up here](https://github.com/signup).

Once you've written your script, you'll be able to add it to the repository.

This guide assumes that you're not familiar with Git or GitHub (which is totally ok). However, if you are familiar with them, feel free to skip down to [Adding your script](#adding-your-script).

## Background on Git and GitHub

Git is a version control system that developers use to keep track of changes to their code. It's a very popular system, and it's used by a lot of companies. GitHub is a website that lets you host your code and make it available to others, and it uses Git to track the changes in the code.

Overall, you can think of it kind of like Google Docs. You can write code, and others can read it, and you can make changes to it. And everything is synced up so everyone knows what the "correct" version of the code is. And the way in which this is done is through forks, commits, and pull requests.

Here's what those terms mean.

### Forks

A fork is a copy of this repository that you can make changes to. In this guide, you're going to fork this repository (which is literally creating a line-by-line clone) and saving that fork onto your computer. That way, you can make changes to the code and then push those changes back to the original repository.

Forking a repository is a lot like just copying a Google Docs file.

### Commits

Commits are snapshots in time. They are save points. Once you edit, add, or delete several files, you "commit" them to group those changes together. Note that this is different than saving an individual file. You can save changes as many times as you want, but you only "commit" them once to—well—commit the changes.

### Pull requests

By now you may have realized that you've made changes to a copy of this repository, not the original one. Pull requests allow you to merge those changes back into the original repository.

As part of the pull request process, other collaborators can review your code. This isn't a test to pass, but rather it's just a constructive step to help improve the quality of your contributions. Once your pull request is merged, you've contributed!

---

In addition to this guide, there great resources for learning [Git](https://youtu.be/USjZcfj8yxE) and [GitHub](https://youtu.be/nhNq2kIvi9s) out there in case you'd like to learn more.

## Adding your script

> In short, you'll create a pull request to add your script to the `/src` directory. This section will walk you through that process.

When using Git and GitHub, you can either use the terminal or GitHub Desktop, which is a desktop application that provides a nice interface for Git. In thie guide, we'll be using GitHub Desktop. You can download it at [https://desktop.github.com](https://desktop.github.com/).

Make sure you download GitHub Desktop and sign in to your GitHub account. You only need to do this once.

Checkout [GitHub's documentation](https://docs.github.com/en/desktop/installing-and-configuring-github-desktop/overview/getting-started-with-github-desktop#part-1-installing-and-authenticating) for this for more detail.

And if you get stuck, you can always [get help](/docs/getting-started/getting-help).

### 1. Clone the repository

You will only need to clone the repository once. If you've already cloned it (e.g., you already contributed a script), you can skip this step.

1. Once you've signed into GitHub Desktop, go to the repository on GitHub. [https://github.com/finale-lua/lua-scripts](https://github.com/finale-lua/lua-scripts)
2. You should see a bright green button that says "Code". Click it! Then click "Open with GitHub Desktop."
3. This will bring up a dialog in GitHub Desktop. Note the folder where it says "Local Path." This is the location GitHub desktop saves your fork of the repository on your computer. You will need this later.
4. Click "Clone" to fork the repository. This will save a copy of the repository on your computer.
5. Success! You've now cloned the repository.

### 2. Add your script

Once you've written your script, you'll now be able to add it to the repository.

You may wish to double-check your script with the [script checklist](/docs/getting-started/script-checklist) before adding it. Don't worry, though. If there's something you missed, we'll help you out.

1. Find the cloned repository on your computer. This is the "Local Path" you noted earlier.
2. Inside the repository folder, you should see another folder named `src`. This is where all the scripts are stored. Add your script file (e.g., `note_resize.lua`) to this `src` folder.
3. Go back to GitHub Desktop. You should now see that one file was added.
4. Next, let's name the commit. In the lower left corner of GitHub Desktop, you should see a text field that either says "Summary (required)" or "Add [script name]". This is is the name of your commit. Go ahead and make sure it says "Add [script name]" (e.g., "Add note_resize.lua").
5. Finally, let's commit the change. Again, in the lower left corner of GitHub Desktop, you should see a blue button that says "Commit to master". Click it!
6. Success! You've now committed your change to the repository.

### 3. Create a pull request

Creating a pull request is the final step in adding your script to the repository. A pull request will merge your changes into the original repository.

If you've already contributed, skip the first three items and move to item #4: click "Push origin".

1. Go back to GitHub Desktop. At the top, you should see a button that says "Push origin". Click it!
2. You'll receive a prompt to fork the repository. Select "Fork This Repository."
3. Next, GitHub Desktop will ask you how you plan to use the fork. Select "To contribute to the parent project" because you want to contribute to the main repository for these scripts.
4. Click the same "Push origin" button. This will sync your changes with GitHub's servers.
5. Go to Branch > Create Pull Request in the menu bar. This will take you to github.com to create the pull request.
6. On GitHub.com, click "Create Pull Request"
7. Add a descriptive title and description, then press "Create Pull Request"
8. Success! You've now created a pull request!

We will now review your script and merge it into the main repository. We may ask for some changes before it is merged, but we'll help you through that process if needed.
