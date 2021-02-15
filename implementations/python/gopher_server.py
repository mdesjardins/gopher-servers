"""Python implementation of a basic barebones Gopher server. See README.md."""
import sys
import os
import getopt
import socketserver
import logging
from dataclasses import dataclass
from typing import List, Dict
from enum import Enum


logging.basicConfig(level=logging.DEBUG)


class FileType(Enum):
    TEXT = 0
    DIRECTORY = 1
    NAMESERVER = 2
    ERROR = 3
    HQX = 4
    ARCHIVE = 5
    SEARCH = 7
    BINARY = 9
    MIRROR = 100
    GIF = 101
    IMAGE = 102
    DOCUMENT = 103
    HTML = 104
    INFO = 105
    SOUND = 106
    VIDEO = 107
    CALENDAR = 108


FILE_TYPE_MAP: Dict[str, str] = {
    '0': FileType.TEXT,
    '1': FileType.DIRECTORY,
    '2': FileType.NAMESERVER,
    '3': FileType.ERROR,
    '4': FileType.HQX,
    '5': FileType.ARCHIVE,
    '7': FileType.SEARCH,
    '9': FileType.BINARY,
    '+': FileType.MIRROR,
    'g': FileType.GIF,
    'I': FileType.IMAGE,
    'd': FileType.DOCUMENT,
    'h': FileType.HTML,
    'i': FileType.INFO,
    's': FileType.SOUND,
    ';': FileType.VIDEO,
    'c': FileType.CALENDAR
}


INVERSE_FILE_TYPE_MAP = {v: k for k, v in FILE_TYPE_MAP.items()}

# Stolen from gophernicus.h FILETYPES.
FILE_EXTENSION_MAP = {
    'txt': FileType.TEXT,
    'md': FileType.TEXT,
    'pl': FileType.TEXT,
    'py': FileType.TEXT,
    'sh': FileType.TEXT,
    'tcl': FileType.TEXT,
    'c': FileType.TEXT,
    'cpp': FileType.TEXT,
    'h': FileType.TEXT,
    'log': FileType.TEXT,
    'conf': FileType.TEXT,
    'php': FileType.TEXT,
    'php3': FileType.TEXT,
    'hqx': FileType.HQX,
    'zip': FileType.ARCHIVE,
    'gz': FileType.ARCHIVE,
    'Z': FileType.ARCHIVE,
    'tgz': FileType.ARCHIVE,
    'bz2': FileType.ARCHIVE,
    'rar': FileType.ARCHIVE,
    'ics': FileType.CALENDAR,
    'ical': FileType.CALENDAR,
    'gif': FileType.GIF,
    'jpg': FileType.IMAGE,
    'jpeg': FileType.IMAGE,
    'png': FileType.IMAGE,
    'bmp': FileType.IMAGE,
    'mp3': FileType.SOUND,
    'wav': FileType.SOUND,
    'flac': FileType.SOUND,
    'ogg': FileType.SOUND,
    'avi': FileType.VIDEO,
    'mp4': FileType.VIDEO,
    'mpg': FileType.VIDEO,
    'mov': FileType.VIDEO,
    'qt': FileType.VIDEO,
    'pdf': FileType.DOCUMENT,
    'ps': FileType.DOCUMENT,
    'doc': FileType.DOCUMENT,
    'docx': FileType.DOCUMENT,
    'ppt': FileType.DOCUMENT,
    'pptx': FileType.DOCUMENT,
    'xls': FileType.DOCUMENT,
    'xlsx': FileType.DOCUMENT,
}


@dataclass
class Config:
    """Global configuration values."""
    port: int = 70
    host: str = 'localhost'
    root: str = '/var/gopher'
    mapfile_name: str = 'gophermap'


CONFIG = Config()


def _selector_to_path(selector: str) -> str:
    """Utility method used in several different classes for converting
    selector names to paths on the filesystem."""
    return os.path.abspath(os.path.join(CONFIG.root, selector[1:]))


class GopherMenu:
    """This class represents a Gopher Menu and can be streamed out
    to the client as bytes."""
    def __init__(self, selector: str):
        self.selector = selector
        self.entries: List[str] = []
        map_path = os.path.abspath(
            os.path.join(_selector_to_path(selector), CONFIG.mapfile_name)
        )
        if os.path.isfile(map_path) and os.access(map_path, os.R_OK):
            self._build_from_gophermap(map_path)
        else:
            self._build_from_directory_listing(selector)

    def _build_from_gophermap(self, map_path: str) -> None:
        with open(map_path) as map:
            lines = map.readlines()
            for line in lines:
                line = line.strip()
                if line.startswith("#"):
                    continue
                if "\t" not in line:
                    line = f"i{line}"

                fields = line.split("\t")
                file_type_and_name = fields[0]
                if len(fields) > 1:
                    file_type_and_name, filename, host, port = line.split("\t")
                else:
                    filename = ""
                    host = CONFIG.host
                    port = str(CONFIG.port)
                if file_type_and_name[0] in FILE_TYPE_MAP:
                    menu_line = "\t".join([file_type_and_name.strip(),
                                           filename,
                                           host,
                                           port])
                    self.entries.append(menu_line)
                else:
                    logging.error(f"Invalid line in Gophermap: {line}")

    def _build_from_directory_listing(self, selector: str) -> None:
        path = _selector_to_path(selector)
        for entry in os.scandir(path):
            if os.access(entry.path, os.R_OK):
                file_type = FileType.DIRECTORY
                if entry.is_file():
                    extension = entry.name.split(".")[-1]
                    file_type = FILE_EXTENSION_MAP.get(extension,
                                                       FileType.BINARY)
                file_type_and_name = (
                    f"{INVERSE_FILE_TYPE_MAP[file_type]}{entry.name}"
                )
                menu_line = "\t".join([file_type_and_name.strip(),
                                       entry.path,
                                       CONFIG.host,
                                       str(CONFIG.port)])
                self.entries.append(menu_line)

    def __bytes__(self) -> bytes:
        if len(self.entries) == 0:
            return bytes("\r\n", "ascii")
        self.entries.append(".\r\n")
        return ("\r\n".join(self.entries)).encode()


class GopherServerRequestHandler(socketserver.BaseRequestHandler):
    """Handles incoming Gopher requests. The callback is the handle
    function."""
    def _is_serveable_directory(self, selector: str) -> bool:
        path = _selector_to_path(selector)
        return os.path.isdir(path) and os.access(path, os.R_OK)  # executable?

    def _is_serveable_file(self, selector: str) -> bool:
        path = _selector_to_path(selector)
        return os.path.isfile(path) and os.access(path, os.R_OK)

    def _is_text_file(self, selector: str) -> bool:
        extension = _selector_to_path(selector).split(".")[-1]
        return FILE_EXTENSION_MAP.get(extension, None) == FileType.TEXT

    def _serve_not_found_error(self, selector: str) -> None:
        """Serves an error message and error type."""
        file_type = INVERSE_FILE_TYPE_MAP[FileType.ERROR]
        message = "\t".join([
            f"{file_type} '{selector}' doesn't exist!",
            "",
            CONFIG.host,
            str(CONFIG.port)
        ]) + "\r\n"
        self.request.sendall(message.encode())

    def _serve_text(self, selector: str) -> None:
        """Serves a plain text file, one line at a time."""
        path = _selector_to_path(selector)
        with open(path) as f:
            lines = f.readlines()
            for line in lines:
                self.request.sendall(f"{line.strip()}\r\n".encode())

    def _serve_file(self, selector: str) -> None:
        if self._is_text_file(selector):
            self._serve_text(selector)
        else:
            with open(_selector_to_path(selector), 'rb') as f:
                self.request.sendfile(f, 0)

    def handle(self):
        """Handles incoming server requests."""
        selector = self.request.recv(1024).decode('ascii').strip()
        logging.info(f"Requested {selector}")
        if self._is_serveable_directory(selector):
            self.request.sendall(bytes(GopherMenu(selector)))
        elif self._is_serveable_file(selector):
            self._serve_file(selector)
        else:
            logging.warning(f"Requested selector not found: {selector}")
            self._serve_not_found_error(selector)


class ThreadedTcpServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    pass


def main(argv: List[str]):
    """Entrypoint. Parse command line args and sit in a server loop."""
    try:
        opts, _ = getopt.getopt(argv[1:],
                                "p:h:r:m",
                                ["port=", "host=", "root=", "mapfilename="])
    except getopt.GetoptError:
        print(
            "python gopher_server.py "
            "--port=<port> --host=<host> --root=<root> "
            "--mapfilename=<mapfilename>"
        )
        sys.exit(-1)

    for opt, arg in opts:
        if opt in ('-p', '--port'):
            CONFIG.port = int(arg)
        elif opt in ('-h', '--host'):
            CONFIG.host = arg
        elif opt in ('-r', '--root'):
            CONFIG.root = arg
        elif opt in ('-m', '--mapfilename'):
            CONFIG.mapfile_name = arg

    logging.info(
        f"Starting Gopher Server at {CONFIG.host} "
        f"on port {CONFIG.port}, serving from {CONFIG.root}"
    )

    # Serve forever
    socketserver.TCPServer.allow_reuse_address = True
    server = ThreadedTcpServer((CONFIG.host, CONFIG.port),
                               GopherServerRequestHandler)
    with server:
        server.serve_forever()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
