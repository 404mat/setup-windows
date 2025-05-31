eval "$(ssh-agent -s)" > /dev/null 2>&1
ssh-add ~/.ssh/github_mathias-pc > /dev/null 2>&1


fastfetch

if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi