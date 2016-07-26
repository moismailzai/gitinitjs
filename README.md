# gitinitjs

#### A POSIX-compliant script that bootstraps a directory for new GitHub-based JavaScript projects.


## Details

**Current version**: 0.1.0-0
*(expect breaking changes prior to version 1.0)*

**Source code**: [https://github.com/moismailzai/gitinitjs](https://github.com/moismailzai/gitinitjs)

**License**: [MIT](https://opensource.org/licenses/MIT)

**Copyright**: &copy; 2016 [Misaqe Ismailzai](http://www.moismailzai.com) <moismailzai@gmail.com>


## Installation

**Standalone**: [regular](https://cdn.rawgit.com/moismailzai/gitinitjs/master/gitinitjs.sh)

``` sh
git clone https://github.com/moismailzai/gitinitjs
chmod +x gitinitjs.sh
```

**Bower**: [bower](https://bower.io/search/?q=gitinitjs)

``` sh
bower install gitinitjs
```


## Dependancies

A POSIX-compliant shell.


## What Does It Do?

Bootstraps a directory for new GitHub-based JavaScript projects.

The script creates a new new directory and populates it with the following files and folders:
```
|-- assets/
|-- docs/
|-- src/
|   |- main.js 
|-- tests/
|- bower.json
|- gulpfile.js
|- LICENSE
|- package.json
|- README.md
|- .gitignore
```
Each file is configured based on user-defined script defaults or command-line arguments. Usage is straightforward:


## Usage:
```
usage: gitinitjs.sh [[[-a author_name] [-e author_email] [-g github_user_id] [-l license_type] [-n npm_user_id] [-p project_name] [-t target_directory] [-u author_url]] | [-h]]
   -a author_name: the author's name (used to attribute ownership in various files)
   (the default value can be configured in $AUTHOR_NAME and is currently set to "Misaqe Ismailzai")

   -e author_email: the author's email address (used to set contact information in various files)
   (the default value can be configured in $AUTHOR_EMAIL and is currently set to "moismailzai@gmail.com")

   -g github_user_id: the github.com user id to associate this project with (used to generate links in various files)
   (the default value can be configured in $GITHUB_USER_ID and is currently set to "moismailzai")

   -l license_type: the type of license to generate and associate this project with
   valid types: agpl3 apache2 artistic2 bsd bsd3c eclipse gpl2 gpl3 lgpl2 lgpl3 mit mozilla2 unlicense none
   (the default value can be configured in $LICENSE_TYPE and is currently set to "mit")

   -n npm_user_id: the npmjs.com user id to associate this project with (used to generate links in various files)
   (the default value can be configured in $NPM_USER_ID and is currently set to "moismailzai")

   -p project_name: the project name (used as the project directory name as well)
   (the default value is the current directory's name, "/home/mo/Dropbox/dev/cars")

   -t target_directory: the target directory under which the project directory should be created
   (the default value can be configured in $TARGET_DIRECTORY and is currently set to "/home/mo/Dropbox/dev/cars/")

   -u author_url: the author's URL (used to set contact information in various files)
   (the default value can be configured in $AUTHOR_URL and is currently set to "http://www.moismailzai.com")

   -h: display this message
```

**Setting Project Defaults**

Edit the default variables, found at the top of the script:  
``` sh 
##### User Defaults (change these to set project defaults) #####################
AUTHOR_NAME="Your Name"
AUTHOR_EMAIL="your@email.com"
AUTHOR_URL="http://www.yourwebsite.com"
GITHUB_USER_ID="youruserid"
LICENSE_TYPE="mit"
NPM_USER_ID="youruserid"
TARGET_DIRECTORY="${PWD}/"
##### END OF CONFIGURABLE DEFAULTS #############################################
```  


**Bootstrapping a Project**

// the script assumes you've set sane defaults so simply calling it is enough to get you rolling (though you'll be asked to confirm that you want to use the current directory, and its name, as the root directory of a new project).

``` sh
gitinitjs.sh
```

// calling with -p will bootstrap a project called "ninjasgonewild" in a directory called "ninjasgonewild" (provided the directory doesn't already exist). By default, this project directory is placed wherever the script is invoked from but you can alter the behavior by changing the "TARGET_DIRECTORY" variable to a path of your choice.

``` sh
gitinitjs.sh -p ninjasgonewild
```

//  calling with a flag will override defaults. Eg, the following would force the "none" license (which generates a COPYRIGHT file instead of a LICENSE file).  
``` sh
gitinitjs.sh -l none
```

// you can force the script to completely override all defaults by explicitly providing each parameter (-a author name, -e author email, -g github.com username, -l license type, -n npmjs.com username, -p project name, -t project target directory, and -u author url):
``` sh
gitinitjs.sh -a "Christopher Alesund" -e getright@nip.gl -g GeT_RiGhT -l unlicense -n GeT_RiGhT -p ninjasgonewild -t /root/home/christopher -u http://nip.gl/players/get_right
```
