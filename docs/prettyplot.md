# prettyplot

`prettyplot` applies the lab plot style to a finished figure. Call it after
plotting, labeling, and adding legends and colorbars, since it styles only
the objects that exist.

```matlab
t = tiledlayout(1, 2);
plot(nexttile(t), x, y);
xlabel("time (s)");
imagesc(nexttile(t), Z);
colorbar();

prettyplot();                                   % the current figure, lab defaults
prettyplot(gcf, "FontSize", 12);                % override a default
prettyplot(gcf, "Tile2.FontSize", 10);          % only the axes in tile 2
prettyplot(gcf, "(ColorBar).TickLength", 0.02); % only colorbars
prettyplot(gcf, size = [3.5 2.6]);              % 3.5 x 2.6 inches
report = prettyplot(gcf);                       % table of every property set
```

Tick labels stay automatic. The LaTeX number format lives on each axis ruler,
so resizing the window, changing a font size, or exporting at another size
recomputes the ticks and their labels together.

## Calls

```matlab
prettyplot(target, "Key", value, ..., name = value)
prettyplot(config, "Key", value, ..., name = value)
```

- `target` is a figure, tiled layout, axes, legend, colorbar, or an array of
  them, such as `[ax1 ax3]`. Without one, `prettyplot` styles
  `groot().CurrentFigure` and never creates a figure.
- `config` and the `config` option take rules as a dict, struct, `dictionary`,
  or N-by-2 cell. A struct cannot hold keys with dots or parentheses.
- The key-value pairs after the target are rules too.

| Option | Default | Meaning |
| --- | --- | --- |
| `config` | `[]` | Rules that override the defaults |
| `white_background` | `true` | White figure; switches a dark theme to light first |
| `size` | `[]` | `[width height]` of the figure, as matplotlib's `figsize` |
| `size_unit` | `"in"` | `"in"`, `"cm"`, or `"pt"` |
| `debug` | `false` | Print every property set and the elapsed time |

`size` resizes each figure that holds a target, even when the target is an
axes. It also sets the paper size, so `print` and `saveas` match the screen
size. A docked figure, or one larger than the screen, may not take the size;
`prettyplot` then warns with `MMGA:prettyplot:sizeNotApplied`. A `size` that
is not two positive numbers throws `MMGA:prettyplot:invalidSize`.

## Defaults

```matlab
"Box", "on"
"FontName", "Times New Roman"
"FontSize", 14
"(NumericRuler).TickLabelInterpreter", "latex"
"(NumericRuler).TickLabelFormat", "@latex-num"   % %g -> $%g$
"TickLength", [0.02 0.05]
"(ColorBar).TickLength", 0.03
```

Axis labels and titles keep MATLAB's 1.1x size multipliers, so with the
defaults they are 15.4 pt. Legends and colorbars are 14 pt.

## Keys

A key is `Property` or `Segment.Segment.Property`:

- `(Pattern)` matches a class name, such as `ColorBar` or `NumericRuler`, or a
  `Type`, such as `colorbar` or `line`.
- A bare segment matches the role through which an object is reached from its
  parent:

| Role | Object |
| --- | --- |
| `XAxis`, `YAxis`, `ZAxis`, `ThetaAxis`, `RAxis` | An axes ruler; yyaxis has two `YAxis` |
| `XLabel`, `YLabel`, `ZLabel`, `ThetaLabel`, `RLabel` | An axes label; yyaxis has two `YLabel` |
| `Title`, `Subtitle` | The title of an axes, tiled layout, or legend |
| `Legend`, `Colorbar` | The legend or colorbar of an axes |
| `Ruler`, `Label` | A colorbar's ruler and label |
| `Tile<n>` | The child of a tiled layout in tile `n` (the first tile of a span) |

Segments name a chain of direct parents ending at the styled object. Names
ignore case, and `*` matches any text.

| Key | Styles |
| --- | --- |
| `"LineWidth"` | Every object with a `LineWidth`, except rulers (see below) |
| `"(Line).LineWidth"` | Lines |
| `"(Axes).FontSize"` | Cartesian axes only, not `PolarAxes` |
| `"Colorbar.Ruler.TickLabelFormat"` | Colorbar rulers, not the axes rulers |
| `"*Label.Interpreter"` | Every axis and colorbar label |
| `"(Axes).Title.FontWeight"` | Axes titles, not the layout title |
| `"(TiledChartLayout).Title.FontSize"` | The layout title only |
| `"Tile2.FontSize"` | The axes in tile 2 |
| `"Tile2.(Line).Color"` | Lines in tile 2 |
| `"Tile*.Colorbar.TickLength"` | Every tile's colorbar |
| `"Legend.Location"` | Every legend |

A key whose property no styled object has warns with
`MMGA:prettyplot:unknownProperty`, which usually means a typo.

## Which rule wins

1. Rules you pass beat the defaults, and the name-value pairs beat the config.
2. Within one source, a key with more segments wins, then a key with fewer
   `*`, then the later key.

Rulers and labels follow their axes or colorbar. A ruler or a label skips a
rule for a property that its axes or colorbar passes down when the axes or
colorbar took the same rule or a stronger one. Labels inherit `FontSize` and
`FontName`. Rulers also inherit `FontAngle`, `FontWeight`, `LineWidth`,
`TickLabelInterpreter`, `TickLength`, and `TickDirection`. So
`"(Axes).FontSize", 13, "FontSize", 16` gives 13 pt tick labels and 14.3 pt
axis labels, and `"XLabel.FontSize", 18` still sets the label.

## Handlers

A value that starts with `@` runs a handler on each matched object instead of
setting the property:

- `"@latex-num"` turns a numeric ruler's default `%g` format into `$%g$`, and
  a polar `%g°` into `$%g^{\circ}$`, when the ruler uses the LaTeX
  interpreter. It leaves custom formats and manual labels alone.
- A function handle runs as `f(obj, prop)`, as in
  `"(Axes).Tag", @(ax, prop) set(ax, prop, "styled")`. Properties whose names
  end in `Fcn` or `Callback` take a function handle as a plain value.
- `"@@text"` sets the literal text `"@text"`.

An unknown handler warns with `MMGA:prettyplot:unknownHandler`, a handler that
throws warns with `MMGA:prettyplot:handlerFailed`, and a value MATLAB rejects
warns with `MMGA:prettyplot:setFailed`. `prettyplot` goes on with the other
rules.

## Manual tick labels

A ruler with manual labels but automatic ticks, as after `ax.XTickLabel = ...`,
reuses its labels on whatever ticks MATLAB recomputes. `prettyplot` pins the
ticks of such rulers before changing anything, so the labels stay on the
ticks they were written for. `xticks` with `xticklabels` already pins them.

## Migrating from the old prettyplot

- Keys match whole names. `"TickLabel"` used to match `XTickLabel` and
  `YTickLabel` by suffix; write `"*TickLabel"` for that now.
- Drop `"TickLabel", "@latex-num"` from configs. The default rule above
  replaces it and keeps the labels automatic.
- `(Class)` matches the whole class name or `Type`. `"(Bar)"` no longer hits
  `ColorBar` or `ErrorBar`, and `"(Axes)"` no longer hits `PolarAxes`.
- Dotted keys such as `"Legend.Location"` now work. They never matched
  before, so the old defaults `"Label.Interpreter"`, `"Legend.Interpreter"`,
  and `"Legend.Location"` are gone rather than turned on.
- A value MATLAB rejects now warns instead of being truncated to fit, which
  used to corrupt properties such as `XTick` and `Colormap`.
- `strict`, `masks`, `auto_update`, and `MAX_RECUR_LEVEL` are ignored with
  `MMGA:prettyplot:deprecatedOption`. Use a target for `strict`, and drop
  `auto_update`: labels now follow resizes by themselves.
- `figsize` and `figsize_units` are now `size` and `size_unit`, and the unit
  is `"in"`, `"cm"`, or `"pt"`. The old names are no longer options, so they
  warn with `MMGA:prettyplot:unknownProperty` as rules.

## Limitations

- Objects created after the call, such as a legend added later, are not
  styled. Call `prettyplot` again.
- Categorical and datetime rulers keep the TeX interpreter, so their labels
  render in `FontName` rather than LaTeX.
- A colorbar's `TickLength` is one number. A plain `"TickLength", [a b]` that
  you pass overrides the colorbar default too, and MATLAB keeps `a` with a
  warning. Add `"(ColorBar).TickLength"` to keep colorbars separate.
