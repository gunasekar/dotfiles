# printer

A **Print to PDF** printer for macOS (macOS only). Print to it from any app and the
job lands in `~/Downloads` as `<document>_printed_<timestamp>.pdf`.

It exists for apps that won't let you use the "Save as PDF" button in the macOS print
dialog. Acrobat is one. It refuses ("Saving a PDF file when printing is not
supported"), and it won't open its print dialog at all on a Mac with no printer
installed. The case that needed it: a digitally signed PDF that Acrobat shows as
"Signature valid" on this Mac, but that shows as unverified on any machine without
the signer's certificate. Printing it here, through Acrobat, keeps the verified
appearance in the output.

## Installation

```bash
cd ~/.dotfiles
./install.sh   # stows the package, loads the agent, creates the queue
```

Needs `ghostscript` (in the Brewfile).

## How it works

| Piece | Where | Role |
|---|---|---|
| CUPS queue `Print_to_PDF` | `lpadmin`, run by `install.sh` | Generic PostScript driver, device `socket://127.0.0.1:9100` |
| `local.guna.print-to-pdf` | `~/Library/LaunchAgents/` | launchd listens on `127.0.0.1:9100` and starts the script once per connection |
| `print-to-pdf` | `~/.local/bin/` | Reads the PostScript job from stdin, runs `gs` (pdfwrite, A4) into `~/Downloads` |

The listener is bound to loopback only, so nothing else on the network can print
through it. It isn't a resident process: launchd holds the socket and only runs the
script when a job arrives.

Errors from `gs` go to `/tmp/print-to-pdf.log`.

Because the queue uses a PPD driver, `lpadmin` warns that printer drivers are
deprecated. A future CUPS release may drop them, and then the queue would need an
IPP Everywhere equivalent.

## Removal

```bash
launchctl bootout gui/$(id -u)/local.guna.print-to-pdf
lpadmin -x Print_to_PDF
cd ~/.dotfiles && stow -D printer
```
