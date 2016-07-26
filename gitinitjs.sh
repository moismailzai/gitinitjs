#!/bin/sh

# gitinitjs - A POSIX-compliant script that bootstraps a directory for new GitHub-based JavaScript projects.
# parsed with http://www.shellcheck.net/ to ensure POSIX-compliance.


##### User Defaults (change these to set project defaults) #####################
AUTHOR_NAME="Your Name"
AUTHOR_EMAIL="your@email.com"
AUTHOR_URL="http://www.yourwebsite.com"
GITHUB_USER_ID="youruserid"
LICENSE_TYPE="mit"
NPM_USER_ID="youruserid"
TARGET_DIRECTORY="${PWD}/"
##### END OF CONFIGURABLE DEFAULTS #############################################


#### Constants

OPTIND=1 # reinitialize getopts variable
OPTERR=1 # ensure getopts variable is set
PROJECT_NAME_INPUT=""
PROJECT_NAME_PARSED=""
PROJECT_DIRECTORY=""
SCRIPTNAME=$(basename "$0")
YEAR=$(date +'%Y')
SUPPORTED_LICENSES=" agpl3 apache2 artistic2 bsd bsd3c eclipse gpl2 gpl3 lgpl2 lgpl3 mit mozilla2 unlicense none "
LICENSE_URL=""


##### Functions

usage ()
{
    echo "
    usage: $SCRIPTNAME [[[-a author_name] [-e author_email] [-g github_user_id] [-l license_type] [-n npm_user_id] [-p project_name] [-t target_directory] [-u author_url]] | [-h]]


                       -a author_name:      the author's name (used to attribute ownership in various files)
                                            (the default value can be configured in \$AUTHOR_NAME and is currently set to \"$AUTHOR_NAME\")

                       -e author_email:     the author's email address (used to set contact information in various files)
                                            (the default value can be configured in \$AUTHOR_EMAIL and is currently set to \"$AUTHOR_EMAIL\")

                       -g github_user_id:   the github.com user id to associate this project with (used to generate links in various files)
                                            (the default value can be configured in \$GITHUB_USER_ID and is currently set to \"$GITHUB_USER_ID\")

                       -l license_type:     the type of license to generate and associate this project with
                                            valid types:$SUPPORTED_LICENSES
                                            (the default value can be configured in \$LICENSE_TYPE and is currently set to \"$LICENSE_TYPE\")

                       -n npm_user_id:      the npmjs.com user id to associate this project with (used to generate links in various files)
                                            (the default value can be configured in \$NPM_USER_ID and is currently set to \"$NPM_USER_ID\")

                       -p project_name:     the project name (used as the project directory name as well)
                                            (the default value is the current directory's name, \"${PWD}\")

                       -t target_directory: the target directory under which the project directory should be created
                                            (the default value can be configured in \$TARGET_DIRECTORY and is currently set to \"$TARGET_DIRECTORY\")

                       -u author_url:       the author's URL (used to set contact information in various files)
                                            (the default value can be configured in \$AUTHOR_URL and is currently set to \"$AUTHOR_URL\")

                       -h:                  display this message
"
} # end of usage

echoerror () # send error messages to standard error
{
  echonicely "$@" 1>&2;
} # end of echoerror

echonicely () # add padding to echo'd messages
{
  echo "
        ${1}
       "
} # end of echonicely

confirm () # based on https://stackoverflow.com/questions/3231804/in-bash-how-to-add-are-you-sure-y-n-to-any-command-or-alias/3232082#3232082
{
  echonicely "${1:-Are you sure? [y/N]}"
  read -r response
  case "$response" in
      [yY][eE][sS]|[yY])
          return 0
          ;;
      *)
          return 1
          ;;
  esac
} # end of confirm

# shellcheck disable=SC2166
string_contains () # black magic: POSIX-compliant string_contains function found at http://stackoverflow.com/a/20460402 # potential portability issue? --> https://github.com/koalaman/shellcheck/wiki/SC2166
{
  [ -z "${2##*$1*}" ] && [ -z "$1" -o -n "$2" ];
} # end of string_contains

generate_directory ()
{
  while [ "${1}" != "" ]
    do
      directory_path="$PROJECT_DIRECTORY/${1}"
      [ -d "$directory_path" ] || mkdir "$directory_path" || echoerror "\"$directory_path\" already exists, skipping."
      shift
  done
} # end of generate_directory

git_init ()
{
  directory_path="$PROJECT_DIRECTORY/.git"
  create_git=true
  if [ -d "$directory_path" ];
    then
      if confirm "A local .git folder already exists in \"$directory_path\", git init anyway? [y/N]";
        then
          create_git=true
        else
          create_git=false
          echoerror "Git repository already exists. Skipping git steps."
      fi
    else
      create_git=true
  fi
  if $create_git;
    then
      cd "$PROJECT_DIRECTORY" || exit
      git init
      git add .
      git commit -m "First commit."
  fi
} # end of git_init

npm_init () # install npm modules used in gulpfile.js and add them ad dev dependencies in package.json
{
  cd "$PROJECT_DIRECTORY" && npm install browserify filesize gulp gulp-filesize gulp-rename gulp-sourcemaps gulp-uglify gulp-util jsdoc lodash.assign mocha rename vinyl-buffer vinyl-source-stream watchify --save-dev
} # end of npm_init

parse_name ()
{
  if [ "$PROJECT_NAME_INPUT" != "" ]; # if a project name was provided to the script
    then
      PROJECT_NAME_PARSED="$(printf '%s' "$PROJECT_NAME_INPUT" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9]//g')" # sanitize the input and use it as the project name
      PROJECT_DIRECTORY="$TARGET_DIRECTORY$PROJECT_NAME_PARSED" # set the project directory based on the $TARGET_DIRECTORY and project name
      if [ "$PROJECT_NAME_PARSED" = "$PROJECT_NAME_INPUT" ]; # ensure the sanitized input matches the original input (so the project we create has the expected name)
        then
          if [ -d "$PROJECT_DIRECTORY" ];
            then
              confirm "Local \"$PROJECT_NAME_PARSED\" directory already exists. Use it anyway? [y/N]" || return 1 && return 0
            else
              mkdir "$PROJECT_DIRECTORY" || return 1 && return 0
          fi
        else
          if confirm "\"$PROJECT_NAME_INPUT\" is not a valid project name. Use \"$PROJECT_NAME_PARSED\" instead? [y/N]";
            then
              mkdir "$PROJECT_DIRECTORY" || return 1 && return 0
            else
              return 1
          fi
      fi
    else
      if confirm "No project name specified. Use the current directory for project \"${PWD##*/}\"? [y/N]";
        then
          PROJECT_NAME_PARSED="${PWD##*/}"
          PROJECT_DIRECTORY="${PWD}/" # set the project directory to the current directory
          return 0
        else
          return 1
      fi
  fi
} # end of parse_name

generate_readme ()
{
  github_url="https://github.com/$GITHUB_USER_ID/$PROJECT_NAME_PARSED"
  github_url_raw_git="https://cdn.rawgit.com/$GITHUB_USER_ID/$PROJECT_NAME_PARSED"
  npm_url="https://www.npmjs.com/package/$PROJECT_NAME_PARSED"
  bower_url="https://bower.io/search/?q=$PROJECT_NAME_PARSED"
  filename="$PROJECT_DIRECTORY/README.md"
  filecontents="# $PROJECT_NAME_PARSED

#### A brief blurb.

## Details

**Current version**: 0.1.0-0
*(expect breaking changes prior to version 1.0)*

**Source code**: [$github_url]($github_url)

**License**: [${LICENSE_URL##*/}]($LICENSE_URL)

**Copyright**: &copy; $YEAR [$AUTHOR_NAME]($AUTHOR_URL) <$AUTHOR_EMAIL>


## Installation

**Standalone**: [regular]($github_url_raw_git)

\`\`\`
code
\`\`\`

**NodeJS**: [npm]($npm_url)

\`npm install $PROJECT_NAME_PARSED\`

**Bower**: [bower]($bower_url)

\`bower install $PROJECT_NAME_PARSED\`


## Dependancies

**lib:** [ ]( )


## What Does It Do?


## Usage:

**case**

// commented example

\`\`\`

\`\`\`
"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_readme

generate_main_js ()
{
  github_url="https://github.com/$GITHUB_USER_ID/$PROJECT_NAME_PARSED"
  github_url_raw_git="https://cdn.rawgit.com/$GITHUB_USER_ID/$PROJECT_NAME_PARSED"
  npm_url="https://www.npmjs.com/package/$PROJECT_NAME_PARSED"
  bower_url="https://bower.io/search/?q=$PROJECT_NAME_PARSED"
  filename="$PROJECT_DIRECTORY/src/main.js"
  filecontents="/*jslint node: true */
/*global module, require*/
'use strict';
/**
 * $PROJECT_NAME_PARSED is a [...] .
 *
 *    Source code...................... $github_url
 *    Reference implementation.........
 *    License.......................... ${LICENSE_URL##*/} ($LICENSE_URL)
 *    Copyright........................ © $YEAR $AUTHOR_NAME <$AUTHOR_EMAIL> ($AUTHOR_URL)
 *
 */

module.exports = $PROJECT_NAME_PARSED;
"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_main_js

generate_gitignore ()
{
  filename="$PROJECT_DIRECTORY/.gitignore"
  filecontents="# Created by https://www.gitignore.io/api/macos,linux,node,bower,intellij

### macOS ###
*.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two \r
Icon


# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk


### Linux ###
*~

# temporary files which can be created if a process still has a handle open of a deleted file
.fuse_hidden*

# KDE directory preferences
.directory

# Linux trash folder which might appear on any partition or disk
.Trash-*


### Node ###
# Logs
logs
*.log
npm-debug.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Directory for instrumented libs generated by jscoverage/JSCover
lib-cov

# Coverage directory used by tools like istanbul
coverage

# nyc test coverage
.nyc_output

# Grunt intermediate storage (http://gruntjs.com/creating-plugins#storing-task-files)
.grunt

# node-waf configuration
.lock-wscript

# Compiled binary addons (http://nodejs.org/api/addons.html)
build/Release

# Dependency directories
node_modules
jspm_packages

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history


### Bower ###
bower_components
.bower-cache
.bower-registry
.bower-tmp


### Intellij ###
# Covers JetBrains IDEs: IntelliJ, RubyMine, PhpStorm, AppCode, PyCharm, CLion, Android Studio and Webstorm
# Reference: https://intellij-support.jetbrains.com/hc/en-us/articles/206544839

# User-specific stuff:
.idea/workspace.xml
.idea/tasks.xml
.idea/dictionaries
.idea/vcs.xml
.idea/jsLibraryMappings.xml

# Sensitive or high-churn files:
.idea/dataSources.ids
.idea/dataSources.xml
.idea/dataSources.local.xml
.idea/sqlDataSources.xml
.idea/dynamic.xml
.idea/uiDesigner.xml

# Gradle:
.idea/gradle.xml
.idea/libraries

# Mongo Explorer plugin:
.idea/mongoSettings.xml

## File-based project format:
*.iws

## Plugin-specific files:

# IntelliJ
/out/

# mpeltonen/sbt-idea plugin
.idea_modules/

# JIRA plugin
atlassian-ide-plugin.xml

# Crashlytics plugin (for Android Studio and IntelliJ)
com_crashlytics_export_strings.xml
crashlytics.properties
crashlytics-build.properties
fabric.properties

### Intellij Patch ###
# Comment Reason: https://github.com/joeblau/gitignore.io/issues/186#issuecomment-215987721

# *.iml
# modules.xml
# .idea/misc.xml
# *.ipr
"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_gitignore

generate_gulpfile ()
{
  filename="$PROJECT_DIRECTORY/gulpfile.js"
  filecontents="/*global require, pipe*/
'use strict';
var assign = require('lodash.assign'),
    buffer = require('vinyl-buffer'),
    browserify = require('browserify'),
    filesize = require('gulp-filesize'),
    gulp = require('gulp'),
    gutil = require('gulp-util'),
    rename = require('gulp-rename'),
    source = require('vinyl-source-stream'),
    sourcemaps = require('gulp-sourcemaps'),
    uglify = require('gulp-uglify'),
    watchify = require('watchify');

var customOpts = {
        entries: ['./src/main.js'],
        standalone: '$PROJECT_NAME_PARSED',
        debug: true
    },
    opts = assign({}, watchify.args, customOpts),
b = watchify(browserify(opts));
b.on('update', bundle); // on any dep update, runs the bundler
b.on('log', gutil.log); // output build logs to terminal

gulp.task('js', bundle); // so you can run \`gulp js\` to build a file
function bundle() {
    return b.bundle()
        // log errors if they happen
        .on('error', gutil.log.bind(gutil, 'Browserify Error'))
        .pipe(source('$PROJECT_NAME_PARSED'))
        // optional, remove if you don't need to buffer file contents
        .pipe(buffer())
        // optional, remove if you dont want sourcemaps
        .pipe(sourcemaps.init({loadMaps: true})) // loads map from browserify file
        // Add transformation tasks to the pipeline here.
        .pipe(sourcemaps.write('./')) // writes .map file
        .pipe(gulp.dest('./'));
}
"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_gulpfile

generate_package_json ()
{
  filename="$PROJECT_DIRECTORY/package.json"
  filecontents="{
  \"name\": \"$PROJECT_NAME_PARSED\",
  \"version\": \"0.1.0-0\",
  \"description\": \"$PROJECT_NAME_PARSED is a [...] .\",
  \"author\": \"$AUTHOR_NAME <$AUTHOR_EMAIL> ($AUTHOR_URL)\",
  \"scripts\": {
    \"build\": \"npm install && gulp js\",
    \"test\": \"echo \\\"Error: no test specified\\\" && exit 1\"
  },
  \"main\": \"src/main.js\",
  \"repository\": {
    \"type\": \"git\",
    \"url\": \"https://github.com/$GITHUB_USER_ID/$PROJECT_NAME_PARSED\"
  },
  \"bugs\": {
    \"url\": \"https://github.com/$GITHUB_USER_ID/$PROJECT_NAME_PARSED/issues\"
  },
  \"keywords\": [
    \" \"
  ],
  \"dependencies\": {
  },
  \"devDependencies\": {
  },
  \"analyze\": true,
  \"license\": \"${LICENSE_URL##*/}\"
}
"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_package_json

generate_bower_json ()
{
  filename="$PROJECT_DIRECTORY/bower.json"
  filecontents="{
  \"name\": \"$PROJECT_NAME_PARSED\",
  \"version\": \"0.1.0-0\",
  \"homepage\": \"https://github.com/$GITHUB_USER_ID/$PROJECT_NAME_PARSED\",
  \"authors\": [
    \"$AUTHOR_NAME <$AUTHOR_EMAIL> ($AUTHOR_URL)\"
  ],
  \"description\": \"$PROJECT_NAME_PARSED is a [...] .\",
  \"main\": \"src/main.js\",
  \"moduleType\": [
    \"amd\",
    \"globals\",
    \"node\"
  ],
  \"keywords\": [
    \"\"
  ],
  \"license\": \"${LICENSE_URL##*/}\",
  \"ignore\": [
    \"**/.*\",
    \"node_modules\",
    \"bower_components\"
  ],
  \"dependencies\": {
  },
  \"devDependencies\": {
  }
}
"
  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_bower_json

generate_license ()
{
  filename=""
  if [ "$LICENSE_TYPE" = "none" ];
    then
      filename="$PROJECT_DIRECTORY/COPYRIGHT"
    else
        if [ "$LICENSE_TYPE" = "unlicense" ];
          then
            filename="$PROJECT_DIRECTORY/UNLICENSE"
          else
            filename="$PROJECT_DIRECTORY/LICENSE"
        fi
  fi
  filecontents=""
  agpl3="                    GNU AFFERO GENERAL PUBLIC LICENSE
                     Version 3, 19 November 2007

Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.

                          Preamble

The GNU Affero General Public License is a free, copyleft license for
software and other kinds of works, specifically designed to ensure
cooperation with the community in the case of network server software.

The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
our General Public Licenses are intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.

When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

Developers that use our General Public Licenses protect your rights
with two steps: (1) assert copyright on the software, and (2) offer
you this License which gives you legal permission to copy, distribute
and/or modify the software.

A secondary benefit of defending all users' freedom is that
improvements made in alternate versions of the program, if they
receive widespread use, become available for other developers to
incorporate.  Many developers of free software are heartened and
encouraged by the resulting cooperation.  However, in the case of
software used on network servers, this result may fail to come about.
The GNU General Public License permits making a modified version and
letting the public access it on a server without ever releasing its
source code to the public.

The GNU Affero General Public License is designed specifically to
ensure that, in such cases, the modified source code becomes available
to the community.  It requires the operator of a network server to
provide the source code of the modified version running there to the
users of that server.  Therefore, public use of a modified version, on
a publicly accessible server, gives the public access to the source
code of the modified version.

An older license, called the Affero General Public License and
published by Affero, was designed to accomplish similar goals.  This is
a different license, not a version of the Affero GPL, but Affero has
released a new version of the Affero GPL which permits relicensing under
this license.

The precise terms and conditions for copying, distribution and
modification follow.

                     TERMS AND CONDITIONS

0. Definitions.

\"This License\" refers to version 3 of the GNU Affero General Public License.

\"Copyright\" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

\"The Program\" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as \"you\".  \"Licensees\" and
\"recipients\" may be individuals or organizations.

To \"modify\" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a \"modified version\" of the
earlier work or a work \"based on\" the earlier work.

A \"covered work\" means either the unmodified Program or a work based
on the Program.

To \"propagate\" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

To \"convey\" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

An interactive user interface displays \"Appropriate Legal Notices\"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

1. Source Code.

The \"source code\" for a work means the preferred form of the work
for making modifications to it.  \"Object code\" means any non-source
form of a work.

A \"Standard Interface\" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

The \"System Libraries\" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
\"Major Component\", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

The \"Corresponding Source\" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

The Corresponding Source for a work in source code form is that
same work.

2. Basic Permissions.

All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

3. Protecting Users' Legal Rights From Anti-Circumvention Law.

No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

4. Conveying Verbatim Copies.

You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

5. Conveying Modified Source Versions.

You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

  a) The work must carry prominent notices stating that you modified
  it, and giving a relevant date.

  b) The work must carry prominent notices stating that it is
  released under this License and any conditions added under section
  7.  This requirement modifies the requirement in section 4 to
  \"keep intact all notices\".

  c) You must license the entire work, as a whole, under this
  License to anyone who comes into possession of a copy.  This
  License will therefore apply, along with any applicable section 7
  additional terms, to the whole of the work, and all its parts,
  regardless of how they are packaged.  This License gives no
  permission to license the work in any other way, but it does not
  invalidate such permission if you have separately received it.

  d) If the work has interactive user interfaces, each must display
  Appropriate Legal Notices; however, if the Program has interactive
  interfaces that do not display Appropriate Legal Notices, your
  work need not make them do so.

A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
\"aggregate\" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

6. Conveying Non-Source Forms.

You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

  a) Convey the object code in, or embodied in, a physical product
  (including a physical distribution medium), accompanied by the
  Corresponding Source fixed on a durable physical medium
  customarily used for software interchange.

  b) Convey the object code in, or embodied in, a physical product
  (including a physical distribution medium), accompanied by a
  written offer, valid for at least three years and valid for as
  long as you offer spare parts or customer support for that product
  model, to give anyone who possesses the object code either (1) a
  copy of the Corresponding Source for all the software in the
  product that is covered by this License, on a durable physical
  medium customarily used for software interchange, for a price no
  more than your reasonable cost of physically performing this
  conveying of source, or (2) access to copy the
  Corresponding Source from a network server at no charge.

  c) Convey individual copies of the object code with a copy of the
  written offer to provide the Corresponding Source.  This
  alternative is allowed only occasionally and noncommercially, and
  only if you received the object code with such an offer, in accord
  with subsection 6b.

  d) Convey the object code by offering access from a designated
  place (gratis or for a charge), and offer equivalent access to the
  Corresponding Source in the same way through the same place at no
  further charge.  You need not require recipients to copy the
  Corresponding Source along with the object code.  If the place to
  copy the object code is a network server, the Corresponding Source
  may be on a different server (operated by you or a third party)
  that supports equivalent copying facilities, provided you maintain
  clear directions next to the object code saying where to find the
  Corresponding Source.  Regardless of what server hosts the
  Corresponding Source, you remain obligated to ensure that it is
  available for as long as needed to satisfy these requirements.

  e) Convey the object code using peer-to-peer transmission, provided
  you inform other peers where the object code and Corresponding
  Source of the work are being offered to the general public at no
  charge under subsection 6d.

A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

A \"User Product\" is either (1) a \"consumer product\", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, \"normally used\" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

\"Installation Information\" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

7. Additional Terms.

\"Additional permissions\" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

  a) Disclaiming warranty or limiting liability differently from the
  terms of sections 15 and 16 of this License; or

  b) Requiring preservation of specified reasonable legal notices or
  author attributions in that material or in the Appropriate Legal
  Notices displayed by works containing it; or

  c) Prohibiting misrepresentation of the origin of that material, or
  requiring that modified versions of such material be marked in
  reasonable ways as different from the original version; or

  d) Limiting the use for publicity purposes of names of licensors or
  authors of the material; or

  e) Declining to grant rights under trademark law for use of some
  trade names, trademarks, or service marks; or

  f) Requiring indemnification of licensors and authors of that
  material by anyone who conveys the material (or modified versions of
  it) with contractual assumptions of liability to the recipient, for
  any liability that these contractual assumptions directly impose on
  those licensors and authors.

All other non-permissive additional terms are considered \"further
restrictions\" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

8. Termination.

You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

9. Acceptance Not Required for Having Copies.

You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

10. Automatic Licensing of Downstream Recipients.

Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

An \"entity transaction\" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

11. Patents.

A \"contributor\" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's \"contributor version\".

A contributor's \"essential patent claims\" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, \"control\" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

In the following three paragraphs, a \"patent license\" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To \"grant\" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  \"Knowingly relying\" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

A patent license is \"discriminatory\" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

12. No Surrender of Others' Freedom.

If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

13. Remote Network Interaction; Use with the GNU General Public License.

Notwithstanding any other provision of this License, if you modify the
Program, your modified version must prominently offer all users
interacting with it remotely through a computer network (if your version
supports such interaction) an opportunity to receive the Corresponding
Source of your version by providing access to the Corresponding Source
from a network server at no charge, through some standard or customary
means of facilitating copying of software.  This Corresponding Source
shall include the Corresponding Source for any work covered by version 3
of the GNU General Public License that is incorporated pursuant to the
following paragraph.

Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the work with which it is combined will remain governed by version
3 of the GNU General Public License.

14. Revised Versions of this License.

The Free Software Foundation may publish revised and/or new versions of
the GNU Affero General Public License from time to time.  Such new versions
will be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU Affero General
Public License \"or any later version\" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU Affero General Public License, you may choose any version ever published
by the Free Software Foundation.

If the Program specifies that a proxy can decide which future
versions of the GNU Affero General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

15. Disclaimer of Warranty.

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

16. Limitation of Liability.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

17. Interpretation of Sections 15 and 16.

If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                   END OF TERMS AND CONDITIONS
" # end of agpl3 license variable

  apache2="                                 Apache License
                         Version 2.0, January 2004
                      http://www.apache.org/licenses/

 TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

 1. Definitions.

    \"License\" shall mean the terms and conditions for use, reproduction,
    and distribution as defined by Sections 1 through 9 of this document.

    \"Licensor\" shall mean the copyright owner or entity authorized by
    the copyright owner that is granting the License.

    \"Legal Entity\" shall mean the union of the acting entity and all
    other entities that control, are controlled by, or are under common
    control with that entity. For the purposes of this definition,
    \"control\" means (i) the power, direct or indirect, to cause the
    direction or management of such entity, whether by contract or
    otherwise, or (ii) ownership of fifty percent (50%) or more of the
    outstanding shares, or (iii) beneficial ownership of such entity.

    \"You\" (or \"Your\") shall mean an individual or Legal Entity
    exercising permissions granted by this License.

    \"Source\" form shall mean the preferred form for making modifications,
    including but not limited to software source code, documentation
    source, and configuration files.

    \"Object\" form shall mean any form resulting from mechanical
    transformation or translation of a Source form, including but
    not limited to compiled object code, generated documentation,
    and conversions to other media types.

    \"Work\" shall mean the work of authorship, whether in Source or
    Object form, made available under the License, as indicated by a
    copyright notice that is included in or attached to the work
    (an example is provided in the Appendix below).

    \"Derivative Works\" shall mean any work, whether in Source or Object
    form, that is based on (or derived from) the Work and for which the
    editorial revisions, annotations, elaborations, or other modifications
    represent, as a whole, an original work of authorship. For the purposes
    of this License, Derivative Works shall not include works that remain
    separable from, or merely link (or bind by name) to the interfaces of,
    the Work and Derivative Works thereof.

    \"Contribution\" shall mean any work of authorship, including
    the original version of the Work and any modifications or additions
    to that Work or Derivative Works thereof, that is intentionally
    submitted to Licensor for inclusion in the Work by the copyright owner
    or by an individual or Legal Entity authorized to submit on behalf of
    the copyright owner. For the purposes of this definition, \"submitted\"
    means any form of electronic, verbal, or written communication sent
    to the Licensor or its representatives, including but not limited to
    communication on electronic mailing lists, source code control systems,
    and issue tracking systems that are managed by, or on behalf of, the
    Licensor for the purpose of discussing and improving the Work, but
    excluding communication that is conspicuously marked or otherwise
    designated in writing by the copyright owner as \"Not a Contribution.\"

    \"Contributor\" shall mean Licensor and any individual or Legal Entity
    on behalf of whom a Contribution has been received by Licensor and
    subsequently incorporated within the Work.

 2. Grant of Copyright License. Subject to the terms and conditions of
    this License, each Contributor hereby grants to You a perpetual,
    worldwide, non-exclusive, no-charge, royalty-free, irrevocable
    copyright license to reproduce, prepare Derivative Works of,
    publicly display, publicly perform, sublicense, and distribute the
    Work and such Derivative Works in Source or Object form.

 3. Grant of Patent License. Subject to the terms and conditions of
    this License, each Contributor hereby grants to You a perpetual,
    worldwide, non-exclusive, no-charge, royalty-free, irrevocable
    (except as stated in this section) patent license to make, have made,
    use, offer to sell, sell, import, and otherwise transfer the Work,
    where such license applies only to those patent claims licensable
    by such Contributor that are necessarily infringed by their
    Contribution(s) alone or by combination of their Contribution(s)
    with the Work to which such Contribution(s) was submitted. If You
    institute patent litigation against any entity (including a
    cross-claim or counterclaim in a lawsuit) alleging that the Work
    or a Contribution incorporated within the Work constitutes direct
    or contributory patent infringement, then any patent licenses
    granted to You under this License for that Work shall terminate
    as of the date such litigation is filed.

 4. Redistribution. You may reproduce and distribute copies of the
    Work or Derivative Works thereof in any medium, with or without
    modifications, and in Source or Object form, provided that You
    meet the following conditions:

    (a) You must give any other recipients of the Work or
        Derivative Works a copy of this License; and

    (b) You must cause any modified files to carry prominent notices
        stating that You changed the files; and

    (c) You must retain, in the Source form of any Derivative Works
        that You distribute, all copyright, patent, trademark, and
        attribution notices from the Source form of the Work,
        excluding those notices that do not pertain to any part of
        the Derivative Works; and

    (d) If the Work includes a \"NOTICE\" text file as part of its
        distribution, then any Derivative Works that You distribute must
        include a readable copy of the attribution notices contained
        within such NOTICE file, excluding those notices that do not
        pertain to any part of the Derivative Works, in at least one
        of the following places: within a NOTICE text file distributed
        as part of the Derivative Works; within the Source form or
        documentation, if provided along with the Derivative Works; or,
        within a display generated by the Derivative Works, if and
        wherever such third-party notices normally appear. The contents
        of the NOTICE file are for informational purposes only and
        do not modify the License. You may add Your own attribution
        notices within Derivative Works that You distribute, alongside
        or as an addendum to the NOTICE text from the Work, provided
        that such additional attribution notices cannot be construed
        as modifying the License.

    You may add Your own copyright statement to Your modifications and
    may provide additional or different license terms and conditions
    for use, reproduction, or distribution of Your modifications, or
    for any such Derivative Works as a whole, provided Your use,
    reproduction, and distribution of the Work otherwise complies with
    the conditions stated in this License.

 5. Submission of Contributions. Unless You explicitly state otherwise,
    any Contribution intentionally submitted for inclusion in the Work
    by You to the Licensor shall be under the terms and conditions of
    this License, without any additional terms or conditions.
    Notwithstanding the above, nothing herein shall supersede or modify
    the terms of any separate license agreement you may have executed
    with Licensor regarding such Contributions.

 6. Trademarks. This License does not grant permission to use the trade
    names, trademarks, service marks, or product names of the Licensor,
    except as required for reasonable and customary use in describing the
    origin of the Work and reproducing the content of the NOTICE file.

 7. Disclaimer of Warranty. Unless required by applicable law or
    agreed to in writing, Licensor provides the Work (and each
    Contributor provides its Contributions) on an \"AS IS\" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
    implied, including, without limitation, any warranties or conditions
    of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
    PARTICULAR PURPOSE. You are solely responsible for determining the
    appropriateness of using or redistributing the Work and assume any
    risks associated with Your exercise of permissions under this License.

 8. Limitation of Liability. In no event and under no legal theory,
    whether in tort (including negligence), contract, or otherwise,
    unless required by applicable law (such as deliberate and grossly
    negligent acts) or agreed to in writing, shall any Contributor be
    liable to You for damages, including any direct, indirect, special,
    incidental, or consequential damages of any character arising as a
    result of this License or out of the use or inability to use the
    Work (including but not limited to damages for loss of goodwill,
    work stoppage, computer failure or malfunction, or any and all
    other commercial damages or losses), even if such Contributor
    has been advised of the possibility of such damages.

 9. Accepting Warranty or Additional Liability. While redistributing
    the Work or Derivative Works thereof, You may choose to offer,
    and charge a fee for, acceptance of support, warranty, indemnity,
    or other liability obligations and/or rights consistent with this
    License. However, in accepting such obligations, You may act only
    on Your own behalf and on Your sole responsibility, not on behalf
    of any other Contributor, and only if You agree to indemnify,
    defend, and hold each Contributor harmless for any liability
    incurred by, or claims asserted against, such Contributor by reason
    of your accepting any such warranty or additional liability.

 END OF TERMS AND CONDITIONS
" # end of apache2 license variable

  artistic2="Artistic License 2.0
Copyright (c) $YEAR $AUTHOR_NAME

Everyone is permitted to copy and distribute verbatim copies of this license
document, but changing it is not allowed.

Preamble
This license establishes the terms under which a given free software Package may
be copied, modified, distributed, and/or redistributed. The intent is that the
Copyright Holder maintains some artistic control over the development of that
Package while still keeping the Package available as open source and free
software.

You are always permitted to make arrangements wholly outside of this license
directly with the Copyright Holder of a given Package. If the terms of this
license do not permit the full use that you propose to make of the Package, you
should contact the Copyright Holder and seek a different licensing arrangement.

Definitions
\"Copyright Holder\" means the individual(s) or organization(s) named in the
copyright notice for the entire Package.

\"Contributor\" means any party that has contributed code or other material to the
Package, in accordance with the Copyright Holder's procedures.

\"You\" and \"your\" means any person who would like to copy, distribute, or modify
the Package.

\"Package\" means the collection of files distributed by the Copyright Holder, and
derivatives of that collection and/or of those files. A given Package may
consist of either the Standard Version, or a Modified Version.

\"Distribute\" means providing a copy of the Package or making it accessible to
anyone else, or in the case of a company or organization, to others outside of
your company or organization.

\"Distributor Fee\" means any fee that you charge for Distributing this Package or
providing support for this Package to another party. It does not mean licensing
fees.

\"Standard Version\" refers to the Package if it has not been modified, or has
been modified only in ways explicitly requested by the Copyright Holder.

\"Modified Version\" means the Package, if it has been changed, and such changes
were not explicitly requested by the Copyright Holder.

\"Original License\" means this Artistic License as Distributed with the Standard
Version of the Package, in its current version or as it may be modified by The
Perl Foundation in the future.

\"Source\" form means the source code, documentation source, and configuration
files for the Package.

\"Compiled\" form means the compiled bytecode, object code, binary, or any other
form resulting from mechanical transformation or translation of the Source form.

Permission for Use and Modification Without Distribution
(1) You are permitted to use the Standard Version and create and use Modified
Versions for any purpose without restriction, provided that you do not
Distribute the Modified Version.

Permissions for Redistribution of the Standard Version
(2) You may Distribute verbatim copies of the Source form of the Standard
Version of this Package in any medium without restriction, either gratis or for
a Distributor Fee, provided that you duplicate all of the original copyright
notices and associated disclaimers. At your discretion, such verbatim copies may
or may not include a Compiled form of the Package.

(3) You may apply any bug fixes, portability changes, and other modifications
made available from the Copyright Holder. The resulting Package will still be
considered the Standard Version, and as such will be subject to the Original
License.

Distribution of Modified Versions of the Package as Source
(4) You may Distribute your Modified Version as Source (either gratis or for a
Distributor Fee, and with or without a Compiled form of the Modified Version)
provided that you clearly document how it differs from the Standard Version,
including, but not limited to, documenting any non-standard features,
executables, or modules, and provided that you do at least ONE of the following:

(a) make the Modified Version available to the Copyright Holder of the Standard
Version, under the Original License, so that the Copyright Holder may include
your modifications in the Standard Version.
(b) ensure that installation of your Modified Version does not prevent the user
installing or running the Standard Version. In addition, the Modified Version
must bear a name that is different from the name of the Standard Version.
(c) allow anyone who receives a copy of the Modified Version to make the Source
form of the Modified Version available to others under
(i) the Original License or
(ii) a license that permits the licensee to freely copy, modify and redistribute
the Modified Version using the same licensing terms that apply to the copy that
the licensee received, and requires that the Source form of the Modified
Version, and of any works derived from it, be made freely available in that
license fees are prohibited but Distributor Fees are allowed.

Distribution of Compiled Forms of the Standard Version or Modified Versions
without the Source
(5) You may Distribute Compiled forms of the Standard Version without the
Source, provided that you include complete instructions on how to get the Source
of the Standard Version. Such instructions must be valid at the time of your
distribution. If these instructions, at any time while you are carrying out such
distribution, become invalid, you must provide new instructions on demand or
cease further distribution. If you provide valid instructions or cease
distribution within thirty days after you become aware that the instructions are
invalid, then you do not forfeit any of your rights under this license.

(6) You may Distribute a Modified Version in Compiled form without the Source,
provided that you comply with Section 4 with respect to the Source of the
Modified Version.

Aggregating or Linking the Package
(7) You may aggregate the Package (either the Standard Version or Modified
Version) with other packages and Distribute the resulting aggregation provided
that you do not charge a licensing fee for the Package. Distributor Fees are
permitted, and licensing fees for other components in the aggregation are
permitted. The terms of this license apply to the use and Distribution of the
Standard or Modified Versions as included in the aggregation.

(8) You are permitted to link Modified and Standard Versions with other works,
to embed the Package in a larger work of your own, or to build stand-alone
binary or bytecode versions of applications that include the Package, and
Distribute the result without restriction, provided the result does not expose a
direct interface to the Package.

Items That are Not Considered Part of a Modified Version

(9) Works (including, but not limited to, modules and scripts) that merely
extend or make use of the Package, do not, by themselves, cause the Package to
be a Modified Version. In addition, such works are not considered parts of the
Package itself, and are not subject to the terms of this license.

General Provisions

(10) Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify, or
distribute the Package, if you do not accept this license.

(11) If your Modified Version has been derived from a Modified Version made by
someone other than you, you are nevertheless required to ensure that your
Modified Version complies with the requirements of this license.

(12) This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

(13) This license includes the non-exclusive, worldwide, free-of-charge patent
license to make, have made, use, offer to sell, sell, import and otherwise
transfer the Package with respect to any patent claims licensable by the
Copyright Holder that are necessarily infringed by the Package. If you institute
patent litigation (including a cross-claim or counterclaim) against any party
alleging that the Package constitutes direct or contributory patent
infringement, then this Artistic License to you shall terminate on the date that
such litigation is filed.

(14) Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS \"AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW.
UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY
OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.
" # end of artistic2 license variable

  bsd="Copyright (c) $YEAR, $AUTHOR_NAME
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" # end of bsd license variable

  bsd3c="Copyright (c) $YEAR, $AUTHOR_NAME
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* Neither the name of the {organization} nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" # end of bsd3c license variable

  eclipse="Eclipse Public License - v 1.0

THE ACCOMPANYING PROGRAM IS PROVIDED UNDER THE TERMS OF THIS ECLIPSE PUBLIC
LICENSE (\"AGREEMENT\"). ANY USE, REPRODUCTION OR DISTRIBUTION OF THE PROGRAM
CONSTITUTES RECIPIENT'S ACCEPTANCE OF THIS AGREEMENT.

1. DEFINITIONS

\"Contribution\" means:

a) in the case of the initial Contributor, the initial code and documentation
 distributed under this Agreement, and
b) in the case of each subsequent Contributor:
  i) changes to the Program, and
 ii) additions to the Program;

 where such changes and/or additions to the Program originate from and are
 distributed by that particular Contributor. A Contribution 'originates' from
 a Contributor if it was added to the Program by such Contributor itself or
 anyone acting on such Contributor's behalf. Contributions do not include
 additions to the Program which: (i) are separate modules of software
 distributed in conjunction with the Program under their own license
 agreement, and (ii) are not derivative works of the Program.

\"Contributor\" means any person or entity that distributes the Program.

\"Licensed Patents\" mean patent claims licensable by a Contributor which are
necessarily infringed by the use or sale of its Contribution alone or when
combined with the Program.

\"Program\" means the Contributions distributed in accordance with this Agreement.

\"Recipient\" means anyone who receives the Program under this Agreement,
including all Contributors.

2. GRANT OF RIGHTS
a) Subject to the terms of this Agreement, each Contributor hereby grants
   Recipient a non-exclusive, worldwide, royalty-free copyright license to
   reproduce, prepare derivative works of, publicly display, publicly perform,
   distribute and sublicense the Contribution of such Contributor, if any, and
   such derivative works, in source code and object code form.
b) Subject to the terms of this Agreement, each Contributor hereby grants
   Recipient a non-exclusive, worldwide, royalty-free patent license under
   Licensed Patents to make, use, sell, offer to sell, import and otherwise
   transfer the Contribution of such Contributor, if any, in source code and
   object code form. This patent license shall apply to the combination of the
   Contribution and the Program if, at the time the Contribution is added by
   the Contributor, such addition of the Contribution causes such combination
   to be covered by the Licensed Patents. The patent license shall not apply
   to any other combinations which include the Contribution. No hardware per
   se is licensed hereunder.
c) Recipient understands that although each Contributor grants the licenses to
   its Contributions set forth herein, no assurances are provided by any
   Contributor that the Program does not infringe the patent or other
   intellectual property rights of any other entity. Each Contributor
   disclaims any liability to Recipient for claims brought by any other entity
   based on infringement of intellectual property rights or otherwise. As a
   condition to exercising the rights and licenses granted hereunder, each
   Recipient hereby assumes sole responsibility to secure any other
   intellectual property rights needed, if any. For example, if a third party
   patent license is required to allow Recipient to distribute the Program, it
   is Recipient's responsibility to acquire that license before distributing
   the Program.
d) Each Contributor represents that to its knowledge it has sufficient
   copyright rights in its Contribution, if any, to grant the copyright
   license set forth in this Agreement.

3. REQUIREMENTS

A Contributor may choose to distribute the Program in object code form under its
own license agreement, provided that:

a) it complies with the terms and conditions of this Agreement; and
b) its license agreement:
    i) effectively disclaims on behalf of all Contributors all warranties and
       conditions, express and implied, including warranties or conditions of
       title and non-infringement, and implied warranties or conditions of
       merchantability and fitness for a particular purpose;
   ii) effectively excludes on behalf of all Contributors all liability for
       damages, including direct, indirect, special, incidental and
       consequential damages, such as lost profits;
  iii) states that any provisions which differ from this Agreement are offered
       by that Contributor alone and not by any other party; and
   iv) states that source code for the Program is available from such
       Contributor, and informs licensees how to obtain it in a reasonable
       manner on or through a medium customarily used for software exchange.

When the Program is made available in source code form:

a) it must be made available under this Agreement; and
b) a copy of this Agreement must be included with each copy of the Program.
   Contributors may not remove or alter any copyright notices contained within
   the Program.

Each Contributor must identify itself as the originator of its Contribution, if
any, in a manner that reasonably allows subsequent Recipients to identify the
originator of the Contribution.

4. COMMERCIAL DISTRIBUTION

Commercial distributors of software may accept certain responsibilities with
respect to end users, business partners and the like. While this license is
intended to facilitate the commercial use of the Program, the Contributor who
includes the Program in a commercial product offering should do so in a manner
which does not create potential liability for other Contributors. Therefore, if
a Contributor includes the Program in a commercial product offering, such
Contributor (\"Commercial Contributor\") hereby agrees to defend and indemnify
every other Contributor (\"Indemnified Contributor\") against any losses, damages
and costs (collectively \"Losses\") arising from claims, lawsuits and other legal
actions brought by a third party against the Indemnified Contributor to the
extent caused by the acts or omissions of such Commercial Contributor in
connection with its distribution of the Program in a commercial product
offering. The obligations in this section do not apply to any claims or Losses
relating to any actual or alleged intellectual property infringement. In order
to qualify, an Indemnified Contributor must: a) promptly notify the Commercial
Contributor in writing of such claim, and b) allow the Commercial Contributor to
control, and cooperate with the Commercial Contributor in, the defense and any
related settlement negotiations. The Indemnified Contributor may participate in
any such claim at its own expense.

For example, a Contributor might include the Program in a commercial product
offering, Product X. That Contributor is then a Commercial Contributor. If that
Commercial Contributor then makes performance claims, or offers warranties
related to Product X, those performance claims and warranties are such
Commercial Contributor's responsibility alone. Under this section, the
Commercial Contributor would have to defend claims against the other
Contributors related to those performance claims and warranties, and if a court
requires any other Contributor to pay any damages as a result, the Commercial
Contributor must pay those damages.

5. NO WARRANTY

EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, THE PROGRAM IS PROVIDED ON AN
\"AS IS\" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF TITLE,
NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. Each
Recipient is solely responsible for determining the appropriateness of using and
distributing the Program and assumes all risks associated with its exercise of
rights under this Agreement , including but not limited to the risks and costs
of program errors, compliance with applicable laws, damage to or loss of data,
programs or equipment, and unavailability or interruption of operations.

6. DISCLAIMER OF LIABILITY

EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, NEITHER RECIPIENT NOR ANY
CONTRIBUTORS SHALL HAVE ANY LIABILITY FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING WITHOUT LIMITATION LOST
PROFITS), HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OR DISTRIBUTION OF THE PROGRAM OR THE EXERCISE OF ANY RIGHTS
GRANTED HEREUNDER, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

7. GENERAL

If any provision of this Agreement is invalid or unenforceable under applicable
law, it shall not affect the validity or enforceability of the remainder of the
terms of this Agreement, and without further action by the parties hereto, such
provision shall be reformed to the minimum extent necessary to make such
provision valid and enforceable.

If Recipient institutes patent litigation against any entity (including a
cross-claim or counterclaim in a lawsuit) alleging that the Program itself
(excluding combinations of the Program with other software or hardware)
infringes such Recipient's patent(s), then such Recipient's rights granted under
Section 2(b) shall terminate as of the date such litigation is filed.

All Recipient's rights under this Agreement shall terminate if it fails to
comply with any of the material terms or conditions of this Agreement and does
not cure such failure in a reasonable period of time after becoming aware of
such noncompliance. If all Recipient's rights under this Agreement terminate,
Recipient agrees to cease use and distribution of the Program as soon as
reasonably practicable. However, Recipient's obligations under this Agreement
and any licenses granted by Recipient relating to the Program shall continue and
survive.

Everyone is permitted to copy and distribute copies of this Agreement, but in
order to avoid inconsistency the Agreement is copyrighted and may only be
modified in the following manner. The Agreement Steward reserves the right to
publish new versions (including revisions) of this Agreement from time to time.
No one other than the Agreement Steward has the right to modify this Agreement.
The Eclipse Foundation is the initial Agreement Steward. The Eclipse Foundation
may assign the responsibility to serve as the Agreement Steward to a suitable
separate entity. Each new version of the Agreement will be given a
distinguishing version number. The Program (including Contributions) may always
be distributed subject to the version of the Agreement under which it was
received. In addition, after a new version of the Agreement is published,
Contributor may elect to distribute the Program (including its Contributions)
under the new version. Except as expressly stated in Sections 2(a) and 2(b)
above, Recipient receives no rights or licenses to the intellectual property of
any Contributor under this Agreement, whether expressly, by implication,
estoppel or otherwise. All rights in the Program not expressly granted under
this Agreement are reserved.

This Agreement is governed by the laws of the State of New York and the
intellectual property laws of the United States of America. No party to this
Agreement will bring a legal action under this Agreement more than one year
after the cause of action arose. Each party waives its rights to a jury trial in
any resulting litigation.
" # end of eclipse license variable

  gpl2="                    GNU GENERAL PUBLIC LICENSE
                     Version 2, June 1991

Copyright (C) 1989, 1991 Free Software Foundation, Inc., <http://fsf.org/>
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.

                          Preamble

The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
License is intended to guarantee your freedom to share and change free
software--to make sure the software is free for all its users.  This
General Public License applies to most of the Free Software
Foundation's software and to any other program whose authors commit to
using it.  (Some other Free Software Foundation software is covered by
the GNU Lesser General Public License instead.)  You can apply it to
your programs, too.

When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
this service if you wish), that you receive source code or can get it
if you want it, that you can change the software or use pieces of it
in new free programs; and that you know you can do these things.

To protect your rights, we need to make restrictions that forbid
anyone to deny you these rights or to ask you to surrender the rights.
These restrictions translate to certain responsibilities for you if you
distribute copies of the software, or if you modify it.

For example, if you distribute copies of such a program, whether
gratis or for a fee, you must give the recipients all the rights that
you have.  You must make sure that they, too, receive or can get the
source code.  And you must show them these terms so they know their
rights.

We protect your rights with two steps: (1) copyright the software, and
(2) offer you this license which gives you legal permission to copy,
distribute and/or modify the software.

Also, for each author's protection and ours, we want to make certain
that everyone understands that there is no warranty for this free
software.  If the software is modified by someone else and passed on, we
want its recipients to know that what they have is not the original, so
that any problems introduced by others will not reflect on the original
authors' reputations.

Finally, any free program is threatened constantly by software
patents.  We wish to avoid the danger that redistributors of a free
program will individually obtain patent licenses, in effect making the
program proprietary.  To prevent this, we have made it clear that any
patent must be licensed for everyone's free use or not licensed at all.

The precise terms and conditions for copying, distribution and
modification follow.

                  GNU GENERAL PUBLIC LICENSE
 TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. This License applies to any program or other work which contains
a notice placed by the copyright holder saying it may be distributed
under the terms of this General Public License.  The \"Program\", below,
refers to any such program or work, and a \"work based on the Program\"
means either the Program or any derivative work under copyright law:
that is to say, a work containing the Program or a portion of it,
either verbatim or with modifications and/or translated into another
language.  (Hereinafter, translation is included without limitation in
the term \"modification\".)  Each licensee is addressed as \"you\".

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running the Program is not restricted, and the output from the Program
is covered only if its contents constitute a work based on the
Program (independent of having been made by running the Program).
Whether that is true depends on what the Program does.

1. You may copy and distribute verbatim copies of the Program's
source code as you receive it, in any medium, provided that you
conspicuously and appropriately publish on each copy an appropriate
copyright notice and disclaimer of warranty; keep intact all the
notices that refer to this License and to the absence of any warranty;
and give any other recipients of the Program a copy of this License
along with the Program.

You may charge a fee for the physical act of transferring a copy, and
you may at your option offer warranty protection in exchange for a fee.

2. You may modify your copy or copies of the Program or any portion
of it, thus forming a work based on the Program, and copy and
distribute such modifications or work under the terms of Section 1
above, provided that you also meet all of these conditions:

  a) You must cause the modified files to carry prominent notices
  stating that you changed the files and the date of any change.

  b) You must cause any work that you distribute or publish, that in
  whole or in part contains or is derived from the Program or any
  part thereof, to be licensed as a whole at no charge to all third
  parties under the terms of this License.

  c) If the modified program normally reads commands interactively
  when run, you must cause it, when started running for such
  interactive use in the most ordinary way, to print or display an
  announcement including an appropriate copyright notice and a
  notice that there is no warranty (or else, saying that you provide
  a warranty) and that users may redistribute the program under
  these conditions, and telling the user how to view a copy of this
  License.  (Exception: if the Program itself is interactive but
  does not normally print such an announcement, your work based on
  the Program is not required to print an announcement.)

These requirements apply to the modified work as a whole.  If
identifiable sections of that work are not derived from the Program,
and can be reasonably considered independent and separate works in
themselves, then this License, and its terms, do not apply to those
sections when you distribute them as separate works.  But when you
distribute the same sections as part of a whole which is a work based
on the Program, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote it.

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Program.

In addition, mere aggregation of another work not based on the Program
with the Program (or with a work based on the Program) on a volume of
a storage or distribution medium does not bring the other work under
the scope of this License.

3. You may copy and distribute the Program (or a work based on it,
under Section 2) in object code or executable form under the terms of
Sections 1 and 2 above provided that you also do one of the following:

  a) Accompany it with the complete corresponding machine-readable
  source code, which must be distributed under the terms of Sections
  1 and 2 above on a medium customarily used for software interchange; or,

  b) Accompany it with a written offer, valid for at least three
  years, to give any third party, for a charge no more than your
  cost of physically performing source distribution, a complete
  machine-readable copy of the corresponding source code, to be
  distributed under the terms of Sections 1 and 2 above on a medium
  customarily used for software interchange; or,

  c) Accompany it with the information you received as to the offer
  to distribute corresponding source code.  (This alternative is
  allowed only for noncommercial distribution and only if you
  received the program in object code or executable form with such
  an offer, in accord with Subsection b above.)

The source code for a work means the preferred form of the work for
making modifications to it.  For an executable work, complete source
code means all the source code for all modules it contains, plus any
associated interface definition files, plus the scripts used to
control compilation and installation of the executable.  However, as a
special exception, the source code distributed need not include
anything that is normally distributed (in either source or binary
form) with the major components (compiler, kernel, and so on) of the
operating system on which the executable runs, unless that component
itself accompanies the executable.

If distribution of executable or object code is made by offering
access to copy from a designated place, then offering equivalent
access to copy the source code from the same place counts as
distribution of the source code, even though third parties are not
compelled to copy the source along with the object code.

4. You may not copy, modify, sublicense, or distribute the Program
except as expressly provided under this License.  Any attempt
otherwise to copy, modify, sublicense or distribute the Program is
void, and will automatically terminate your rights under this License.
However, parties who have received copies, or rights, from you under
this License will not have their licenses terminated so long as such
parties remain in full compliance.

5. You are not required to accept this License, since you have not
signed it.  However, nothing else grants you permission to modify or
distribute the Program or its derivative works.  These actions are
prohibited by law if you do not accept this License.  Therefore, by
modifying or distributing the Program (or any work based on the
Program), you indicate your acceptance of this License to do so, and
all its terms and conditions for copying, distributing or modifying
the Program or works based on it.

6. Each time you redistribute the Program (or any work based on the
Program), the recipient automatically receives a license from the
original licensor to copy, distribute or modify the Program subject to
these terms and conditions.  You may not impose any further
restrictions on the recipients' exercise of the rights granted herein.
You are not responsible for enforcing compliance by third parties to
this License.

7. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot
distribute so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you
may not distribute the Program at all.  For example, if a patent
license would not permit royalty-free redistribution of the Program by
all those who receive copies directly or indirectly through you, then
the only way you could satisfy both it and this License would be to
refrain entirely from distribution of the Program.

If any portion of this section is held invalid or unenforceable under
any particular circumstance, the balance of the section is intended to
apply and the section as a whole is intended to apply in other
circumstances.

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system, which is
implemented by public license practices.  Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is believed to
be a consequence of the rest of this License.

8. If the distribution and/or use of the Program is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Program under this License
may add an explicit geographical distribution limitation excluding
those countries, so that distribution is permitted only in or among
countries not thus excluded.  In such case, this License incorporates
the limitation as if written in the body of this License.

9. The Free Software Foundation may publish revised and/or new versions
of the General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the Program
specifies a version number of this License which applies to it and \"any
later version\", you have the option of following the terms and conditions
either of that version or of any later version published by the Free
Software Foundation.  If the Program does not specify a version number of
this License, you may choose any version ever published by the Free Software
Foundation.

10. If you wish to incorporate parts of the Program into other free
programs whose distribution conditions are different, write to the author
to ask for permission.  For software which is copyrighted by the Free
Software Foundation, write to the Free Software Foundation; we sometimes
make exceptions for this.  Our decision will be guided by the two goals
of preserving the free status of all derivatives of our free software and
of promoting the sharing and reuse of software generally.

                          NO WARRANTY

11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.  EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED
OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE RISK AS
TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU.  SHOULD THE
PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR OR CORRECTION.

12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED
TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY
YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER
PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

                   END OF TERMS AND CONDITIONS
" # end of gpl2 license variable

  gpl3="                    GNU GENERAL PUBLIC LICENSE
                     Version 3, 29 June 2007

Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.

                          Preamble

The GNU General Public License is a free, copyleft license for
software and other kinds of works.

The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

The precise terms and conditions for copying, distribution and
modification follow.

                     TERMS AND CONDITIONS

0. Definitions.

\"This License\" refers to version 3 of the GNU General Public License.

\"Copyright\" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

\"The Program\" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as \"you\".  \"Licensees\" and
\"recipients\" may be individuals or organizations.

To \"modify\" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a \"modified version\" of the
earlier work or a work \"based on\" the earlier work.

A \"covered work\" means either the unmodified Program or a work based
on the Program.

To \"propagate\" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

To \"convey\" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

An interactive user interface displays \"Appropriate Legal Notices\"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

1. Source Code.

The \"source code\" for a work means the preferred form of the work
for making modifications to it.  \"Object code\" means any non-source
form of a work.

A \"Standard Interface\" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

The \"System Libraries\" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
\"Major Component\", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

The \"Corresponding Source\" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

The Corresponding Source for a work in source code form is that
same work.

2. Basic Permissions.

All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

3. Protecting Users' Legal Rights From Anti-Circumvention Law.

No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

4. Conveying Verbatim Copies.

You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

5. Conveying Modified Source Versions.

You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

  a) The work must carry prominent notices stating that you modified
  it, and giving a relevant date.

  b) The work must carry prominent notices stating that it is
  released under this License and any conditions added under section
  7.  This requirement modifies the requirement in section 4 to
  \"keep intact all notices\".

  c) You must license the entire work, as a whole, under this
  License to anyone who comes into possession of a copy.  This
  License will therefore apply, along with any applicable section 7
  additional terms, to the whole of the work, and all its parts,
  regardless of how they are packaged.  This License gives no
  permission to license the work in any other way, but it does not
  invalidate such permission if you have separately received it.

  d) If the work has interactive user interfaces, each must display
  Appropriate Legal Notices; however, if the Program has interactive
  interfaces that do not display Appropriate Legal Notices, your
  work need not make them do so.

A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
\"aggregate\" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

6. Conveying Non-Source Forms.

You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

  a) Convey the object code in, or embodied in, a physical product
  (including a physical distribution medium), accompanied by the
  Corresponding Source fixed on a durable physical medium
  customarily used for software interchange.

  b) Convey the object code in, or embodied in, a physical product
  (including a physical distribution medium), accompanied by a
  written offer, valid for at least three years and valid for as
  long as you offer spare parts or customer support for that product
  model, to give anyone who possesses the object code either (1) a
  copy of the Corresponding Source for all the software in the
  product that is covered by this License, on a durable physical
  medium customarily used for software interchange, for a price no
  more than your reasonable cost of physically performing this
  conveying of source, or (2) access to copy the
  Corresponding Source from a network server at no charge.

  c) Convey individual copies of the object code with a copy of the
  written offer to provide the Corresponding Source.  This
  alternative is allowed only occasionally and noncommercially, and
  only if you received the object code with such an offer, in accord
  with subsection 6b.

  d) Convey the object code by offering access from a designated
  place (gratis or for a charge), and offer equivalent access to the
  Corresponding Source in the same way through the same place at no
  further charge.  You need not require recipients to copy the
  Corresponding Source along with the object code.  If the place to
  copy the object code is a network server, the Corresponding Source
  may be on a different server (operated by you or a third party)
  that supports equivalent copying facilities, provided you maintain
  clear directions next to the object code saying where to find the
  Corresponding Source.  Regardless of what server hosts the
  Corresponding Source, you remain obligated to ensure that it is
  available for as long as needed to satisfy these requirements.

  e) Convey the object code using peer-to-peer transmission, provided
  you inform other peers where the object code and Corresponding
  Source of the work are being offered to the general public at no
  charge under subsection 6d.

A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

A \"User Product\" is either (1) a \"consumer product\", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, \"normally used\" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

\"Installation Information\" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

7. Additional Terms.

\"Additional permissions\" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

  a) Disclaiming warranty or limiting liability differently from the
  terms of sections 15 and 16 of this License; or

  b) Requiring preservation of specified reasonable legal notices or
  author attributions in that material or in the Appropriate Legal
  Notices displayed by works containing it; or

  c) Prohibiting misrepresentation of the origin of that material, or
  requiring that modified versions of such material be marked in
  reasonable ways as different from the original version; or

  d) Limiting the use for publicity purposes of names of licensors or
  authors of the material; or

  e) Declining to grant rights under trademark law for use of some
  trade names, trademarks, or service marks; or

  f) Requiring indemnification of licensors and authors of that
  material by anyone who conveys the material (or modified versions of
  it) with contractual assumptions of liability to the recipient, for
  any liability that these contractual assumptions directly impose on
  those licensors and authors.

All other non-permissive additional terms are considered \"further
restrictions\" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

8. Termination.

You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

9. Acceptance Not Required for Having Copies.

You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

10. Automatic Licensing of Downstream Recipients.

Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

An \"entity transaction\" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

11. Patents.

A \"contributor\" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's \"contributor version\".

A contributor's \"essential patent claims\" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, \"control\" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

In the following three paragraphs, a \"patent license\" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To \"grant\" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  \"Knowingly relying\" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

A patent license is \"discriminatory\" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

12. No Surrender of Others' Freedom.

If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

13. Use with the GNU Affero General Public License.

Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

14. Revised Versions of this License.

The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License \"or any later version\" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

15. Disclaimer of Warranty.

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM \"AS IS\" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

16. Limitation of Liability.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

17. Interpretation of Sections 15 and 16.

If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                   END OF TERMS AND CONDITIONS
" # end of gpl3 license variable

  lgpl2="                  GNU LESSER GENERAL PUBLIC LICENSE
                     Version 2.1, February 1999

Copyright (C) 1991, 1999 Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.

(This is the first released version of the Lesser GPL.  It also counts
as the successor of the GNU Library Public License, version 2, hence
the version number 2.1.)

                          Preamble

The licenses for most software are designed to take away your
freedom to share and change it.  By contrast, the GNU General Public
Licenses are intended to guarantee your freedom to share and change
free software--to make sure the software is free for all its users.

This license, the Lesser General Public License, applies to some
specially designated software packages--typically libraries--of the
Free Software Foundation and other authors who decide to use it.  You
can use it too, but we suggest you first think carefully about whether
this license or the ordinary General Public License is the better
strategy to use in any particular case, based on the explanations below.

When we speak of free software, we are referring to freedom of use,
not price.  Our General Public Licenses are designed to make sure that
you have the freedom to distribute copies of free software (and charge
for this service if you wish); that you receive source code or can get
it if you want it; that you can change the software and use pieces of
it in new free programs; and that you are informed that you can do
these things.

To protect your rights, we need to make restrictions that forbid
distributors to deny you these rights or to ask you to surrender these
rights.  These restrictions translate to certain responsibilities for
you if you distribute copies of the library or if you modify it.

For example, if you distribute copies of the library, whether gratis
or for a fee, you must give the recipients all the rights that we gave
you.  You must make sure that they, too, receive or can get the source
code.  If you link other code with the library, you must provide
complete object files to the recipients, so that they can relink them
with the library after making changes to the library and recompiling
it.  And you must show them these terms so they know their rights.

We protect your rights with a two-step method: (1) we copyright the
library, and (2) we offer you this license, which gives you legal
permission to copy, distribute and/or modify the library.

To protect each distributor, we want to make it very clear that
there is no warranty for the free library.  Also, if the library is
modified by someone else and passed on, the recipients should know
that what they have is not the original version, so that the original
author's reputation will not be affected by problems that might be
introduced by others.

Finally, software patents pose a constant threat to the existence of
any free program.  We wish to make sure that a company cannot
effectively restrict the users of a free program by obtaining a
restrictive license from a patent holder.  Therefore, we insist that
any patent license obtained for a version of the library must be
consistent with the full freedom of use specified in this license.

Most GNU software, including some libraries, is covered by the
ordinary GNU General Public License.  This license, the GNU Lesser
General Public License, applies to certain designated libraries, and
is quite different from the ordinary General Public License.  We use
this license for certain libraries in order to permit linking those
libraries into non-free programs.

When a program is linked with a library, whether statically or using
a shared library, the combination of the two is legally speaking a
combined work, a derivative of the original library.  The ordinary
General Public License therefore permits such linking only if the
entire combination fits its criteria of freedom.  The Lesser General
Public License permits more lax criteria for linking other code with
the library.

We call this license the \"Lesser\" General Public License because it
does Less to protect the user's freedom than the ordinary General
Public License.  It also provides other free software developers Less
of an advantage over competing non-free programs.  These disadvantages
are the reason we use the ordinary General Public License for many
libraries.  However, the Lesser license provides advantages in certain
special circumstances.

For example, on rare occasions, there may be a special need to
encourage the widest possible use of a certain library, so that it becomes
a de-facto standard.  To achieve this, non-free programs must be
allowed to use the library.  A more frequent case is that a free
library does the same job as widely used non-free libraries.  In this
case, there is little to gain by limiting the free library to free
software only, so we use the Lesser General Public License.

In other cases, permission to use a particular library in non-free
programs enables a greater number of people to use a large body of
free software.  For example, permission to use the GNU C Library in
non-free programs enables many more people to use the whole GNU
operating system, as well as its variant, the GNU/Linux operating
system.

Although the Lesser General Public License is Less protective of the
users' freedom, it does ensure that the user of a program that is
linked with the Library has the freedom and the wherewithal to run
that program using a modified version of the Library.

The precise terms and conditions for copying, distribution and
modification follow.  Pay close attention to the difference between a
\"work based on the library\" and a \"work that uses the library\".  The
former contains code derived from the library, whereas the latter must
be combined with the library in order to run.

                GNU LESSER GENERAL PUBLIC LICENSE
 TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. This License Agreement applies to any software library or other
program which contains a notice placed by the copyright holder or
other authorized party saying it may be distributed under the terms of
this Lesser General Public License (also called \"this License\").
Each licensee is addressed as \"you\".

A \"library\" means a collection of software functions and/or data
prepared so as to be conveniently linked with application programs
(which use some of those functions and data) to form executables.

The \"Library\", below, refers to any such software library or work
which has been distributed under these terms.  A \"work based on the
Library\" means either the Library or any derivative work under
copyright law: that is to say, a work containing the Library or a
portion of it, either verbatim or with modifications and/or translated
straightforwardly into another language.  (Hereinafter, translation is
included without limitation in the term \"modification\".)

\"Source code\" for a work means the preferred form of the work for
making modifications to it.  For a library, complete source code means
all the source code for all modules it contains, plus any associated
interface definition files, plus the scripts used to control compilation
and installation of the library.

Activities other than copying, distribution and modification are not
covered by this License; they are outside its scope.  The act of
running a program using the Library is not restricted, and output from
such a program is covered only if its contents constitute a work based
on the Library (independent of the use of the Library in a tool for
writing it).  Whether that is true depends on what the Library does
and what the program that uses the Library does.

1. You may copy and distribute verbatim copies of the Library's
complete source code as you receive it, in any medium, provided that
you conspicuously and appropriately publish on each copy an
appropriate copyright notice and disclaimer of warranty; keep intact
all the notices that refer to this License and to the absence of any
warranty; and distribute a copy of this License along with the
Library.

You may charge a fee for the physical act of transferring a copy,
and you may at your option offer warranty protection in exchange for a
fee.

2. You may modify your copy or copies of the Library or any portion
of it, thus forming a work based on the Library, and copy and
distribute such modifications or work under the terms of Section 1
above, provided that you also meet all of these conditions:

  a) The modified work must itself be a software library.

  b) You must cause the files modified to carry prominent notices
  stating that you changed the files and the date of any change.

  c) You must cause the whole of the work to be licensed at no
  charge to all third parties under the terms of this License.

  d) If a facility in the modified Library refers to a function or a
  table of data to be supplied by an application program that uses
  the facility, other than as an argument passed when the facility
  is invoked, then you must make a good faith effort to ensure that,
  in the event an application does not supply such function or
  table, the facility still operates, and performs whatever part of
  its purpose remains meaningful.

  (For example, a function in a library to compute square roots has
  a purpose that is entirely well-defined independent of the
  application.  Therefore, Subsection 2d requires that any
  application-supplied function or table used by this function must
  be optional: if the application does not supply it, the square
  root function must still compute square roots.)

These requirements apply to the modified work as a whole.  If
identifiable sections of that work are not derived from the Library,
and can be reasonably considered independent and separate works in
themselves, then this License, and its terms, do not apply to those
sections when you distribute them as separate works.  But when you
distribute the same sections as part of a whole which is a work based
on the Library, the distribution of the whole must be on the terms of
this License, whose permissions for other licensees extend to the
entire whole, and thus to each and every part regardless of who wrote
it.

Thus, it is not the intent of this section to claim rights or contest
your rights to work written entirely by you; rather, the intent is to
exercise the right to control the distribution of derivative or
collective works based on the Library.

In addition, mere aggregation of another work not based on the Library
with the Library (or with a work based on the Library) on a volume of
a storage or distribution medium does not bring the other work under
the scope of this License.

3. You may opt to apply the terms of the ordinary GNU General Public
License instead of this License to a given copy of the Library.  To do
this, you must alter all the notices that refer to this License, so
that they refer to the ordinary GNU General Public License, version 2,
instead of to this License.  (If a newer version than version 2 of the
ordinary GNU General Public License has appeared, then you can specify
that version instead if you wish.)  Do not make any other change in
these notices.

Once this change is made in a given copy, it is irreversible for
that copy, so the ordinary GNU General Public License applies to all
subsequent copies and derivative works made from that copy.

This option is useful when you wish to copy part of the code of
the Library into a program that is not a library.

4. You may copy and distribute the Library (or a portion or
derivative of it, under Section 2) in object code or executable form
under the terms of Sections 1 and 2 above provided that you accompany
it with the complete corresponding machine-readable source code, which
must be distributed under the terms of Sections 1 and 2 above on a
medium customarily used for software interchange.

If distribution of object code is made by offering access to copy
from a designated place, then offering equivalent access to copy the
source code from the same place satisfies the requirement to
distribute the source code, even though third parties are not
compelled to copy the source along with the object code.

5. A program that contains no derivative of any portion of the
Library, but is designed to work with the Library by being compiled or
linked with it, is called a \"work that uses the Library\".  Such a
work, in isolation, is not a derivative work of the Library, and
therefore falls outside the scope of this License.

However, linking a \"work that uses the Library\" with the Library
creates an executable that is a derivative of the Library (because it
contains portions of the Library), rather than a \"work that uses the
library\".  The executable is therefore covered by this License.
Section 6 states terms for distribution of such executables.

When a \"work that uses the Library\" uses material from a header file
that is part of the Library, the object code for the work may be a
derivative work of the Library even though the source code is not.
Whether this is true is especially significant if the work can be
linked without the Library, or if the work is itself a library.  The
threshold for this to be true is not precisely defined by law.

If such an object file uses only numerical parameters, data
structure layouts and accessors, and small macros and small inline
functions (ten lines or less in length), then the use of the object
file is unrestricted, regardless of whether it is legally a derivative
work.  (Executables containing this object code plus portions of the
Library will still fall under Section 6.)

Otherwise, if the work is a derivative of the Library, you may
distribute the object code for the work under the terms of Section 6.
Any executables containing that work also fall under Section 6,
whether or not they are linked directly with the Library itself.

6. As an exception to the Sections above, you may also combine or
link a \"work that uses the Library\" with the Library to produce a
work containing portions of the Library, and distribute that work
under terms of your choice, provided that the terms permit
modification of the work for the customer's own use and reverse
engineering for debugging such modifications.

You must give prominent notice with each copy of the work that the
Library is used in it and that the Library and its use are covered by
this License.  You must supply a copy of this License.  If the work
during execution displays copyright notices, you must include the
copyright notice for the Library among them, as well as a reference
directing the user to the copy of this License.  Also, you must do one
of these things:

  a) Accompany the work with the complete corresponding
  machine-readable source code for the Library including whatever
  changes were used in the work (which must be distributed under
  Sections 1 and 2 above); and, if the work is an executable linked
  with the Library, with the complete machine-readable \"work that
  uses the Library\", as object code and/or source code, so that the
  user can modify the Library and then relink to produce a modified
  executable containing the modified Library.  (It is understood
  that the user who changes the contents of definitions files in the
  Library will not necessarily be able to recompile the application
  to use the modified definitions.)

  b) Use a suitable shared library mechanism for linking with the
  Library.  A suitable mechanism is one that (1) uses at run time a
  copy of the library already present on the user's computer system,
  rather than copying library functions into the executable, and (2)
  will operate properly with a modified version of the library, if
  the user installs one, as long as the modified version is
  interface-compatible with the version that the work was made with.

  c) Accompany the work with a written offer, valid for at
  least three years, to give the same user the materials
  specified in Subsection 6a, above, for a charge no more
  than the cost of performing this distribution.

  d) If distribution of the work is made by offering access to copy
  from a designated place, offer equivalent access to copy the above
  specified materials from the same place.

  e) Verify that the user has already received a copy of these
  materials or that you have already sent this user a copy.

For an executable, the required form of the \"work that uses the
Library\" must include any data and utility programs needed for
reproducing the executable from it.  However, as a special exception,
the materials to be distributed need not include anything that is
normally distributed (in either source or binary form) with the major
components (compiler, kernel, and so on) of the operating system on
which the executable runs, unless that component itself accompanies
the executable.

It may happen that this requirement contradicts the license
restrictions of other proprietary libraries that do not normally
accompany the operating system.  Such a contradiction means you cannot
use both them and the Library together in an executable that you
distribute.

7. You may place library facilities that are a work based on the
Library side-by-side in a single library together with other library
facilities not covered by this License, and distribute such a combined
library, provided that the separate distribution of the work based on
the Library and of the other library facilities is otherwise
permitted, and provided that you do these two things:

  a) Accompany the combined library with a copy of the same work
  based on the Library, uncombined with any other library
  facilities.  This must be distributed under the terms of the
  Sections above.

  b) Give prominent notice with the combined library of the fact
  that part of it is a work based on the Library, and explaining
  where to find the accompanying uncombined form of the same work.

8. You may not copy, modify, sublicense, link with, or distribute
the Library except as expressly provided under this License.  Any
attempt otherwise to copy, modify, sublicense, link with, or
distribute the Library is void, and will automatically terminate your
rights under this License.  However, parties who have received copies,
or rights, from you under this License will not have their licenses
terminated so long as such parties remain in full compliance.

9. You are not required to accept this License, since you have not
signed it.  However, nothing else grants you permission to modify or
distribute the Library or its derivative works.  These actions are
prohibited by law if you do not accept this License.  Therefore, by
modifying or distributing the Library (or any work based on the
Library), you indicate your acceptance of this License to do so, and
all its terms and conditions for copying, distributing or modifying
the Library or works based on it.

10. Each time you redistribute the Library (or any work based on the
Library), the recipient automatically receives a license from the
original licensor to copy, distribute, link with or modify the Library
subject to these terms and conditions.  You may not impose any further
restrictions on the recipients' exercise of the rights granted herein.
You are not responsible for enforcing compliance by third parties with
this License.

11. If, as a consequence of a court judgment or allegation of patent
infringement or for any other reason (not limited to patent issues),
conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot
distribute so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you
may not distribute the Library at all.  For example, if a patent
license would not permit royalty-free redistribution of the Library by
all those who receive copies directly or indirectly through you, then
the only way you could satisfy both it and this License would be to
refrain entirely from distribution of the Library.

If any portion of this section is held invalid or unenforceable under any
particular circumstance, the balance of the section is intended to apply,
and the section as a whole is intended to apply in other circumstances.

It is not the purpose of this section to induce you to infringe any
patents or other property right claims or to contest validity of any
such claims; this section has the sole purpose of protecting the
integrity of the free software distribution system which is
implemented by public license practices.  Many people have made
generous contributions to the wide range of software distributed
through that system in reliance on consistent application of that
system; it is up to the author/donor to decide if he or she is willing
to distribute software through any other system and a licensee cannot
impose that choice.

This section is intended to make thoroughly clear what is believed to
be a consequence of the rest of this License.

12. If the distribution and/or use of the Library is restricted in
certain countries either by patents or by copyrighted interfaces, the
original copyright holder who places the Library under this License may add
an explicit geographical distribution limitation excluding those countries,
so that distribution is permitted only in or among countries not thus
excluded.  In such case, this License incorporates the limitation as if
written in the body of this License.

13. The Free Software Foundation may publish revised and/or new
versions of the Lesser General Public License from time to time.
Such new versions will be similar in spirit to the present version,
but may differ in detail to address new problems or concerns.

Each version is given a distinguishing version number.  If the Library
specifies a version number of this License which applies to it and
\"any later version\", you have the option of following the terms and
conditions either of that version or of any later version published by
the Free Software Foundation.  If the Library does not specify a
license version number, you may choose any version ever published by
the Free Software Foundation.

14. If you wish to incorporate parts of the Library into other free
programs whose distribution conditions are incompatible with these,
write to the author to ask for permission.  For software which is
copyrighted by the Free Software Foundation, write to the Free
Software Foundation; we sometimes make exceptions for this.  Our
decision will be guided by the two goals of preserving the free status
of all derivatives of our free software and of promoting the sharing
and reuse of software generally.

                          NO WARRANTY

15. BECAUSE THE LIBRARY IS LICENSED FREE OF CHARGE, THERE IS NO
WARRANTY FOR THE LIBRARY, TO THE EXTENT PERMITTED BY APPLICABLE LAW.
EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR
OTHER PARTIES PROVIDE THE LIBRARY \"AS IS\" WITHOUT WARRANTY OF ANY
KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
LIBRARY IS WITH YOU.  SHOULD THE LIBRARY PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

16. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN
WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY
AND/OR REDISTRIBUTE THE LIBRARY AS PERMITTED ABOVE, BE LIABLE TO YOU
FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
LIBRARY (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE LIBRARY TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

                   END OF TERMS AND CONDITIONS
" # end of lgpl2 license variable

  lgpl3="                   GNU LESSER GENERAL PUBLIC LICENSE
                     Version 3, 29 June 2007

Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
Everyone is permitted to copy and distribute verbatim copies
of this license document, but changing it is not allowed.


This version of the GNU Lesser General Public License incorporates
the terms and conditions of version 3 of the GNU General Public
License, supplemented by the additional permissions listed below.

0. Additional Definitions.

As used herein, \"this License\" refers to version 3 of the GNU Lesser
General Public License, and the \"GNU GPL\" refers to version 3 of the GNU
General Public License.

\"The Library\" refers to a covered work governed by this License,
other than an Application or a Combined Work as defined below.

An \"Application\" is any work that makes use of an interface provided
by the Library, but which is not otherwise based on the Library.
Defining a subclass of a class defined by the Library is deemed a mode
of using an interface provided by the Library.

A \"Combined Work\" is a work produced by combining or linking an
Application with the Library.  The particular version of the Library
with which the Combined Work was made is also called the \"Linked
Version\".

The \"Minimal Corresponding Source\" for a Combined Work means the
Corresponding Source for the Combined Work, excluding any source code
for portions of the Combined Work that, considered in isolation, are
based on the Application, and not on the Linked Version.

The \"Corresponding Application Code\" for a Combined Work means the
object code and/or source code for the Application, including any data
and utility programs needed for reproducing the Combined Work from the
Application, but excluding the System Libraries of the Combined Work.

1. Exception to Section 3 of the GNU GPL.

You may convey a covered work under sections 3 and 4 of this License
without being bound by section 3 of the GNU GPL.

2. Conveying Modified Versions.

If you modify a copy of the Library, and, in your modifications, a
facility refers to a function or data to be supplied by an Application
that uses the facility (other than as an argument passed when the
facility is invoked), then you may convey a copy of the modified
version:

 a) under this License, provided that you make a good faith effort to
 ensure that, in the event an Application does not supply the
 function or data, the facility still operates, and performs
 whatever part of its purpose remains meaningful, or

 b) under the GNU GPL, with none of the additional permissions of
 this License applicable to that copy.

3. Object Code Incorporating Material from Library Header Files.

The object code form of an Application may incorporate material from
a header file that is part of the Library.  You may convey such object
code under terms of your choice, provided that, if the incorporated
material is not limited to numerical parameters, data structure
layouts and accessors, or small macros, inline functions and templates
(ten or fewer lines in length), you do both of the following:

 a) Give prominent notice with each copy of the object code that the
 Library is used in it and that the Library and its use are
 covered by this License.

 b) Accompany the object code with a copy of the GNU GPL and this license
 document.

4. Combined Works.

You may convey a Combined Work under terms of your choice that,
taken together, effectively do not restrict modification of the
portions of the Library contained in the Combined Work and reverse
engineering for debugging such modifications, if you also do each of
the following:

 a) Give prominent notice with each copy of the Combined Work that
 the Library is used in it and that the Library and its use are
 covered by this License.

 b) Accompany the Combined Work with a copy of the GNU GPL and this license
 document.

 c) For a Combined Work that displays copyright notices during
 execution, include the copyright notice for the Library among
 these notices, as well as a reference directing the user to the
 copies of the GNU GPL and this license document.

 d) Do one of the following:

     0) Convey the Minimal Corresponding Source under the terms of this
     License, and the Corresponding Application Code in a form
     suitable for, and under terms that permit, the user to
     recombine or relink the Application with a modified version of
     the Linked Version to produce a modified Combined Work, in the
     manner specified by section 6 of the GNU GPL for conveying
     Corresponding Source.

     1) Use a suitable shared library mechanism for linking with the
     Library.  A suitable mechanism is one that (a) uses at run time
     a copy of the Library already present on the user's computer
     system, and (b) will operate properly with a modified version
     of the Library that is interface-compatible with the Linked
     Version.

 e) Provide Installation Information, but only if you would otherwise
 be required to provide such information under section 6 of the
 GNU GPL, and only to the extent that such information is
 necessary to install and execute a modified version of the
 Combined Work produced by recombining or relinking the
 Application with a modified version of the Linked Version. (If
 you use option 4d0, the Installation Information must accompany
 the Minimal Corresponding Source and Corresponding Application
 Code. If you use option 4d1, you must provide the Installation
 Information in the manner specified by section 6 of the GNU GPL
 for conveying Corresponding Source.)

5. Combined Libraries.

You may place library facilities that are a work based on the
Library side by side in a single library together with other library
facilities that are not Applications and are not covered by this
License, and convey such a combined library under terms of your
choice, if you do both of the following:

 a) Accompany the combined library with a copy of the same work based
 on the Library, uncombined with any other library facilities,
 conveyed under the terms of this License.

 b) Give prominent notice with the combined library that part of it
 is a work based on the Library, and explaining where to find the
 accompanying uncombined form of the same work.

6. Revised Versions of the GNU Lesser General Public License.

The Free Software Foundation may publish revised and/or new versions
of the GNU Lesser General Public License from time to time. Such new
versions will be similar in spirit to the present version, but may
differ in detail to address new problems or concerns.

Each version is given a distinguishing version number. If the
Library as you received it specifies that a certain numbered version
of the GNU Lesser General Public License \"or any later version\"
applies to it, you have the option of following the terms and
conditions either of that published version or of any later version
published by the Free Software Foundation. If the Library as you
received it does not specify a version number of the GNU Lesser
General Public License, you may choose any version of the GNU Lesser
General Public License ever published by the Free Software Foundation.

If the Library as you received it specifies that a proxy can decide
whether future versions of the GNU Lesser General Public License shall
apply, that proxy's public statement of acceptance of any version is
permanent authorization for you to choose that version for the
Library.
" # end of lgpl3 license variable

  mit="The MIT License (MIT)

Copyright (c) $YEAR $AUTHOR_NAME

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
" # end of mit license variable

  mozilla2="Mozilla Public License, version 2.0

1. Definitions

1.1. \"Contributor\"

   means each individual or legal entity that creates, contributes to the
   creation of, or owns Covered Software.

1.2. \"Contributor Version\"

   means the combination of the Contributions of others (if any) used by a
   Contributor and that particular Contributor’s Contribution.

1.3. \"Contribution\"

   means Covered Software of a particular Contributor.

1.4. \"Covered Software\"

   means Source Code Form to which the initial Contributor has attached the
   notice in Exhibit A, the Executable Form of such Source Code Form, and
   Modifications of such Source Code Form, in each case including portions
   thereof.

1.5. \"Incompatible With Secondary Licenses\"
   means

   a. that the initial Contributor has attached the notice described in
      Exhibit B to the Covered Software; or

   b. that the Covered Software was made available under the terms of version
      1.1 or earlier of the License, but not also under the terms of a
      Secondary License.

1.6. \"Executable Form\"

   means any form of the work other than Source Code Form.

1.7. \"Larger Work\"

   means a work that combines Covered Software with other material, in a separate
   file or files, that is not Covered Software.

1.8. \"License\"

   means this document.

1.9. \"Licensable\"

   means having the right to grant, to the maximum extent possible, whether at the
   time of the initial grant or subsequently, any and all of the rights conveyed by
   this License.

1.10. \"Modifications\"

   means any of the following:

   a. any file in Source Code Form that results from an addition to, deletion
      from, or modification of the contents of Covered Software; or

   b. any new file in Source Code Form that contains any Covered Software.

1.11. \"Patent Claims\" of a Contributor

    means any patent claim(s), including without limitation, method, process,
    and apparatus claims, in any patent Licensable by such Contributor that
    would be infringed, but for the grant of the License, by the making,
    using, selling, offering for sale, having made, import, or transfer of
    either its Contributions or its Contributor Version.

1.12. \"Secondary License\"

    means either the GNU General Public License, Version 2.0, the GNU Lesser
    General Public License, Version 2.1, the GNU Affero General Public
    License, Version 3.0, or any later versions of those licenses.

1.13. \"Source Code Form\"

    means the form of the work preferred for making modifications.

1.14. \"You\" (or \"Your\")

    means an individual or a legal entity exercising rights under this
    License. For legal entities, \"You\" includes any entity that controls, is
    controlled by, or is under common control with You. For purposes of this
    definition, \"control\" means (a) the power, direct or indirect, to cause
    the direction or management of such entity, whether by contract or
    otherwise, or (b) ownership of more than fifty percent (50%) of the
    outstanding shares or beneficial ownership of such entity.


2. License Grants and Conditions

2.1. Grants

   Each Contributor hereby grants You a world-wide, royalty-free,
   non-exclusive license:

   a. under intellectual property rights (other than patent or trademark)
      Licensable by such Contributor to use, reproduce, make available,
      modify, display, perform, distribute, and otherwise exploit its
      Contributions, either on an unmodified basis, with Modifications, or as
      part of a Larger Work; and

   b. under Patent Claims of such Contributor to make, use, sell, offer for
      sale, have made, import, and otherwise transfer either its Contributions
      or its Contributor Version.

2.2. Effective Date

   The licenses granted in Section 2.1 with respect to any Contribution become
   effective for each Contribution on the date the Contributor first distributes
   such Contribution.

2.3. Limitations on Grant Scope

   The licenses granted in this Section 2 are the only rights granted under this
   License. No additional rights or licenses will be implied from the distribution
   or licensing of Covered Software under this License. Notwithstanding Section
   2.1(b) above, no patent license is granted by a Contributor:

   a. for any code that a Contributor has removed from Covered Software; or

   b. for infringements caused by: (i) Your and any other third party’s
      modifications of Covered Software, or (ii) the combination of its
      Contributions with other software (except as part of its Contributor
      Version); or

   c. under Patent Claims infringed by Covered Software in the absence of its
      Contributions.

   This License does not grant any rights in the trademarks, service marks, or
   logos of any Contributor (except as may be necessary to comply with the
   notice requirements in Section 3.4).

2.4. Subsequent Licenses

   No Contributor makes additional grants as a result of Your choice to
   distribute the Covered Software under a subsequent version of this License
   (see Section 10.2) or under the terms of a Secondary License (if permitted
   under the terms of Section 3.3).

2.5. Representation

   Each Contributor represents that the Contributor believes its Contributions
   are its original creation(s) or it has sufficient rights to grant the
   rights to its Contributions conveyed by this License.

2.6. Fair Use

   This License is not intended to limit any rights You have under applicable
   copyright doctrines of fair use, fair dealing, or other equivalents.

2.7. Conditions

   Sections 3.1, 3.2, 3.3, and 3.4 are conditions of the licenses granted in
   Section 2.1.


3. Responsibilities

3.1. Distribution of Source Form

   All distribution of Covered Software in Source Code Form, including any
   Modifications that You create or to which You contribute, must be under the
   terms of this License. You must inform recipients that the Source Code Form
   of the Covered Software is governed by the terms of this License, and how
   they can obtain a copy of this License. You may not attempt to alter or
   restrict the recipients’ rights in the Source Code Form.

3.2. Distribution of Executable Form

   If You distribute Covered Software in Executable Form then:

   a. such Covered Software must also be made available in Source Code Form,
      as described in Section 3.1, and You must inform recipients of the
      Executable Form how they can obtain a copy of such Source Code Form by
      reasonable means in a timely manner, at a charge no more than the cost
      of distribution to the recipient; and

   b. You may distribute such Executable Form under the terms of this License,
      or sublicense it under different terms, provided that the license for
      the Executable Form does not attempt to limit or alter the recipients’
      rights in the Source Code Form under this License.

3.3. Distribution of a Larger Work

   You may create and distribute a Larger Work under terms of Your choice,
   provided that You also comply with the requirements of this License for the
   Covered Software. If the Larger Work is a combination of Covered Software
   with a work governed by one or more Secondary Licenses, and the Covered
   Software is not Incompatible With Secondary Licenses, this License permits
   You to additionally distribute such Covered Software under the terms of
   such Secondary License(s), so that the recipient of the Larger Work may, at
   their option, further distribute the Covered Software under the terms of
   either this License or such Secondary License(s).

3.4. Notices

   You may not remove or alter the substance of any license notices (including
   copyright notices, patent notices, disclaimers of warranty, or limitations
   of liability) contained within the Source Code Form of the Covered
   Software, except that You may alter any license notices to the extent
   required to remedy known factual inaccuracies.

3.5. Application of Additional Terms

   You may choose to offer, and to charge a fee for, warranty, support,
   indemnity or liability obligations to one or more recipients of Covered
   Software. However, You may do so only on Your own behalf, and not on behalf
   of any Contributor. You must make it absolutely clear that any such
   warranty, support, indemnity, or liability obligation is offered by You
   alone, and You hereby agree to indemnify every Contributor for any
   liability incurred by such Contributor as a result of warranty, support,
   indemnity or liability terms You offer. You may include additional
   disclaimers of warranty and limitations of liability specific to any
   jurisdiction.

4. Inability to Comply Due to Statute or Regulation

 If it is impossible for You to comply with any of the terms of this License
 with respect to some or all of the Covered Software due to statute, judicial
 order, or regulation then You must: (a) comply with the terms of this License
 to the maximum extent possible; and (b) describe the limitations and the code
 they affect. Such description must be placed in a text file included with all
 distributions of the Covered Software under this License. Except to the
 extent prohibited by statute or regulation, such description must be
 sufficiently detailed for a recipient of ordinary skill to be able to
 understand it.

5. Termination

5.1. The rights granted under this License will terminate automatically if You
   fail to comply with any of its terms. However, if You become compliant,
   then the rights granted under this License from a particular Contributor
   are reinstated (a) provisionally, unless and until such Contributor
   explicitly and finally terminates Your grants, and (b) on an ongoing basis,
   if such Contributor fails to notify You of the non-compliance by some
   reasonable means prior to 60 days after You have come back into compliance.
   Moreover, Your grants from a particular Contributor are reinstated on an
   ongoing basis if such Contributor notifies You of the non-compliance by
   some reasonable means, this is the first time You have received notice of
   non-compliance with this License from such Contributor, and You become
   compliant prior to 30 days after Your receipt of the notice.

5.2. If You initiate litigation against any entity by asserting a patent
   infringement claim (excluding declaratory judgment actions, counter-claims,
   and cross-claims) alleging that a Contributor Version directly or
   indirectly infringes any patent, then the rights granted to You by any and
   all Contributors for the Covered Software under Section 2.1 of this License
   shall terminate.

5.3. In the event of termination under Sections 5.1 or 5.2 above, all end user
   license agreements (excluding distributors and resellers) which have been
   validly granted by You or Your distributors under this License prior to
   termination shall survive termination.

6. Disclaimer of Warranty

 Covered Software is provided under this License on an \"as is\" basis, without
 warranty of any kind, either expressed, implied, or statutory, including,
 without limitation, warranties that the Covered Software is free of defects,
 merchantable, fit for a particular purpose or non-infringing. The entire
 risk as to the quality and performance of the Covered Software is with You.
 Should any Covered Software prove defective in any respect, You (not any
 Contributor) assume the cost of any necessary servicing, repair, or
 correction. This disclaimer of warranty constitutes an essential part of this
 License. No use of  any Covered Software is authorized under this License
 except under this disclaimer.

7. Limitation of Liability

 Under no circumstances and under no legal theory, whether tort (including
 negligence), contract, or otherwise, shall any Contributor, or anyone who
 distributes Covered Software as permitted above, be liable to You for any
 direct, indirect, special, incidental, or consequential damages of any
 character including, without limitation, damages for lost profits, loss of
 goodwill, work stoppage, computer failure or malfunction, or any and all
 other commercial damages or losses, even if such party shall have been
 informed of the possibility of such damages. This limitation of liability
 shall not apply to liability for death or personal injury resulting from such
 party’s negligence to the extent applicable law prohibits such limitation.
 Some jurisdictions do not allow the exclusion or limitation of incidental or
 consequential damages, so this exclusion and limitation may not apply to You.

8. Litigation

 Any litigation relating to this License may be brought only in the courts of
 a jurisdiction where the defendant maintains its principal place of business
 and such litigation shall be governed by laws of that jurisdiction, without
 reference to its conflict-of-law provisions. Nothing in this Section shall
 prevent a party’s ability to bring cross-claims or counter-claims.

9. Miscellaneous

 This License represents the complete agreement concerning the subject matter
 hereof. If any provision of this License is held to be unenforceable, such
 provision shall be reformed only to the extent necessary to make it
 enforceable. Any law or regulation which provides that the language of a
 contract shall be construed against the drafter shall not be used to construe
 this License against a Contributor.


10. Versions of the License

10.1. New Versions

    Mozilla Foundation is the license steward. Except as provided in Section
    10.3, no one other than the license steward has the right to modify or
    publish new versions of this License. Each version will be given a
    distinguishing version number.

10.2. Effect of New Versions

    You may distribute the Covered Software under the terms of the version of
    the License under which You originally received the Covered Software, or
    under the terms of any subsequent version published by the license
    steward.

10.3. Modified Versions

    If you create software not governed by this License, and you want to
    create a new license for such software, you may create and use a modified
    version of this License if you rename the license and remove any
    references to the name of the license steward (except to note that such
    modified license differs from this License).

10.4. Distributing Source Code Form that is Incompatible With Secondary Licenses
    If You choose to distribute Source Code Form that is Incompatible With
    Secondary Licenses under the terms of this version of the License, the
    notice described in Exhibit B of this License must be attached.

Exhibit A - Source Code Form License Notice

    This Source Code Form is subject to the
    terms of the Mozilla Public License, v.
    2.0. If a copy of the MPL was not
    distributed with this file, You can
    obtain one at
    http://mozilla.org/MPL/2.0/.

If it is not possible or desirable to put the notice in a particular file, then
You may include the notice in a location (such as a LICENSE file in a relevant
directory) where a recipient would be likely to look for such a notice.

You may add additional accurate notices of copyright ownership.

Exhibit B - \"Incompatible With Secondary Licenses\" Notice

    This Source Code Form is \"Incompatible
    With Secondary Licenses\", as defined by
    the Mozilla Public License, v. 2.0.

" # end of mozilla2 license variable

  unlicense="This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>
" # end of unlicense license variable

  none="Copyright $YEAR $AUTHOR_NAME
" # end of none license variable

  case "$LICENSE_TYPE" in
    agpl3)
                filecontents="$agpl3"
                LICENSE_URL="https://opensource.org/licenses/AGPL-3.0"
                ;;
    apache2)
                LICENSE_URL="https://opensource.org/licenses/Apache-2.0"
                filecontents="$apache2"
                ;;
    artistic2)
                LICENSE_URL="https://opensource.org/licenses/Artistic-2.0"
                filecontents="$artistic2"
                ;;
    bsd)
                LICENSE_URL="https://opensource.org/licenses/BSD-2-Clause"
                filecontents="$bsd"
                ;;
    bsd3c)
                LICENSE_URL="https://opensource.org/licenses/BSD-3-Clause"
                filecontents="$bsd3c"
                ;;
    eclipse)
                LICENSE_URL="https://opensource.org/licenses/EPL-1.0"
                filecontents="$eclipse"
                ;;
    gpl2)
                LICENSE_URL="https://opensource.org/licenses/GPL-2.0"
                filecontents="$gpl2"
                ;;
    gpl3)
                LICENSE_URL="https://opensource.org/licenses/GPL-3.0"
                filecontents="$gpl3"
                ;;
    lgpl2)
                LICENSE_URL="https://opensource.org/licenses/LGPL-2.1"
                filecontents="$lgpl2"
                ;;
    lgpl3)
                LICENSE_URL="https://opensource.org/licenses/LGPL-3.0"
                filecontents="$lgpl3"
                ;;
    mit)
                LICENSE_URL="https://opensource.org/licenses/MIT"
                filecontents="$mit"
                ;;
    mozilla2)
                LICENSE_URL="https://opensource.org/licenses/MPL-2.0"
                filecontents="$mozilla2"
                ;;
    unlicense)
                LICENSE_URL="https://unlicense.org/UNLICENSE"
                filecontents="$unlicense"
                ;;
    none)
                LICENSE_URL=""
                filecontents="$none"
                ;;
    *)
                exit 1
                ;;
  esac

  [ -e "$filename" ] && echonicely "\"$filename\" already exists, skipping." || echo "$filecontents" >> "$filename"
} # end of generate_license


##### Main

while getopts ":ha:e:g:l:n:p:t:u:" opt; do
    case "$opt" in
      h)
          usage
          exit 0
          ;;
      a)
          AUTHOR_NAME="$(printf '%s' "$OPTARG" | sed -e 's/[^a-zA-Z[:blank:]]//g')"
          echonicely "Setting author name to \"$AUTHOR_NAME\"."
          ;;
      e)
          AUTHOR_EMAIL="$(printf '%s' "$OPTARG" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9@.]//g')"
          if string_contains "@" "$AUTHOR_EMAIL";
            then
              AUTHOR_EMAIL="$OPTARG"
              echonicely "Setting author email address to \"$AUTHOR_EMAIL\"."
            else
              echoerror "\"$OPTARG\" doesn't appear to be a valid email address."
              exit 1
          fi
          ;;
      g)
          GITHUB_USER_ID="$(printf '%s' "$OPTARG" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9]//g')"
          echonicely "Setting github user id to \"$GITHUB_USER_ID\"."
          ;;
      n)
          NPM_USER_ID="$(printf '%s' "$OPTARG" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9]//g')"
          echonicely "Setting npm user id to \"$NPM_USER_ID\"."
          ;;
      l)
          LICENSE_TYPE="$(printf '%s' "$OPTARG" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9]//g')" # sanitize user input
          if string_contains " $LICENSE_TYPE " "$SUPPORTED_LICENSES"; # check against list of supported licenses
            then
              echonicely "Setting license to \"$LICENSE_TYPE\"."
            else
              echoerror "\"$OPTARG\" is not a supported license type. Please select from: $SUPPORTED_LICENSES"
              exit 1
          fi
          ;;
      p)
          PROJECT_NAME_INPUT="$OPTARG"
          ;;
      t)
          if [ -d "$OPTARG" ]; # ensure this is a directory
            then
              if [ -w "$OPTARG" ]; # ensure we can write to the directory
                then
                  TARGET_DIRECTORY="$OPTARG/" # add a trailing / (multiple trailing //'s get flattened but this will ensure there's always at least one)
                  echonicely "Setting base directory to \"$TARGET_DIRECTORY\"."
                  else
                  echonicely "Cannot write to directory \"$OPTARG\"."
                  exit 1
              fi
            else
              echonicely "\"$OPTARG\" is not a directory."
              exit 1
          fi
          ;;
      u)
          AUTHOR_URL="$(printf '%s' "$OPTARG" | sed -e 's/[[:blank:]]//g' -e 's/[^a-zA-Z0-9/.]//g')"
          if string_contains "." "$AUTHOR_URL" && string_contains "/" "$AUTHOR_URL";
            then
              AUTHOR_URL="$OPTARG"
              echonicely "Setting author url to \"$AUTHOR_URL\"."
            else
              echoerror "\"$OPTARG\" doesn't appear to be a valid url."
              exit 1
          fi
          ;;
      *)
          echoerror "Invalid option: -$OPTARG"
          exit 1
          ;;
      :)
          echoerror "Option -$OPTARG requires an argument."
          exit 1
          ;;
    esac
done

if parse_name;
  then
    generate_directory "assets" "docs" "src" "tests"
    generate_license
    generate_main_js
    generate_readme
    generate_gitignore
    generate_gulpfile
    generate_package_json
    generate_bower_json
    npm_init
    git_init
  else
    echoerror "No changes were made."
fi
