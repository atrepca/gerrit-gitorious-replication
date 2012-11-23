# Gerrit to Gitorious replication

When replicating Git repositories from [Gerrit](http://code.google.com/p/gerrit/) to [Gitorious](http://gitorious.org/), the repositories have to be created in Gitorious beforehand. This is a script that compares the list of repositories in both Gerrit and Gitorious and creates the missing ones in the latter. It can also be used to batch create Gitorious repositories.

## Installation

* Copy `sync-repos.cron` to `/etc/cron.d/` and `sync-repos.sh` to a preferred location on a centralized job scheduling server
* Copy `create-gitorious-repos.rb` to the Gitorious server

## Configuration

1. `sync-repos.sh` - 5 variables need to be set: the Gerrit server and a Gerrit user, the Gitorious server and a user account, and the location of `create-gitorious-repos.rb`.
2. `sync-repos.cron` - Set the location of `sync-repos.sh` and the user it will run as.
3. `create-gitorious-repos.rb` - 2 variables need setting: the Gitorious project repositories will be created into and the path to `environment.rb`.
