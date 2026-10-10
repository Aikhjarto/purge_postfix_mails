"""Tests for the bash completion in completions/purge_postfix_mails.sh."""
import os
import shutil
import subprocess
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
COMPLETION = os.path.join(ROOT, "completions", "purge_postfix_mails.sh")
COMMANDS = ("purge_postfix_mails.sh", "purge_postfix_mailer_daemon.sh",
            "purge_postfix_per_recipient.sh", "purge_postfix_per_sender.sh")


def complete(command, *words, cwd=None):
    """The candidates bash offers for the last of words, which may be empty."""
    words = (command,) + words
    script = 'source "$1"; shift; COMP_WORDS=("$@"); COMP_CWORD=$(($# - 1)); ' \
             '$(complete -p "$1" | sed -E "s/.*-F ([^ ]+) .*/\\1/"); printf "%s\\n" "${COMPREPLY[@]}"'
    result = subprocess.run(["bash", "-c", script, "bash", COMPLETION] + list(words),
                            capture_output=True, text=True, check=True, cwd=cwd)
    return [line for line in result.stdout.split("\n") if line]


@unittest.skipUnless(shutil.which("bash"), "bash is not installed")
class CompletionTests(unittest.TestCase):
    def test_syntax(self):
        subprocess.run(["bash", "-n", COMPLETION], check=True)

    def test_scripts_have_no_options(self):
        for command in COMMANDS:
            with open(os.path.join(ROOT, command)) as script:
                self.assertNotIn("getopts", script.read(), command)

    def test_no_file_names(self):
        with tempfile.TemporaryDirectory() as directory:
            open(os.path.join(directory, "queue.txt"), "w").close()
            for command in COMMANDS:
                self.assertEqual(complete(command, "", cwd=directory), [], command)
                self.assertEqual(complete(command, "root@example.org", "q", cwd=directory), [], command)

    def test_every_installed_script_is_registered(self):
        installed = sorted(name for name in os.listdir(ROOT) if name.endswith(".sh"))
        self.assertEqual(installed, sorted(COMMANDS))
        for command in COMMANDS:
            result = subprocess.run(["bash", "-c", 'source "$1"; complete -p "$2"', "bash", COMPLETION, command],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, command)


if __name__ == "__main__":
    unittest.main()
