# FIXME: go through the options and completion settings and see if
# there's anything else that should be added. We lost a few things
# when we moved away from oh-my-zsh.

################################################################################
#### Define default bundle list

bundles=(
    "plugins/fasd, from:oh-my-zsh" # Quickly jump to directories
    "plugins/lein, from:oh-my-zsh" # Completion for lein
    "plugins/sudo, from:oh-my-zsh" # Quickly re-run commands with sudo
    "plugins/tmuxinator, from:oh-my-zsh" # Completion for tmuxinator
    "plugins/wd, from:oh-my-zsh" # Quickly jump to directories
    "zsh-users/zsh-autosuggestions" # Autosuggestions from history
)

################################################################################
#### Define bundle list management functions

# Usage: add_bundle <zplug-args>
#
# Adds a bundle to $bundles. Word splitting will be performed on
# zplug-args to determine the arguments that will be passed to zplug.
add_bundle() {
    if ! (( ${bundles[(I)$1]} )); then
        bundles+=($1)
    fi
}

# Usage: remove_bundle <zplug-args>
#
# Removes a bundle from $bundles by name. The name should be exactly
# the same as it appears in $bundles, with spaces if necessary.
remove_bundle() {
    bundles=("${(@)bundles:#$1}")
}

################################################################################
#### Load user-specific configuration file (1 of 2)

if [[ -f ~/.zshrc.before.local ]]; then
    source ~/.zshrc.before.local
fi

################################################################################
#### zplug

export ZPLUG_HOME=/usr/local/opt/zplug

if [[ -f $ZPLUG_HOME/init.zsh ]]; then
    source $ZPLUG_HOME/init.zsh

    for bundle in $bundles; do
        zplug $=bundle
    done

    if ! zplug check; then
        zplug install
    fi

    zplug load
fi

################################################################################
#### Prompt

# Enable parameter expansion and other substitutions in the $PROMPT.
setopt promptsubst

# Here we define a prompt that displays the current directory and git
# branch, and turns red on a nonzero exit code. Adapted heavily from
# [1], with supporting functions extracted from Oh My Zsh [2] so that
# we don't have to load the latter as a dependency.
#
# [1]: https://github.com/robbyrussell/oh-my-zsh/blob/master/themes/mgutz.zsh-theme
# [2]: https://github.com/robbyrussell/oh-my-zsh/blob/3705d47bb3f3229234cba992320eadc97a221caf/lib/git.zsh

# Function that compares the provided version of git to the version
# installed and on path Outputs -1, 0, or 1 if the installed version
# is less than, equal to, or greater than the input version,
# respectively.
function git_compare_version() {
    local INPUT_GIT_VERSION INSTALLED_GIT_VERSION
    INPUT_GIT_VERSION=(${(s/./)1})
    INSTALLED_GIT_VERSION=($(command git --version 2>/dev/null))
    INSTALLED_GIT_VERSION=(${(s/./)INSTALLED_GIT_VERSION[3]})

    for i in {1..3}; do
        if [[ $INSTALLED_GIT_VERSION[$i] -gt $INPUT_GIT_VERSION[$i] ]]; then
            echo 1
            return 0
        fi
        if [[ $INSTALLED_GIT_VERSION[$i] -lt $INPUT_GIT_VERSION[$i] ]]; then
            echo -1
            return 0
        fi
    done
    echo 0
}
POST_1_7_2_GIT=$(git_compare_version "1.7.2")
unfunction git_compare_version

# Function that prints the branch or revision of the current HEAD,
# surrounded by square brackets and followed by an asterisk if the
# working directory is dirty, if the user is inside a Git repository.
function radian_prompt_git_info() {
    local ref
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
        ref=$(command git rev-parse --short HEAD 2> /dev/null) || \
        return 0
    echo "[${ref#refs/heads/}$(radian_prompt_git_dirty)]"
}

# Function that prints an asterisk if the working directory is dirty.
# If $RADIAN_PROMPT_IGNORE_UNTRACKED_FILES is true, then untracked
# files are not counted as dirty.
function radian_prompt_git_dirty() {
    local FLAGS
    FLAGS=('--porcelain')
    if [[ $POST_1_7_2_GIT -gt 0 ]]; then
        FLAGS+='--ignore-submodules=dirty'
    fi
    if [[ $RADIAN_PROMPT_IGNORE_UNTRACKED_FILES == true ]]; then
        FLAGS+='--untracked-files=no'
    fi
    if [[ $(command git status ${FLAGS} 2> /dev/null | tail -n1) ]]; then
        echo "*"
    fi
}

# Define the actual prompt format.
PROMPT='%(?.%{$fg[blue]%}.%{$fg[red]%})%c%{$reset_color%}$(radian_prompt_git_info)%(?.%{$fg[blue]%}.%{$fg[red]%}) %# %{$reset_color%}'

################################################################################
#### Tab completion

# FIXME

################################################################################
#### Magic aliases

# When no arguments are provided to "." or "source", they default to
# sourcing .zshrc. Based on [1], thanks @PythonNut!
#
# [1]: http://unix.stackexchange.com/a/326948/176805
function _accept-line() {
    if [[ $BUFFER == "." ]]; then
        BUFFER=". ~/.zshrc"
    elif [[ $BUFFER == "source" ]]; then
        BUFFER="source ~/.zshrc"
    fi
    zle .accept-line
}
zle -N accept-line _accept-line

################################################################################
#### Command history

# Never discard history within a session, or at least not before any
# reasonable amount of time.
export HISTSIZE=1000000

# Save history to disk. The value of this option is the default
# installed by zsh-newuser-install.
export HISTFILE=~/.zsh_history

# Never discard history in the file on disk, either.
export SAVEHIST=1000000

# Don't save commands to the history if they start with a leading
# space.
setopt histignorespace

################################################################################
#### Filesystem navigation

# Default flags for ls:
#   -a  show hidden files except for . and ..
#   -l  display additional information
#   -h  display file size in human-readable format
#   -F  display trailing / for directories
# If GNU ls is available, we use that by default.
if command -v gls &>/dev/null; then
    alias l='gls -AlhF --color=auto'
else
    alias l='ls -AlhF'
fi

# These are global aliases; you can use them anywhere in a command.
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias -g .......='../../../../../..'
alias -g ........='../../../../../../..'
alias -g .........='../../../../../../../..'
alias -g ..........='../../../../../../../../..'

# These are some aliases for moving to previously visited directories.
# The first alias uses "--" so that we can alias "-" without it being
# interpreted as a flag for the alias command.
alias -- -='cd -'
alias 1='cd -'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

# To complement the previous set of aliases, here is a convenient way
# to list the last few directories visited, with their numbers. The
# alias "d", which is used by oh-my-zsh for this purpose, is taken
# from fasd, so instead I chose a different convenient abbreviation of
# "dirs".
alias ds='dirs -v | head -10'

# These aliases are for interacting with directories on the
# filesystem.
alias md='mkdir -p'
alias rd='rmdir'
mcd() {
    mkdir -p $@
    cd ${@[$#]}
}

# You can "copy" any number of files, then "paste", "move" or
# "pasteln" them to pass them as arguments to cp, mv, or ln
# respectively. Just like a graphical filesystem manager. Each of the
# latter three functions defaults to the current directory as the
# destination.
copy() {
    RADIAN_COPY_TARGETS=()
    for target; do
        if [[ $target == /* ]]; then
            RADIAN_COPY_TARGETS+=($target)
        else
            RADIAN_COPY_TARGETS+=($PWD/$target)
        fi
    done
}
paste() {
    cp -R $RADIAN_COPY_TARGETS ${1:-.}
}
move() {
    mv $RADIAN_COPY_TARGETS ${1:-.}
}
pasteln() {
    ln -s $RADIAN_COPY_TARGETS ${1:-.}
}

# This alias takes a symlink, resolves it, and replaces it with a copy
# of whatever it points to.
delink() {
    if [[ -z $1 ]]; then
        echo "usage: delink <symlinks>"
        return 1
    fi
    for link; do
        if [[ -L $link ]]; then
            if [[ -e $link ]]; then
                target=$(grealpath $link)
                if rm $link; then
                    if cp -R $target $link; then
                        echo "Copied $target to $link"
                    else
                        ln -s $target $link
                    fi
                fi
            else
                echo "Broken symlink: $link"
            fi
        else
            echo "Not a symlink: $link"
        fi
    done
}

################################################################################
#### Man

# By default, run-help is an alias to man. We want to turn that off so
# that we can access the function definition of run-help (by default,
# aliases take precedence over functions). But if you re-source this
# file, then the alias might already be removed, so we suppress any
# error that this might throw.
unalias run-help 2>/dev/null || true

# Now we tell Zsh to autoload the run-help function, meaning that when
# it is invoked, Zsh will load the function from the file where it is
# defined. (That file comes with Zsh.) There are additional functions
# that we can autoload that will increase the functionality of
# run-help, but unfortunately they have a serious bug that causes them
# to crash when there is an alias defined for the function that you
# are requesting help for. (For example, loading run-help-git causes
# an error when requesting help for git because we later alias
# git=hub.) So we don't bother with those.
autoload -Uz run-help

# We define a function that wraps man to provide some basic
# highlighting for man pages. This makes them a little easier on the
# eyes. (This is done by binding some environment variables that less
# looks at.) See [1].
#
# [1]: https://github.com/robbyrussell/oh-my-zsh/blob/3ebbb40b31fa1ce9f10040742cdb06ea04fa7c41/plugins/colored-man-pages/colored-man-pages.plugin.zsh
man() {
    env \
	LESS_TERMCAP_mb=$(printf "\e[1;31m") \
	LESS_TERMCAP_md=$(printf "\e[1;31m") \
	LESS_TERMCAP_me=$(printf "\e[0m") \
	LESS_TERMCAP_ue=$(printf "\e[0m") \
	LESS_TERMCAP_us=$(printf "\e[1;32m") \
	man $@
}

# Now we make some convenient aliases to the run-help system. Note
# that this means there are actually three different things called
# man: an executable, a function, and an alias. It all seems to work
# out as necessary, though, so that you get the run-help features,
# with the syntax highlighting as defined above, when you type man.
alias man=run-help
alias help=run-help

################################################################################
#### Git

alias g=git

alias gh='git help'

alias gi='git init'

alias gst='git status'

alias gsh='git show'

alias gl= # FIXME

alias ga='git add'
alias gap='git add --patch'
alias gaa='git add --all'

alias grm='git rm'

alias gmv='git mv'

alias gr='git reset'
alias grs='git reset --soft'
alias grh='git reset --hard'

alias gc='git commit --verbose'
alias gca='git commit --verbose --amend'
alias gcf='git commit -C HEAD --amend'
alias gce='git commit --verbose --allow-empty'
gcw() {
    # This logic is taken from [1]. I think it is designed to
    # correctly deal with the three kinds of changes that might need
    # to be added: changes to existing files, untracked files, and
    # deleted files. (These are surprisingly difficult to account for
    # all at the same time.)
    #
    # [1]: https://github.com/robbyrussell/oh-my-zsh/blob/3477ff25274fa75bd9e6110f391f6ad98ca2af72/plugins/git/git.plugin.zsh#L240
    git add --all
    git rm $(git ls-files --deleted) 2>/dev/null
    git commit --message=--wip--
}

alias gcp='git cherry-pick'
alias gcpc='git cherry-pick --continue'
alias gcpa='git cherry-pick --abort'

alias gt='git tag'
alias gtd='git tag -d'

alias gn='git notes'
alias gna='git notes add'
alias gnr='git notes remove'

alias gsta='git stash save'
alias gstau='git stash save --include-untracked'
alias gstap='git stash save --patch'
alias gstl='git stash list'
alias gsts='git stash show --text'
alias gstss='git stash show --stat'
alias gstaa='git stash apply'
alias gstp='git stash pop'
alias gstd='git stash drop'

alias gd='git diff'

alias gbl='git blame'

alias gb='git branch'
alias gbd='git branch --delete'
alias gbdd='git branch --delete --force'
gbu() {
    git branch --set-upstream-to=$@
}

alias gco='git checkout'
alias gcp='git checkout --patch'
alias gcb='git checkout -B'

alias gbs='git bisect'
alias gbss='git bisect start'
alias gbsg='git bisect good'
alias gbsb='git bisect bad'
alias gbsr='git bisect reset'

alias gm='git merge'
alias gma='git merge --abort'

alias grb='git rebase'
alias grbi='git rebase --interactive'
alias grbc='git rebase --continue'
alias grbs='git rebase --skip'
alias grba='git rebase --abort'

alias gcl='git clone --recursive'

alias gre='git remote'
alias grel='git remote list'
alias gresh='git remote show'
alias greren='git remote rename'
alias grerem='git remote remove'
alias greset='git remote set-url'

alias gf='git fetch --prune'
alias gfa='git fetch --all --prune'

alias gu='git pull'
alias gur='git pull --rebase'
alias gum='git pull --no-rebase'

alias gp='git push'
alias gpf='git push --force'
alias gpu='git push --set-upstream'
alias gpd='git push --delete'

################################################################################
#### Hub

# This extends Git to work especially well with Github. See [1] for
# more information.
#
# [1]: https://github.com/github/hub
eval "$(hub alias -s)" 2>/dev/null || true

################################################################################
#### Tmux

alias mux=tmuxinator

# Function for setting up a tmux session suitable for standard
# development. Takes a project name and an optional command. If a tmux
# session with the project name already exists, switches to it.
# Otherwise, you need to have wd installed. If a warp point with the
# project name already exists, jumps to it. Otherwise, uses fasd to
# make a guess at the correct directory (and creates a warp point,
# with your permission). After getting to the correct directory, sets
# up a tmux session with windows: emacs, git, zsh, zsh. Runs 'emacs'
# in the first window and 'git checkup' in the second. If you provide
# a second argument, runs it as a shell command (provide multiple
# commands with '&&' or ';') in all four windows before anything else.
proj() {
    if ! type tmux &>/dev/null; then
        echo "You need tmux for this to work."
    fi
    if echo "$1" | egrep -q "^\s*$"; then
        echo "Please provide a project name."
        return 1
    fi
    # Check if the session already exists.
    if tmux list-sessions -F "#{session_name}" 2>/dev/null | egrep -q "^$1$"; then
        if [[ $TMUX ]]; then
            tmux switch-client -t "$1"
        else
            tmux attach-session -t "$1"
        fi
    else
        if type wd &>/dev/null; then
            # Check if the warp point exists.
            if wd list | egrep -q "^\s*$1\s"; then
                (
                    # Start the tmux server, if necessary.
                    tmux start-server

                    # Change to the specified directory.
                    wd "$1"

                    # Create the session.
                    TMUX= tmux new-session -d -s "$1" -n emacs

                    # Create the remaining windows.
                    tmux new-window -t "$1:2" -n git
                    tmux new-window -t "$1:3" -n zsh
                    tmux new-window -t "$1:4" -n zsh

                    # Select the 'git' window initially.
                    tmux select-window -t "$1:2"

                    # Run the $2 command in all windows, if necessary.
                    if [[ $2 ]]; then
                        for i in {1..4}; do
                            tmux send-keys -t "$1:$i" "$2" Enter
                        done
                    fi

                    # Run window-specific commands.
                    tmux send-keys -t "$1:1" emacs Enter
                    tmux send-keys -t "$1:2" "git checkup" Enter

                    # Attach to the session.
                    if [[ $TMUX ]]; then
                        tmux switch-client -t "$1"
                    else
                        tmux attach-session -t "$1"
                    fi
                )
            else
                echo "Warp point '$1' not found."
                if which fasd &>/dev/null && type z &>/dev/null; then
                    guess="$(z $1 && echo $PWD)"
                    if [[ $guess ]]; then
                        echo "$guess"
                        echo -n "Is this the correct directory? (Y/n) "
                        read answer
                        if echo "$answer" | egrep -qiv "^n"; then
                            echo -n "Please enter the project name or leave blank to use $1: "
                            read project
                            project=${project:-$1}
                            (cd "$guess" && wd add "$project")
                            proj "$project" "$2"
                            return 0
                        fi
                    else
                        echo "Can't find any directory by that name."
                    fi
                    echo "You'll have to navigate to the directory manually before running proj."
                    return 1
                else
                    echo "You need fasd installed for this to work."
                    return 1
                fi
            fi
        else
            echo "You need wd installed for this to work."
            return 1
        fi
    fi
}

################################################################################
#### Fasd

# Turn off case sensitivity permanently in Fasd. This functionality is
# only available in my fork of Fasd.
export _FASD_NOCASE=1

################################################################################
#### Load user-specific configuration file (2 of 2)

if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
