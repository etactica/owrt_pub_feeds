
you are expected to have a luci installation at ~/src/luci.
We use the tools from there to scan a fixed list of our private apps to generate a .pot file
We use the same structure and methods as luci upstream, except we don't provide helpers for "initializing a new language", we just provide the pot file and you are expected to save it with the "right" name following the existing structure.

(ie, we use po/<langid>/appname.po instead of appname.<langid>.po as appears to be often done in other projects)


