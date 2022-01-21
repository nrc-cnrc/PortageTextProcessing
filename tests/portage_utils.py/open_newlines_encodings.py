#!/usr/bin/env python3

import builtins
import os
import portage_utils
import tempfile
import time
from portage_utils import open

with builtins.open("newlines.txt", "wt", newline="", encoding="utf8") as f:
    f.write("TestéàûLF\nCR\rLF\nCRLF\r\nLF\n")
os.system("gzip < newlines.txt > newlines.gz")


for infile in "newlines.txt", "newlines.gz", "cat newlines.txt |":
    for encoding in None, "latin1", "utf8", portage_utils.DEFAULT_ENCODING_VALUE:
        for newline in None, "", "\n", "\r", "\r\n":
            print(
                infile,
                "default" if encoding is portage_utils.DEFAULT_ENCODING_VALUE else encoding,
                repr(newline),
                list(open(infile, "r", encoding=encoding, newline=newline))
            )
    print(
        infile,
        "rb",
        list(open(infile, "rb"))
    )


tmp_dir_root = "/tmp" if os.path.exists("/tmp") else None  # For portability
with tempfile.TemporaryDirectory(dir=tmp_dir_root) as tmpdirname:
    for outfile, result in (
        ("outlines.txt", "outlines.txt"),
        ("outlines.gz", "outlines.gz"),
        ("| cat > outlines.txt", "outlines.txt")
    ):
        if outfile == "| cat > outlines.txt":
            outfile_path = "| cat > " + os.path.join(tmpdirname, "outlines.txt")
        else:
            outfile_path = os.path.join(tmpdirname, outfile)
        result_path = os.path.join(tmpdirname, result)
        for encoding in "latin1", "utf8", portage_utils.DEFAULT_ENCODING_VALUE:
            for newline in None, "", "\n", "\r", "\r\n":
                with open(outfile_path, "w", encoding=encoding, newline=newline) as f:
                    print("àéCR\rCRLF\r", file=f)
                    print("LF", file=f)
                time.sleep(0.2)
                with open(result_path, "rb") as res:
                    print(
                        outfile,
                        "default" if encoding is portage_utils.DEFAULT_ENCODING_VALUE else encoding,
                        repr(newline),
                        repr(res.read()),
                    )
        with open(outfile_path, "wb") as f:
            f.write(b"CR\rCRLF\r\nLF\n")
        time.sleep(0.2)
        with open(result_path, "rb") as res:
            print(
                outfile,
                "wb",
                repr(res.read()),
            )


