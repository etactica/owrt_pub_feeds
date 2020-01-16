
you are expected to have a luci installation at ~/src/luci.
We use the tools from there to scan a fixed list of our private apps to generate a .pot file
We use the same structure and methods as luci upstream, except we don't provide helpers for "initializing a new language", we just provide the pot file and you are expected to save it with the "right" name following the existing structure.

## Update po/template/\*.pot files from source files
$ ./rebuild.sh 

## Adding new applications

Edit rebuild.sh and add to the list.  All "appropriate" files in the directory should already be covered.

## Update a translation
use poedit and save them to po/<langid>/appname.po

ie, we use po/<langid>/appname.po instead of appname.<langid>.po as appears to be often done in other projects
This is to be consistent with how LuCI does it, so our files are auto loaded properly.

## Find missing translateable strings

$ ./butcher.sh po/<testlanguage>

butcher.sh will create a "translation" that simply makes strings of xxxxx of the same length as the
source strings.  This makes it easy to scan for strings that are not correctly marked for translation
as they will still be in english, instead of xxxx

__Caution__ this will _destroy_ any translations already in that file!

### butcher.sh requirements
python3 and polib
```
python3 -mvenv .env3
. .env3/bin/activate
pip install polib
```
