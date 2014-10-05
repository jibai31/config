For the best experience using Vim on the Vagrant Ubuntu box, install the following plugins:

Install Pathogen and Vundle, then Excuberant CTags:
```
$ mkdir -p ~/.vim/autoload ~/.vim/bundle
$ wget https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
$ mv pathogen.vim ~/.vim/autoload/pathogen.vim
$ git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
$ sudo apt-get install exuberant-ctags
$ mkdir ~/.tmp
```

And get the `.vimrc`:
```
$ wget https://raw.github.com/jibai31/config/master/.vimrc
$ wget .vimrc ~/.vimrc
```

Start vim, and run the following command:
```
:BundleInstall
```
