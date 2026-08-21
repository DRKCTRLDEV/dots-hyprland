#!/usr/bin/env python3

import cv2
import json
import sys

DEFAULT_IMAGE_PATH = '/tmp/quickshell/media/screenshot/image'

def iou(boxA, boxB):
    xA = max(boxA['x'], boxB['x'])
    yA = max(boxA['y'], boxB['y'])
    xB = min(boxA['x'] + boxA['width'], boxB['x'] + boxB['width'])
    yB = min(boxA['y'] + boxA['height'], boxB['y'] + boxB['height'])
    interW = max(0, xB - xA)
    interH = max(0, yB - yA)
    interArea = interW * interH
    boxAArea = boxA['width'] * boxA['height']
    boxBArea = boxB['width'] * boxB['height']
    iou = interArea / float(boxAArea + boxBArea - interArea) if (boxAArea + boxBArea - interArea) > 0 else 0
    return iou

def non_max_suppression(regions, iou_threshold=0.7):
    regions = sorted(regions, key=lambda r: r['width'] * r['height'], reverse=True)
    keep = []
    while regions:
        current = regions.pop(0)
        keep.append(current)
        regions = [r for r in regions if iou(current, r) < iou_threshold]
    return keep

def find_regions(image_path, min_width, min_height, max_width=None, max_height=None):
    image = cv2.imread(image_path)
    if image is None:
        print(f'Error: Could not load image {image_path}', file=sys.stderr)
        sys.exit(1)
    orig_h, orig_w = image.shape[:2]
    resize_factor = 0.1
    image = cv2.resize(image, (int(orig_w * resize_factor), int(orig_h * resize_factor)), interpolation=cv2.INTER_AREA)
    ss = cv2.ximgproc.segmentation.createSelectiveSearchSegmentation()
    ss.setBaseImage(image)
    ss.switchToSelectiveSearchFast(3000, 50, 0.6)
    rects = ss.process()
    regions = []
    for (x, y, w, h) in rects:
        x = int(x / resize_factor)
        y = int(y / resize_factor)
        w = int(w / resize_factor)
        h = int(h / resize_factor)
        if w == orig_w and h == orig_h and x == 0 and y == 0:
            continue
        if w > min_width and h > min_height:
            if (max_width is None or w < max_width) and (max_height is None or h < max_height):
                regions.append({'x': int(x), 'y': int(y), 'width': int(w), 'height': int(h)})
    return non_max_suppression(regions, iou_threshold=0.7)

def main():
    argv = sys.argv[1:]
    image_path = DEFAULT_IMAGE_PATH
    max_width = None
    max_height = None
    hyprctl = False

    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == '--image' and i + 1 < len(argv):
            image_path = argv[i + 1]
            i += 2
        elif arg == '--max-width' and i + 1 < len(argv):
            max_width = int(argv[i + 1])
            i += 2
        elif arg == '--max-height' and i + 1 < len(argv):
            max_height = int(argv[i + 1])
            i += 2
        elif arg == '--hyprctl':
            hyprctl = True
            i += 1
        else:
            i += 1

    regions = find_regions(
        image_path,
        min_width=200,
        min_height=100,
        max_width=max_width,
        max_height=max_height,
    )
    if hyprctl:
        regions = [{"at": [r['x'], r['y']], "size": [r['width'], r['height']]} for r in regions]
    print(json.dumps(regions))

if __name__ == '__main__':
    main()
