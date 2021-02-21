# Credits
# https://www.simplifiedpython.net/python-download-file/
# https://stackoverflow.com/questions/2349991/how-to-import-other-python-files
# https://www.reddit.com/r/VisualStudioCode/comments/i3mpct/how_to_tell_pylance_to_ignore_particular_linefile/
# https://stackoverflow.com/questions/50856103/how-to-avoid-python-autopep8-formatting-in-a-line-in-vscode

import urllib.request
import os

# Get needed scripts
urllib.request.urlretrieve(
    r'https://raw.githubusercontent.com/MatthewDavidMiller/Debian-Install/stable/linux_scripts/debian_server_scripts.py', r'debian_server_scripts.py')
urllib.request.urlretrieve(
    r'https://raw.githubusercontent.com/MatthewDavidMiller/Bash_Python_Common_Functions/main/functions/functions.py', r'functions.py')

# Import functions from files
from debian_server_scripts import *  # type: ignore # nopep8
from functions import *  # type: ignore # nopep8
