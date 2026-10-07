function pass = test_prettyplot(verbose)

    arguments
        verbose logical = true
    end

    pass = false;
    cases = cell(0, 3);

    close_figs = onCleanup(@() delete(findall(groot(), "Type", "figure", "Tag", "test_prettyplot")));

    % the default look: labels and titles keep MATLAB's 1.1x multipliers
    [f, ax] = new_axes();
    plot(ax, linspace(0, 10, 50), sin(linspace(0, 10, 50)));
    xlabel(ax, "x");
    title(ax, "t");
    legend(ax, "a");
    cb = colorbar(ax);
    cb.Label.String = "c";
    report = prettyplot(f);
    cases(end + 1, :) = {"default font sizes", sprintf("%g %g %g %g %g %g", ...
        ax.FontSize, ax.XLabel.FontSize, ax.Title.FontSize, ax.Legend.FontSize, cb.FontSize, cb.Label.FontSize), ...
        "14 15.4 15.4 14 14 14"};
    cases(end + 1, :) = {"default tick lengths", string(mat2str(ax.TickLength)) + " " + mat2str(cb.TickLength), ...
        "[0.02 0.05] 0.03"};
    cases(end + 1, :) = {"default tick label format", string(ax.XAxis.TickLabelFormat) + " " ...
        + ax.XAxis.TickLabelInterpreter + " " + cb.Ruler.TickLabelFormat, "$%g$ latex $%g$"};
    cases(end + 1, :) = {"tick labels stay automatic", string(ax.XTickLabelMode), "auto"};
    cases(end + 1, :) = {"white background", string(mat2str(f.Color)), "[1 1 1]"};
    cases(end + 1, :) = {"report lists the colorbar tick length", ...
        string(report.Value{report.Path == "figure/axes/Colorbar" & report.Property == "TickLength"}), "0.03"};

    % the old labels were frozen text, so recomputed ticks reused them
    f.Position = [100 100 250 200];
    drawnow();
    cases(end + 1, :) = {"labels follow ticks after a resize", follows_ticks(ax), "true"};
    ax.FontSize = 30;
    drawnow();
    cases(end + 1, :) = {"labels follow ticks after a font change", follows_ticks(ax), "true"};

    [f, ax] = new_axes();
    semilogx(ax, logspace(-2, 3, 20), linspace(0, 3e4, 20));
    prettyplot(f);
    drawnow();
    cases(end + 1, :) = {"log labels", string(all(startsWith(string(ax.XTickLabel), "$10^{"))), "true"};
    cases(end + 1, :) = {"exponent label", string(ax.YAxis.SecondaryLabel.String), "$\times10^{4}$"};

    % the config of a lab script written against the old prettyplot
    [f, ax] = new_axes();
    plot(ax, 1:10);
    xlabel(ax, "x");
    legend(ax, "a");
    prettyplot( ...
        f, ...
        config = dict( ...
            "(Legend).Box", matlab.lang.OnOffSwitchState.off, ...
            "(Axes).FontSize", 13, "(Legend).FontSize", 12, ...
            "(Text).Interpreter", "latex", "(Legend).Interpreter", "latex", ...
            "FontSize", 16, "FontName", "Times New Roman" ...
        ) ...
    );
    cases(end + 1, :) = {"lab config font sizes", sprintf("%g %g %g %g", ...
        ax.FontSize, ax.XLabel.FontSize, ax.Legend.FontSize, ax.XAxis.FontSize), "13 14.3 12 13"};
    cases(end + 1, :) = {"lab config text", string(ax.XLabel.Interpreter) + " " + string(ax.Legend.Box), ...
        "latex off"};

    % colorbar and axes ticks are addressed separately
    [f, ax] = new_axes();
    imagesc(ax, magic(8));
    cb = colorbar(ax);
    hold(ax, "on");
    plot(ax, 1:8, 1:8);
    legend(ax, "m");
    prettyplot(f, "Colorbar.Ruler.TickLabelFormat", "$%.1f$", "(ColorBar).FontSize", 9, "(Bar).FontSize", 5);
    cases(end + 1, :) = {"colorbar ruler only", string(cb.Ruler.TickLabelFormat) + " " ...
        + ax.XAxis.TickLabelFormat, "$%.1f$ $%g$"};
    cases(end + 1, :) = {"(ColorBar) only, (Bar) matches no colorbar", sprintf("%g %g", cb.FontSize, ax.FontSize), ...
        "9 14"};
    prettyplot(f, "Legend.Location", "southwest", "*Label.Interpreter", "latex");
    cases(end + 1, :) = {"role keys", string(ax.Legend.Location) + " " + ax.XLabel.Interpreter + " " ...
        + ax.YLabel.Interpreter + " " + ax.Title.Interpreter, "southwest latex latex tex"};

    % tiles by key and by handle
    f = new_figure();
    t = tiledlayout(f, 2, 2);
    axs = gobjects(1, 4);
    for k = 1:4
        axs(k) = nexttile(t);
        plot(axs(k), 1:10);
        title(axs(k), "t" + k);
    end
    title(t, "T");
    prettyplot(f, "Tile2.FontSize", 20, "(TiledChartLayout).Title.FontSize", 18);
    cases(end + 1, :) = {"Tile2 key", font_sizes(axs), "14 20 14 14"};
    cases(end + 1, :) = {"Tile2 title follows its axes", sprintf("%g", axs(2).Title.FontSize), "22"};
    cases(end + 1, :) = {"layout title only", sprintf("%g %g", t.Title.FontSize, axs(1).Title.FontSize), "18 15.4"};
    prettyplot(axs(3), "FontSize", 9);
    cases(end + 1, :) = {"axes target", font_sizes(axs), "14 20 9 14"};
    prettyplot([axs(1), axs(4)], "FontSize", 11);
    cases(end + 1, :) = {"array target", font_sizes(axs), "11 20 9 11"};
    prettyplot(axs(4), "Tile4.FontSize", 12);
    cases(end + 1, :) = {"tile key on an axes target", font_sizes(axs), "11 20 9 12"};
    prettyplot(f, "Tile*.(Line).LineWidth", 2);
    cases(end + 1, :) = {"lines in every tile", sprintf("%g ", arrayfun(@(a) a.Children.LineWidth, axs)), "2 2 2 2 "};

    % layers first, then specificity, then order
    [f, ax] = new_axes();
    plot(ax, 1:10);
    xlabel(ax, "x");
    prettyplot(f, config = dict("FontSize", 12));
    cases(end + 1, :) = {"config beats default", sprintf("%g", ax.FontSize), "12"};
    prettyplot(f, "FontSize", 13, config = dict("FontSize", 12));
    cases(end + 1, :) = {"name-value beats config", sprintf("%g", ax.FontSize), "13"};
    prettyplot(f, config = dict("(Text).FontSize", 10, "(Axes).FontSize", 11));
    cases(end + 1, :) = {"(Text) before (Axes)", sprintf("%g %g", ax.FontSize, ax.XLabel.FontSize), "11 10"};
    prettyplot(f, config = dict("(Axes).FontSize", 11, "(Text).FontSize", 10));
    cases(end + 1, :) = {"(Text) after (Axes)", sprintf("%g %g", ax.FontSize, ax.XLabel.FontSize), "11 10"};

    % manual labels with automatic ticks get their ticks pinned
    [f, ax] = new_axes();
    plot(ax, 0:10);
    ticks = ax.XTick;
    ax.XTickLabel = compose("L%g", ticks);
    prettyplot(f);
    f.Position = [100 100 250 200];
    drawnow();
    cases(end + 1, :) = {"manual labels keep their ticks", string(ax.XTickMode) + " " + tick_text(ax), ...
        "manual " + strjoin(compose("L%g", ticks), ",")};

    % config sources
    sources = {dict("FontSize", 11), struct("FontSize", 11), dictionary("FontSize", 11), {"FontSize", 11}};
    for k = 1:numel(sources)
        [f, ax] = new_axes();
        prettyplot(f, config = sources{k});
        cases(end + 1, :) = {"config from a " + class(sources{k}), sprintf("%g", ax.FontSize), "11"}; %#ok<AGROW>
    end
    set(groot(), "CurrentFigure", f);
    prettyplot(dict("FontSize", 10));
    cases(end + 1, :) = {"positional config on the current figure", sprintf("%g", ax.FontSize), "10"};

    % handlers
    [f, ax] = new_axes();
    prettyplot(f, "(Axes).Tag", @(obj, prop) set(obj, prop, "handled"), "(Axes).ButtonDownFcn", @(~, ~) 1);
    cases(end + 1, :) = {"function handle handler", string(ax.Tag) + " " + class(ax.ButtonDownFcn), ...
        "handled function_handle"};
    prettyplot(f, "(Axes).Tag", "@@literal");
    cases(end + 1, :) = {"@@ escapes a literal @", string(ax.Tag), "@literal"};

    % figsize sets the size in the given units and restores Units
    f = new_figure();
    axes(f);
    prettyplot(f, figsize = [3.5 2.5]);
    units = string(f.Units);
    f.Units = "inches";
    cases(end + 1, :) = {"figsize", units + " " + mat2str(round(f.Position(3:4), 3)), "pixels [3.5 2.5]"};

    % both yyaxis labels, not only the active side's
    [f, ax] = new_axes();
    yyaxis(ax, "left");
    plot(ax, 1:3);
    ylabel(ax, "L");
    yyaxis(ax, "right");
    plot(ax, 3:-1:1);
    ylabel(ax, "R");
    prettyplot(f, "YLabel.FontWeight", "bold");
    cases(end + 1, :) = {"yyaxis labels", string(ax.YAxis(1).Label.FontWeight) + " " + ax.YAxis(2).Label.FontWeight, ...
        "bold bold"};

    f = new_figure();
    pax = polaraxes(f);
    polarplot(pax, linspace(0, 2 * pi, 50), ones(1, 50));
    prettyplot(f);
    cases(end + 1, :) = {"polar degree labels", string(pax.ThetaTickLabel{2}), "$30^{\circ}$"};

    f = new_figure();
    hm = heatmap(f, magic(3));
    cases(end + 1, :) = {"heatmap chart", error_id(@() prettyplot(f)) + " " + hm.FontSize, "no error 14"};

    num_figs = numel(groot().Children);
    set(groot(), "CurrentFigure", []);
    output = evalc("prettyplot()");
    cases(end + 1, :) = {"no figure", string(strip(output)) + " " + (numel(groot().Children) - num_figs), ...
        "[prettyplot] found no figure 0"};

    % warnings and errors; lastwarn records the identifier while warnings are off
    [f, ax] = new_axes();
    plot(ax, 1:10);
    warn_cases = { ...
        {f, "FontSzie", 3}, "MMGA:prettyplot:unknownProperty"; ...
        {f, "masks", "Parent"}, "MMGA:prettyplot:deprecatedOption"; ...
        {f, "(Axes).XLim", "bad"}, "MMGA:prettyplot:setFailed"; ...
        {f, "FontSize", "@nope"}, "MMGA:prettyplot:unknownHandler"; ...
        {f, "(Axes).Tag", @(~, ~) error("boom")}, "MMGA:prettyplot:handlerFailed" ...
    };
    old_state = warning("off", "all");
    restore = onCleanup(@() warning(old_state));
    for k = 1:height(warn_cases)
        lastwarn("");
        prettyplot(warn_cases{k, 1}{:});
        [~, id] = lastwarn();
        cases(end + 1, :) = {"warning " + warn_cases{k, 2}, string(id), warn_cases{k, 2}}; %#ok<AGROW>
    end
    clear restore

    cases(end + 1, :) = {"invalid key", error_id(@() prettyplot(f, "(Axes.FontSize", 1)), "MMGA:prettyplot:invalidKey"};
    cases(end + 1, :) = {"invalid target", error_id(@() prettyplot(42, "FontSize", 1)), "MMGA:prettyplot:invalidTarget"};
    cases(end + 1, :) = {"invalid figsize", error_id(@() prettyplot(f, figsize = [1 2 3])), ...
        "MMGA:prettyplot:invalidFigsize"};

    % the old recursive walk took about 10 s on this figure
    f = new_figure();
    t = tiledlayout(f, 2, 2);
    [X, Y, Z] = peaks(20);
    surf(nexttile(t), X, Y, Z);
    contourf(nexttile(t), X, Y, Z);
    colorbar();
    imagesc(nexttile(t), Z);
    plot3(nexttile(t), X, Y, Z);
    t0 = tic;
    prettyplot(f);
    elapsed = toc(t0);
    cases(end + 1, :) = {sprintf("2x2 tiled figure in %.2f s", elapsed), string(elapsed < 3), "true"};

    for k = 1:size(cases, 1)
        [label, val, dval] = cases{k, :};

        if verbose
            fprintf("%s ... ", label);
        end

        if ~isstring(val) || ~isscalar(val) || val ~= dval
            fprintf("%s gives ""%s"" rather than ""%s""\n", label, val, dval);
            return
        end

        if verbose
            fprintf("PASSED\n");
        end
    end

    pass = true;
end

function f = new_figure()
    f = figure(Visible = "off", Units = "pixels", Position = [100 100 800 600], Tag = "test_prettyplot");
end

function [f, ax] = new_axes()
    f = new_figure();
    ax = axes(f);
end

function s = tick_text(ax)
    s = strjoin(string(ax.XTickLabel)', ",");
end

function s = follows_ticks(ax)
% MATLAB blanks labels that would overlap; every other label must name
% its own tick

    labels = string(ax.XTickLabel)';
    expected = compose("$%g$", ax.XTick);
    s = string(numel(labels) == numel(expected) && all(labels == expected | labels == ""));
end

function s = font_sizes(axs)
    s = strjoin(string(arrayfun(@(a) a.FontSize, axs)), " ");
end

function id = error_id(f)
    try
        f();
        id = "no error";
    catch err
        id = string(err.identifier);
    end
end
