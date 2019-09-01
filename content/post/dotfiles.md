---
title: "Linux / Mac 系统 dotfiles 文件备份还原最佳实践"
date:  2019-05-25
lastmod: 2019-05-25
draft: false
tags: ["git", "dotfiles"]
categories: ["System"]
author: "Jessun"
weight: 1

# You can also close(false) or open(true) something for this content.
# P.S. comment can only be closed
# comment: false
# toc: false

# You can also define another contentCopyright. e.g. contentCopyright: "This is another copyright."
# contentCopyright: 'null'
# reward: false
# mathjax: true
---

## Github 上的 Dotfiles 管理

在使用 Linux 和 Mac 系统时候， 常常需要同步 dotfiles。比如 fish 的配置文件在 ~/.config/fish/config.fish，vim 的配置文件在 ~/.vim/vimrc 等等。Github 有个[ 非官方指南 ](https://dotfiles.github.io)。

## 使用 Git Repo 方式管理 dotfiles

> 参考: [The best way to store your dotfiles: A bare Git repository](https://www.atlassian.com/git/tutorials/dotfiles)

### 开始

```shell
git init --bare $HOME/.cfg
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
config config --local status.showUntrackedFiles no
echo "alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'" >> $HOME/.bashrc
```

- 第一行创建一个文件夹 `~/.cfg`，一个 [ Git bare repository ](http://www.saintsjd.com/2011/01/what-is-a-bare-git-repository/)，用来管理我们的 dotfiles。

- 创建一个 alias 名为 config 的命令，用来进行操作。

- 隐藏其他我们没有明确是否跟踪的文件。这样，当使用 `config status` 命令的时候，不会显示其他无关的文件。

- 将这个别名命令写入 .bashrc 文件。

执行完以上设置之后，$HOME 文件夹中的任何文件都可以用命令进行版本控制。例如：

```shell
config status
config add ~/.vim/vimrc
config commit -m 'Add vimrc'
config add ~/.bashrc
config commit -m 'Add bashrc'
```

这时候，就可以把这个 git 仓库 push 到 github 或者其他远程仓库上。

##  在新系统上下载和使用设置

1. 首先依旧新建 alias，忽略 .cfg 文件夹。

```shell
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
echo ".cfg" >> .gitignore
```

2. 下载备份的配置

```shell
git clone --bare <git-repo-url> $HOME/.cfg
```

3. 检出分支内容

```shell
config checkout
```

上面的步骤可能会失败，并显示类似的如下消息：

```shell
error: The following untracked working tree files would be overwritten by checkout:
    .bashrc
    .gitignore
Please move or remove them before you can switch branches.
Aborting
```

4. 将这些已经存在的文件移动到备份文件夹：

```shell
mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}
```

再次检出

```shell
config checkout
```

这样就可以一直更新并 push 自己的配置仓库了。
