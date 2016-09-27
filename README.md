## my dotfiles

```sh
# initialize vim libraries
git submodule init
git submodule update

# initialize emacs libraries
brew install cask # if you need :)
cd _emacs.d
cask install

# create symbolic links
ln -s ./_vimrc ~/.vimrc
ln -s ./_tmux.conf ~/.tmux.conf
ln -s ./_zshrc ~/.zshrc
ln -s ./_emacs.d ~/.emacs.d
ln -s ./_git.commit.template ~/.git.commit.template
cp ./_gitconfig ~/.gitconfig # and add username and email to this config file.
```
