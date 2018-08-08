# gcloud
if [ -f '/usr/local/bin/google-cloud-sdk/path.fish.inc' ];
  if type source > /dev/null;
    source '/usr/local/bin/google-cloud-sdk/path.fish.inc';
  else;
    . '/usr/local/bin/google-cloud-sdk/path.fish.inc';
  end;
end

# rbenv
status --is-interactive; and source (rbenv init -|psub)