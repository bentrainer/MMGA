# get_screen_size

`get_screen_size` returns the width and height of the primary screen in
pixels, read from the root `ScreenSize` property.

```matlab
[w, h] = get_screen_size()      % for example, w = 1920 and h = 1080
w = get_screen_size()           % the width only
```

## Calls

```matlab
[w, h] = get_screen_size()
```

## Limitations

- MATLAB measures `ScreenSize` in its own pixels. With display scaling on
  Windows, the result is smaller than the screen's native resolution.
