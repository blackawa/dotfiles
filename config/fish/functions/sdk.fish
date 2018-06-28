function sdk
  bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk $argv"
end

for ITEM in $HOME/.sdkman/candidates/*;
  set-gx PATH $PATH $ITEM/current/bin
end
