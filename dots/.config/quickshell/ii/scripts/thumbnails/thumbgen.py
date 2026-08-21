#!/usr/bin/env python3

# From https://github.com/difference-engine/thumbnail-generator-ubuntu (MIT License)
# Since the script is small and the maintainers seem inactive to accept my PR (#11) I decided to just copy it over.
# When it gets merged and the python package gets updated we can just use it

import os
import sys
from multiprocessing import Pool
from pathlib import Path
from typing import List, Union

import gi
from loguru import logger
from tqdm import tqdm

gi.require_version("GnomeDesktop", "4.0")
from gi.repository import Gio, GnomeDesktop  # isort:skip

thumbnail_size_map = {
    "normal": GnomeDesktop.DesktopThumbnailSize.NORMAL,
    "large": GnomeDesktop.DesktopThumbnailSize.LARGE,
    "x-large": GnomeDesktop.DesktopThumbnailSize.XLARGE,
    "xx-large": GnomeDesktop.DesktopThumbnailSize.XXLARGE,
}

factory = None
logger.remove()
logger.add(sys.stdout, level="INFO")
logger.add("/tmp/thumbgen.log", level="DEBUG", rotation="100 MB")

def make_thumbnail(fpath: str) -> bool:
    mtime = os.path.getmtime(fpath)
    # Use Gio to determine the URI and mime type
    f = Gio.file_new_for_path(str(fpath))
    uri = f.get_uri()
    info = f.query_info("standard::content-type", Gio.FileQueryInfoFlags.NONE, None)
    mime_type = info.get_content_type()

    if factory.lookup(uri, mtime) is not None:
        logger.debug("FRESH       {}".format(uri))
        return False

    if not factory.can_thumbnail(uri, mime_type, mtime):
        logger.debug("UNSUPPORTED {}".format(uri))
        return False

    thumbnail = factory.generate_thumbnail(uri, mime_type)
    if thumbnail is None:
        logger.debug("ERROR       {}".format(uri))
        return False

    logger.debug("OK          {}".format(uri))
    factory.save_thumbnail(thumbnail, uri, mtime)
    return True


@logger.catch()
def thumbnail_folder(*, dir_path: Path, workers: int, only_images: bool, recursive: bool, machine_progress: bool = False) -> None:
    all_files = get_all_files(dir_path=dir_path, recursive=recursive)
    if only_images:
        all_files = get_all_images(all_files=all_files)
    all_files = [str(fpath) for fpath in all_files]
    if machine_progress:
        completed = 0
        total = len(all_files)
        with Pool(processes=workers) as p:
            for result in p.imap(make_thumbnail, all_files):
                completed += 1
                print(f"PROGRESS {completed}/{total} FILE {all_files[completed-1]}")
                sys.stdout.flush()
    else:
        with Pool(processes=workers) as p:
            list(tqdm(p.imap(make_thumbnail, all_files), total=len(all_files)))


def get_all_images(*, all_files: List[Path]) -> List[Path]:
    img_suffixes = [".jpg", ".jpeg", ".png", ".gif"]
    all_images = [fpath for fpath in all_files if fpath.suffix in img_suffixes]
    print("Found {} images".format(len(all_images)))
    return all_images


def get_all_files(*, dir_path: Path, recursive: bool) -> List[Path]:
    if not (dir_path.exists() and dir_path.is_dir()):
        raise ValueError("{} doesn't exist or isn't a valid directory!".format(dir_path.resolve()))
    if recursive:
        all_files = dir_path.rglob("*")
    else:
        all_files = dir_path.glob("*")
    all_files = [fpath for fpath in all_files if fpath.is_file()]
    print("Found {} files in the directory: {}".format(len(all_files), dir_path.resolve()))
    return all_files

def main(argv):
    img_dirs = ""
    size = "normal"
    workers = 1
    only_images = False
    recursive = False
    machine_progress = False

    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg in ("-d", "--img_dirs") and i + 1 < len(argv):
            img_dirs = argv[i + 1]
            i += 2
        elif arg in ("-s", "--size") and i + 1 < len(argv):
            size = argv[i + 1]
            i += 2
        elif arg in ("-w", "--workers") and i + 1 < len(argv):
            workers = int(argv[i + 1])
            i += 2
        elif arg in ("-i", "--only_images"):
            only_images = True
            i += 1
        elif arg in ("-r", "--recursive"):
            recursive = True
            i += 1
        elif arg == "--machine_progress":
            machine_progress = True
            i += 1
        else:
            i += 1

    if not img_dirs:
        sys.exit("Error: Missing required option '-d/--img_dirs'")
    if size not in thumbnail_size_map:
        sys.exit(f"Error: Invalid size '{size}'. Must be one of: normal, large, x-large, xx-large")

    img_dirs = [Path(img_dir) for img_dir in img_dirs.split()]
    global factory
    factory = GnomeDesktop.DesktopThumbnailFactory.new(thumbnail_size_map[size])
    for img_dir in img_dirs:
        thumbnail_folder(dir_path=img_dir, workers=workers, only_images=only_images, recursive=recursive, machine_progress=machine_progress)
    print("Thumbnail Generation Completed!")


if __name__ == "__main__":
    main(sys.argv[1:])
