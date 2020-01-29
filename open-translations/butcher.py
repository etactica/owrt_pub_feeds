
import sys
import polib

def butcher(inf, outf):
    print("Butchering from {} to {}".format(inf, outf))
    po = polib.pofile(inf)
    for entry in po:
        entry.msgstr = ' '.join(["x"*len(x) for x in entry.msgid.split()])
    po.save(outf)

def main():
    if len(sys.argv) != 3:
        print("Usage: butcher <source po> <output po>")
        return
    butcher(sys.argv[1], sys.argv[2])

if __name__ == "__main__":
    main()
