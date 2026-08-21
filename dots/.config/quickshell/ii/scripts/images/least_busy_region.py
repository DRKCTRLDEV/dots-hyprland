#!/usr/bin/env python3

import json
import sys

import cv2
import numpy as np


def center_crop(img, target_w, target_h):
    h, w = img.shape[:2]
    if w == target_w and h == target_h:
        return img
    x1 = max(0, (w - target_w) // 2)
    y1 = max(0, (h - target_h) // 2)
    x2 = x1 + target_w
    y2 = y1 + target_h
    return img[y1:y2, x1:x2]


def scale_to_screen(img, screen_width, screen_height):
    orig_h, orig_w = img.shape[:2]
    scale = max(screen_width / orig_w, screen_height / orig_h)
    new_w = int(orig_w * scale)
    new_h = int(orig_h * scale)
    img = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
    return center_crop(img, screen_width, screen_height)


def region_sum(ii, x1, y1, x2, y2):
    total = ii[y2, x2]
    if x1 > 0:
        total -= ii[y2, x1 - 1]
    if y1 > 0:
        total -= ii[y1 - 1, x2]
    if x1 > 0 and y1 > 0:
        total += ii[y1 - 1, x1 - 1]
    return total


def find_extreme_region(
    img,
    region_width,
    region_height,
    screen_width,
    screen_height,
    horizontal_padding,
    vertical_padding,
    busiest,
    stride=10,
):
    img = scale_to_screen(img, screen_width, screen_height)
    arr = img.astype(np.float64)
    h, w = arr.shape
    stride = max(1, stride)
    if horizontal_padding * 2 >= w or vertical_padding * 2 >= h:
        horizontal_padding = max(0, min(horizontal_padding, (w - 1) // 2))
        vertical_padding = max(0, min(vertical_padding, (h - 1) // 2))
    max_region_w = w - 2 * horizontal_padding
    max_region_h = h - 2 * vertical_padding
    if max_region_w <= 0 or max_region_h <= 0:
        raise ValueError("Image too small for the specified padding.")
    region_width = min(region_width, max_region_w)
    region_height = min(region_height, max_region_h)
    integral = cv2.integral(arr, sdepth=cv2.CV_64F)[1:, 1:]
    integral_sq = cv2.integral(arr**2, sdepth=cv2.CV_64F)[1:, 1:]
    area = region_width * region_height
    best_var = None
    best_coords = (horizontal_padding, vertical_padding)
    x_start = horizontal_padding
    y_start = vertical_padding
    x_end = max(x_start, w - region_width - horizontal_padding + 1)
    y_end = max(y_start, h - region_height - vertical_padding + 1)
    for y in range(y_start, y_end + 1, stride):
        for x in range(x_start, x_end + 1, stride):
            x2 = x + region_width - 1
            y2 = y + region_height - 1
            if x2 >= w or y2 >= h:
                continue
            s = region_sum(integral, x, y, x2, y2)
            s2 = region_sum(integral_sq, x, y, x2, y2)
            mean = s / area
            var = (s2 / area) - (mean**2)
            if best_var is None or (
                (var < best_var) if not busiest else (var > best_var)
            ):
                best_var = var
                best_coords = (x, y)
    return best_coords, best_var


def get_dominant_color(img, x, y, w, h, screen_width, screen_height):
    img = scale_to_screen(img, screen_width, screen_height)
    x = max(0, x)
    y = max(0, y)
    w = max(1, min(w, img.shape[1] - x))
    h = max(1, min(h, img.shape[0] - y))
    region = img[y : y + h, x : x + w]
    if region.size == 0 or region.shape[0] == 0 or region.shape[1] == 0:
        return [0, 0, 0]
    region = region.reshape((-1, 3))
    non_black = region[np.any(region > 10, axis=1)]
    if non_black.shape[0] == 0:
        non_black = region
    region = np.float32(non_black)
    if region.shape[0] < 3:
        return [int(x) for x in np.mean(region, axis=0)]
    criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 10, 1.0)
    K = min(3, region.shape[0])
    _, labels, centers = cv2.kmeans(
        region, K, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS
    )
    counts = np.bincount(labels.flatten())
    dominant = centers[np.argmax(counts)]
    return [int(x) for x in reversed(dominant)]


def main():
    args = sys.argv[1:]
    if len(args) != 8 or args[7] not in ("least", "most"):
        sys.exit(2)
    image_path = args[0]
    screen_width, screen_height, region_width, region_height, padding_x, padding_y = (
        int(x) for x in args[1:7]
    )
    busiest = args[7] == "most"

    gray_img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    color_img = cv2.imread(image_path)
    if gray_img is None or color_img is None:
        sys.stderr.write(f"Image not found: {image_path}\n")
        sys.exit(1)

    coords, variance = find_extreme_region(
        gray_img,
        region_width=region_width,
        region_height=region_height,
        screen_width=screen_width,
        screen_height=screen_height,
        horizontal_padding=padding_x,
        vertical_padding=padding_y,
        busiest=busiest,
    )
    dominant_color = get_dominant_color(
        color_img,
        coords[0],
        coords[1],
        region_width,
        region_height,
        screen_width,
        screen_height,
    )
    dominant_color_hex = "#{:02x}{:02x}{:02x}".format(*dominant_color)
    print(
        json.dumps(
            {
                "center_x": coords[0] + region_width // 2,
                "center_y": coords[1] + region_height // 2,
                "width": region_width,
                "height": region_height,
                "variance": variance,
                "dominant_color": dominant_color_hex,
            }
        )
    )


if __name__ == "__main__":
    main()
