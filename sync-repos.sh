#!/bin/bash

# Compares the repository list between Gerrit and Gitorious and if the latter
# is missing any it creates them by calling the ${CREATE_REPOS} script on the
# ${GITORIOUS} server.
#
# This script is for the Gerrit to Gitorious replication, so a scenario where
# repositories are created in Gerrit first. For the replication to function
# properly the repositories have to exist in Gitorious too.
#
# The script runs from a location external to both ${GERRIT} and ${GITORIOUS}.
#
# CONFIGURATION: set the variables below, points 1 to 6.

# -----------------------------------------------------------------------------
# exit on error
set -e

# consider unset variables an error
set -u

# -----------------------------------------------------------------------------
# misc; variables, change these as needed

# 1. Gerrit server FQDN
GERRIT="gerrit.example.org"

# 2. Gerrit user; needs to be part of the Administrators group to get the list
# of all the projects and trigger the replication
GERRIT_USER="gerrit"

# 3. Gitorious server FQDN
GITORIOUS="gitorious.example.org"

# 4. An account on the Gitorious server; needs an SSH key, needs to be able to
# run MySQL commands without a password (through ~/.my.cnf) and MySQL select
# rights on the ${GITORIOUS_DB}; also needs rights to run the ${CREATE_REPOS}
# script as root
GITORIOUS_USER="gitorious"

# 5. The Gitorious MySQL Production database
GITORIOUS_DB="gitorious_production"

# 6. the location of the script that creates the repositories on the
# ${GITORIOUS} server
CREATE_REPOS="/opt/scripts/create_gitorious_repos.rb"

# a temporary directory where the diff files will be created; will be cleaned
# up on exit
DIFF_DIR=`/bin/mktemp -d /tmp/tmp.XXXXXXXXXX`
trap "/bin/rm -rf ${DIFF_DIR}" EXIT

# -----------------------------------------------------------------------------
# get the sorted list of Gerrit projects and convert them to lowercase
/usr/bin/ssh -p 2222 ${GERRIT_USER}@${GERRIT} gerrit ls-projects --type ALL > ${DIFF_DIR}/repos_gerrit
/bin/cat ${DIFF_DIR}/repos_gerrit | /usr/bin/tr '[A-Z]' '[a-z]' | /bin/sort > ${DIFF_DIR}/repos_gerrit_lowercase

# -----------------------------------------------------------------------------
# get the sorted list of Gitorious repositories
/usr/bin/ssh ${GITORIOUS_USER}@${GITORIOUS} 'mysql --skip-column-names -B -u ${GITORIOUS_USER} ${GITORIOUS_DB} -e "SELECT name FROM repositories"' | /bin/sort > ${DIFF_DIR}/repos_gitorious

# -----------------------------------------------------------------------------
# compare the two resulting files; we're interested only in lines unique to FILE1
MISSING_REPOS=`/usr/bin/comm -23 ${DIFF_DIR}/repos_gerrit_lowercase ${DIFF_DIR}/repos_gitorious`

# -----------------------------------------------------------------------------
# if the comparison resulted in a file then we have Gitorious repositories to create
if [ "${MISSING_REPOS}" ]; then
    /usr/bin/ssh ${GITORIOUS_USER}@${GITORIOUS} ${CREATE_REPOS} ${MISSING_REPOS} > /dev/null

    # suppressed output earlier so that we can throw it nicely here, for logging purposes
    if [ "$?" -eq "0" ]; then
        /bin/echo -e "\n`/bin/date -Is` :: The following repositories have been created in Gitorious:\n${MISSING_REPOS}"
    fi

    # also trigger the replication for the newly created repositories
    for i in ${MISSING_REPOS}; do
        /bin/grep -i $i ${DIFF_DIR}/repos_gerrit >> ${DIFF_DIR}/repos_missing
    done
    /usr/bin/ssh -p 2222 ${GERRIT_USER}@${GERRIT} gerrit replicate `/bin/cat ${DIFF_DIR}/repos_missing`
fi
