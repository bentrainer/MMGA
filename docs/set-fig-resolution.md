# set_fig_resolution

`set_fig_resolution` resizes a figure to a width and height in pixels and
centers it on the screen. It never creates a figure. For a size in inches or
centimeters, as for a paper, use `prettyplot(fig, figsize = [w h])`.

```matlab
fig = figure();
set_fig_resolution(fig, 1920, 1080);    % 1920 x 1080, centered
set_fig_resolution(800, 600);           % the current figure
set_fig_resolution();                   % the current figure at 1280 x 720
```

## Calls

```matlab
set_fig_resolution()
set_fig_resolution(width, height)
set_fig_resolution(fig)
set_fig_resolution(fig, width, height, position = "center")
```

| Option | Default | Meaning |
| --- | --- | --- |
| `position` | `"center"` | Where to place the figure; only `"center"` is implemented |

- `width` and `height` default to 1280 and 720.
- Without `fig`, it resizes the current figure. When there is no current
  figure, it warns and does nothing.

## Warnings

| Identifier | Cause |
| --- | --- |
| `MMGA:set_fig_resolution:noFigure` | No `fig` was given and there is no current figure; nothing changes. |
| `MMGA:set_fig_resolution:positionNotImplemented` | `position` is not `"center"`; the figure is centered. |

## Limitations

- Any `position` other than `"center"` warns and centers the figure.
- The figure's `Units` must be `"pixels"`, the default.
