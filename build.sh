#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: \$0 <source_file>" >&2
    exit 1
fi

SOURCE="\$1"
if [ ! -f "\$SOURCE" ]; then
    echo "Error: File '\$SOURCE' not found." >&2
    exit 2
fi

OUTPUT=\$(grep -m 1 '^ *//\|^\s*%' "\$SOURCE" | grep -o 'Output:[[:space:]]*[^[:space:]]*' | sed 's/^[[:space:]]*Output:[[:space:]]*//' | head -1)

if [ -z "\$OUTPUT" ]; then
    echo "Error: No 'Output: filename' comment found in '\$SOURCE'." >&2
    exit 3
fi

TMPDIR=\$(mktemp -d)
if [ \$? -ne 0 ]; then
    echo "Error: Failed to create temporary directory." >&2
    exit 4
fi

cleanup() {
    rm -rf "\$TMPDIR"
}
trap cleanup EXIT INT TERM HUP

cp "\$SOURCE" "\$TMPDIR/"
cd "\$TMPDIR" || { echo "Error: Cannot change directory to '\$TMPDIR'." >&2; exit 5; }

case "\$SOURCE" in
    *.c)
        gcc -o "\$OUTPUT" "\$(basename "\$SOURCE")"
        if [ \$? -ne 0 ]; then
            echo "Error: Compilation failed." >&2
            exit 6
        fi
        ;;
    *.cpp|*.cc)
        g++ -o "\$OUTPUT" "\$(basename "\$SOURCE")"
        if [ \$? -ne 0 ]; then
            echo "Error: Compilation failed." >&2
            exit 6
        fi
        ;;
    *.tex)
        pdflatex "\$(basename "\$SOURCE")" >/dev/null 2>&1
        if [ \$? -ne 0 ]; then
            echo "Error: LaTeX compilation failed." >&2
            exit 7
        fi
        if [ ! -f "\$OUTPUT" ]; then
            echo "Error: Expected output file '\$OUTPUT' not generated." >&2
            exit 8
        fi
        ;;
    *)
        echo "Error: Unsupported file type: '\$SOURCE'" >&2
        exit 9
        ;;
esac

cp "\$OUTPUT" "../" || { echo "Error: Failed to copy output file." >&2; exit 10; }

exit 0
