function varargout = prettyplot(varargin, opts)
% PRETTYPLOT - Restyle figures with the lab plot style.
%   prettyplot() styles the current figure with the default rules.
%   prettyplot(target, "Key", value, ...) styles a figure, tiled layout,
%   axes, legend, colorbar, or an array of them, and the given rules
%   override the defaults. prettyplot(config, ...) reads rules from a dict,
%   struct, dictionary, or N-by-2 cell, as does the config option.
%
%   A key is "Property" or "Seg.Seg.Property". A "(Class)" segment matches
%   a class name or Type, such as "(ColorBar)" or "(Text)". A bare segment
%   matches how an object is reached from its parent: XAxis, YAxis, ZAxis,
%   ThetaAxis, RAxis, Ruler, XLabel, YLabel, ZLabel, Title, Subtitle,
%   Label, Legend, Colorbar, or Tile<n>. Segments name the direct parent
%   chain, names ignore case, and * matches any text. A value "@name" runs
%   a handler instead of setting the property. See docs/prettyplot.md.
%
%   report = prettyplot(...) returns a table of every property it set.

    arguments (Repeating)
        varargin
    end

    arguments
        opts.config = []
        opts.white_background logical = true
        opts.debug logical = false
        opts.figsize double = []
        opts.figsize_units (1, 1) string {mustBeMember(opts.figsize_units, ["inches", "centimeters", "points"])} = "inches"
        % deprecated, accepted and ignored
        opts.strict
        opts.masks
        opts.auto_update
        opts.MAX_RECUR_LEVEL
    end

    pp_start = tic;

    deprecated = ["strict", "masks", "auto_update", "MAX_RECUR_LEVEL"];
    passed = deprecated(isfield(opts, deprecated));
    if ~isempty(passed)
        warning( ...
            "MMGA:prettyplot:deprecatedOption", ...
            "[prettyplot] %s no longer has an effect and is ignored; see docs/prettyplot.md", ...
            strjoin(passed, ", ") ...
        );
    end

    if ~isempty(opts.figsize) && (numel(opts.figsize) ~= 2 || any(~isfinite(opts.figsize)) || any(opts.figsize <= 0))
        error("MMGA:prettyplot:invalidFigsize", "figsize must be [width height] with positive values");
    end

    [targets, rules] = parse_inputs(varargin, opts.config);
    report = empty_report();
    if isempty(targets)
        fprintf("[prettyplot] found no figure\n");
        if nargout > 0
            varargout{1} = report;
        end
        return
    end

    nodes = collect_nodes(targets);
    figs = owning_figures(targets);

    % pin before anything changes the layout, so manual labels keep the
    % ticks they were written for
    if isempty(opts.figsize)
        pin_manual_ticks(nodes);
    else
        pin_manual_ticks(collect_nodes(figs));
    end

    if opts.white_background
        apply_background(figs);
    end

    if ~isempty(opts.figsize)
        apply_figsize(figs, opts.figsize(:)', opts.figsize_units);
    end

    report = apply_rules(nodes, rules, opts.debug);

    if opts.debug
        fprintf("[prettyplot] elapsed %.2fs\n", toc(pp_start));
    end

    if nargout > 0
        varargout{1} = report;
    end
end

function [targets, rules] = parse_inputs(args, config)
% Split the positional arguments into targets and rules. Rules from the
% defaults, the config, and the name-value pairs form layers 0, 1, and 2.

    targets = [];
    positional_config = [];
    pairs = args;
    if mod(numel(pairs), 2) == 1
        first = pairs{1};
        pairs = pairs(2:end);
        if is_mapping(first)
            positional_config = first;
        elseif is_target(first)
            targets = first;
        else
            error( ...
                "MMGA:prettyplot:invalidTarget", ...
                "expected a graphics object or a config before the key-value pairs, but got a %s", ...
                class(first) ...
            );
        end
    end

    rules = default_rules();

    has_config = ~isempty(config) && ~(isnumeric(config) && isscalar(config) && isnan(config));
    if has_config
        if ~is_mapping(config)
            error( ...
                "MMGA:prettyplot:invalidArguments", ...
                "config must be a dict, struct, dictionary, or N-by-2 cell, but got a %s", ...
                class(config) ...
            );
        end
        rules = [rules, rules_from_mapping(config, 1, numel(rules))];
    end

    if ~isempty(positional_config)
        rules = [rules, rules_from_mapping(positional_config, 1, numel(rules))];
    end

    if mod(numel(pairs), 2) == 1
        error("MMGA:prettyplot:invalidArguments", "expected key-value pairs, but got an odd number of arguments");
    end

    rules = [rules, rules_from_mapping(reshape(pairs, 2, [])', 2, numel(rules))];

    if isempty(targets)
        targets = groot().CurrentFigure;
    elseif isa(targets, "matlab.ui.Root")
        targets = targets.Children;
    end
    targets = prune_targets(reshape(targets, 1, []));
end

function rules = default_rules()
% The lab style. Tick labels stay automatic: the LaTeX format follows the
% ticks when a resize or font change makes MATLAB recompute them.

    pairs = { ...
        "Box", "on"; ...
        "FontName", "Times New Roman"; ...
        "FontSize", 14; ...
        "(NumericRuler).TickLabelInterpreter", "latex"; ...
        "(NumericRuler).TickLabelFormat", "@latex-num"; ...
        "TickLength", [0.02 0.05]; ...
        "(ColorBar).TickLength", 0.03 ...
    };
    rules = rules_from_mapping(pairs, 0, 0);
end

function rules = rules_from_mapping(mapping, layer, first_order)
% Parse every key of a mapping into a rule.

    [ks, vs] = mapping_items(mapping);
    rules = repmat(make_rule("Box", [], 0, 0), 1, 0);
    for k = 1:numel(ks)
        rules(end + 1) = make_rule(ks{k}, vs{k}, layer, first_order + k); %#ok<AGROW>
    end
end

function [ks, vs] = mapping_items(mapping)
% Return the keys and values of a mapping as two column cells, in order.

    if isa(mapping, "dictionary")
        ks = {};
        vs = {};
        if numEntries(mapping) > 0
            ks = keys(mapping);
            vs = values(mapping);
        end
        if ~iscell(ks)
            ks = num2cell(ks);
        end
        if ~iscell(vs)
            vs = num2cell(vs);
        end
    elseif isstruct(mapping)
        ks = fieldnames(mapping);
        vs = struct2cell(mapping);
    elseif iscell(mapping)
        ks = mapping(:, 1);
        vs = mapping(:, 2);
    else
        ks = mapping.keys();
        vs = mapping.values();
    end

    ks = ks(:);
    vs = vs(:);
end

function rule = make_rule(key, value, layer, order)
% Parse "Seg.Seg.Property" into selector segments and a property pattern.

    if ~(isstring(key) && isscalar(key)) && ~(ischar(key) && (isrow(key) || isempty(key)))
        error("MMGA:prettyplot:invalidKey", "keys must be text, but got a %s", class(key));
    end

    key = string(key);
    parts = strip(split(key, "."));
    if any(strlength(parts) == 0)
        error("MMGA:prettyplot:invalidKey", "key ""%s"" has an empty segment", key);
    end

    segs = struct("kind", {}, "name", {});
    for k = 1:numel(parts) - 1
        part = parts(k);
        if startsWith(part, "(") && endsWith(part, ")") && strlength(part) > 2
            segs(end + 1) = struct("kind", "class", "name", extractBetween(part, 2, strlength(part) - 1)); %#ok<AGROW>
        elseif contains(part, ["(", ")"])
            error("MMGA:prettyplot:invalidKey", "key ""%s"" has a malformed class segment ""%s""", key, part);
        else
            segs(end + 1) = struct("kind", "role", "name", part); %#ok<AGROW>
        end
    end

    prop = parts(end);
    if contains(prop, ["(", ")"])
        error("MMGA:prettyplot:invalidKey", "key ""%s"" must end with a property name", key);
    end

    names = [[segs.name], prop];
    rule = struct( ...
        "key", key, "segs", segs, "prop", prop, "glob", contains(prop, "*"), ...
        "value", {value}, "layer", layer, "nseg", numel(segs), ...
        "nexact", sum(~contains(names, "*")), "order", order ...
    );
end

function r = is_mapping(x)
    r = isa(x, "dictionary") || (isstruct(x) && isscalar(x)) ...
        || (iscell(x) && ismatrix(x) && size(x, 2) == 2) ...
        || (isobject(x) && ~isa(x, "matlab.graphics.Graphics") && ismethod(x, "keys") && ismethod(x, "values"));
end

function r = is_target(x)
    r = ~isempty(x) && isobject(x) && all(isgraphics(x), "all");
end

function r = is_handle(v)
    r = isobject(v) && isscalar(v) && isgraphics(v);
end

function v = member(h, name)
% Return h.(name), or [] when h lacks the property or hides it, as charts
% such as heatmap do with XAxis.

    v = [];
    if isprop(h, name)
        try
            v = h.(name);
        catch
        end
    end
end

function targets = prune_targets(targets)
% Drop repeated targets and targets inside another target, so every
% object is visited once.

    keep = true(1, numel(targets));
    for i = 1:numel(targets)
        for j = 1:i - 1
            if keep(j) && targets(j) == targets(i)
                keep(i) = false;
            end
        end

        p = owner_of(targets(i));
        while keep(i) && ~isempty(p)
            for j = 1:numel(targets)
                if j ~= i && targets(j) == p
                    keep(i) = false;
                end
            end
            p = owner_of(p);
        end
    end

    targets = targets(keep);
end

function p = owner_of(h)
% Return the object that styling reaches h through: the axes of a legend
% or colorbar, or else the parent. Return [] at the root.

    if (isa(h, "matlab.graphics.illustration.Legend") || isa(h, "matlab.graphics.illustration.ColorBar")) ...
        && isprop(h, "Axes") && is_handle(h.Axes)
        p = h.Axes;
    else
        p = h.Parent;
    end

    if ~is_handle(p) || isa(p, "matlab.ui.Root")
        p = [];
    end
end

function figs = owning_figures(targets)
    figs = matlab.ui.Figure.empty();
    for k = 1:numel(targets)
        f = ancestor(targets(k), "figure");
        if ~isempty(f) && ~any(figs == f)
            figs(end + 1) = f; %#ok<AGROW>
        end
    end
end

function nodes = collect_nodes(targets)
% Walk each target's tree, parents before their parts, and record the path
% of roles and classes that selectors match against.

    nodes = struct("h", {}, "path", {}, "owner", {}, "part", {});
    for k = 1:numel(targets)
        h = targets(k);
        nodes = visit(nodes, h, ancestor_path(h), root_role(h), 0, "", 0);
    end
end

function path = ancestor_path(h)
    p = owner_of(h);
    if isempty(p)
        path = make_seg([], "", 0);
        path(:) = [];
    else
        path = [ancestor_path(p), make_seg(p, root_role(p), 0)];
    end
end

function role = root_role(h)
    if isa(h, "matlab.graphics.illustration.Legend") && ~isempty(owner_of(h)) && isprop(h, "Axes")
        role = "Legend";
    elseif isa(h, "matlab.graphics.illustration.ColorBar") && ~isempty(owner_of(h)) && isprop(h, "Axes")
        role = "Colorbar";
    else
        role = tile_role(h);
    end
end

function role = tile_role(h)
    role = "";
    if isa(h.Parent, "matlab.graphics.layout.TiledChartLayout") && isprop(h, "Layout") && isprop(h.Layout, "Tile")
        tile = h.Layout.Tile;
        if isnumeric(tile) && isscalar(tile)
            role = "Tile" + tile;
        end
    end
end

function seg = make_seg(h, role, index)
    if isempty(h)
        seg = struct("role", "", "cls", "", "type", "", "label", "");
        return
    end

    cls = split(string(class(h)), ".");
    cls = cls(end);
    type = "";
    if isprop(h, "Type")
        type = string(h.Type);
    end

    label = type;
    if label == ""
        label = cls;
    end
    if startsWith(role, "Tile")
        label = label + "[" + role + "]";
    elseif role ~= ""
        label = role;
    elseif index > 0
        label = label + "(" + index + ")";
    end

    seg = struct("role", role, "cls", cls, "type", type, "label", label);
end

function nodes = visit(nodes, h, path, role, owner, part, index)
    node_path = [path, make_seg(h, role, index)];
    nodes(end + 1) = struct("h", h, "path", node_path, "owner", owner, "part", part);
    self = numel(nodes);

    if part ~= ""
        return
    end

    % rulers before text: a ruler's FontSize resets its label's
    ruler_roles = ["XAxis", "YAxis", "ZAxis", "ThetaAxis", "RAxis", "Ruler"];
    rulers = {};
    ruler_names = strings(1, 0);
    for name = ruler_roles
        value = member(h, name);
        for k = 1:numel(value)
            if is_handle(value(k))
                nodes = visit(nodes, value(k), node_path, name, self, "ruler", 0);
                rulers{end + 1} = value(k); %#ok<AGROW>
                ruler_names(end + 1) = name; %#ok<AGROW>
            end
        end
    end
    is_axes = ~isempty(ruler_names) && all(ruler_names ~= "Ruler");

    % an axes takes its labels from the rulers, which finds both yyaxis
    % labels; a colorbar's ruler label is the colorbar's own Label
    text_roles = ["Title", "Subtitle"];
    if is_axes
        for k = 1:numel(rulers)
            label = member(rulers{k}, "Label");
            if is_handle(label)
                nodes = visit(nodes, label, node_path, replace(ruler_names(k), "Axis", "Label"), self, "text", 0);
            end
        end
    else
        text_roles = [text_roles, "XLabel", "YLabel", "ZLabel", "Label"];
    end

    for name = text_roles
        value = member(h, name);
        if is_handle(value)
            nodes = visit(nodes, value, node_path, name, self, "text", 0);
        end
    end

    if is_axes
        lgd = member(h, "Legend");
        if is_handle(lgd)
            nodes = visit(nodes, lgd, node_path, "Legend", self, "", 0);
        end
        for cb = axes_colorbars(h)
            nodes = visit(nodes, cb, node_path, "Colorbar", self, "", 0);
        end
    end

    % legends and colorbars are children of the layout or figure, but
    % they are reached through their axes above
    kids = member(h, "Children");
    keep = true(numel(kids), 1);
    for k = 1:numel(kids)
        keep(k) = ~isa(kids(k), "matlab.graphics.illustration.Legend") ...
            && ~isa(kids(k), "matlab.graphics.illustration.ColorBar");
    end
    kids = flipud(kids(keep));

    types = strings(numel(kids), 1);
    for k = 1:numel(kids)
        if isprop(kids(k), "Type")
            types(k) = string(kids(k).Type);
        end
    end

    for k = 1:numel(kids)
        index = 0;
        if sum(types == types(k)) > 1
            index = sum(types(1:k) == types(k));
        end
        nodes = visit(nodes, kids(k), node_path, tile_role(kids(k)), self, "", index);
    end
end

function cbs = axes_colorbars(ax)
    cbs = matlab.graphics.illustration.ColorBar.empty(1, 0);
    if isprop(ax, "Colorbar")
        cb = member(ax, "Colorbar");
        if is_handle(cb)
            cbs = cb;
        end
        return
    end

    % releases without Axes.Colorbar: find colorbars that point at ax
    if ~isprop(ax, "Parent") || ~is_handle(ax.Parent)
        return
    end
    for c = reshape(ax.Parent.Children, 1, [])
        if isa(c, "matlab.graphics.illustration.ColorBar") && isprop(c, "Axes") && c.Axes == ax
            cbs(end + 1) = c; %#ok<AGROW>
        end
    end
end

function pin_manual_ticks(nodes)
% A ruler with manual labels but automatic ticks reuses its labels on
% whatever ticks MATLAB recomputes after a resize, so pin the ticks.

    for k = 1:numel(nodes)
        r = nodes(k).h;
        if nodes(k).part ~= "ruler" || ~isprop(r, "TickLabelsMode") || ~isprop(r, "TickValuesMode")
            continue
        end
        if r.TickLabelsMode == "manual" && r.TickValuesMode == "auto"
            r.TickValues = r.TickValues;
        end
    end
end

function apply_background(figs)
    for f = figs
        % a dark theme keeps light text, which vanishes on white
        if isprop(f, "Theme") && isobject(f.Theme) && isprop(f.Theme, "BaseColorStyle") ...
            && f.Theme.BaseColorStyle == "dark"
            f.Theme = "light";
        end
        f.Color = "white";
    end
end

function apply_figsize(figs, figsize, units)
    for f = figs
        if isprop(f, "WindowStyle") && f.WindowStyle == "docked"
            warning("MMGA:prettyplot:figsizeNotApplied", "[prettyplot] figsize does not apply to a docked figure");
            continue
        end

        old_units = f.Units;
        restore = onCleanup(@() set(f, "Units", old_units));
        f.Units = units;
        pos = f.Position;
        f.Position = [pos(1), pos(2) + pos(4) - figsize(2), figsize];
        f.PaperUnits = units;
        f.PaperSize = figsize;
        f.PaperPositionMode = "auto";

        got = f.Position(3:4);
        if any(abs(got - figsize) > 1e-3 * max(figsize))
            warning( ...
                "MMGA:prettyplot:figsizeNotApplied", ...
                "[prettyplot] asked for a %gx%g %s figure but got %gx%g; it may not fit on the screen", ...
                figsize(1), figsize(2), units, got(1), got(2) ...
            );
        end
        clear restore
    end
end

function report = apply_rules(nodes, rules, debug)
% Pick the winning rule for each property of each node, set the plain
% values in tree order, then run the handlers.

    num_nodes = numel(nodes);
    winners = cell(1, num_nodes);
    prop_cache = dictionary(string.empty(), {});
    matched = false(1, numel(rules));

    for i = 1:num_nodes
        h = nodes(i).h;
        win = dictionary(string.empty(), []);
        names = dictionary(string.empty(), string.empty());
        for r = 1:numel(rules)
            if ~match_segs(rules(r).segs, nodes(i).path)
                continue
            end

            [props, prop_cache] = matching_props(rules(r), h, prop_cache);
            for p = props
                key = lower(p);
                if isKey(win, key) && ~stronger(rules(r), rules(win(key)), true)
                    continue
                end
                win(key) = r;
                names(key) = p;
            end
        end

        % a part follows its owner for the properties the owner passes
        % down, unless the part's own rule outranks the owner's
        inherited = inherited_props(nodes(i).part);
        owner = nodes(i).owner;
        if ~isempty(inherited) && owner > 0 && numEntries(win) > 0
            owner_win = winners{owner}.win;
            for key = keys(win)'
                if ~any(lower(inherited) == key) || ~isprop(nodes(owner).h, key) || ~isKey(owner_win, key)
                    continue
                end
                ro = owner_win(key);
                rp = win(key);
                if ro == rp || stronger(rules(ro), rules(rp), false)
                    win(key) = [];
                end
            end
        end

        winners{i} = struct("win", win, "names", names);
        if numEntries(win) > 0
            matched(values(win)) = true;
        end
    end

    rows = cell(0, 4);
    deferred = cell(0, 3);
    for i = 1:num_nodes
        win = winners{i}.win;
        if numEntries(win) == 0
            continue
        end

        % within one object, follow the order the rules were given in
        props = keys(win);
        ridx = values(win);
        [~, idx] = sortrows([[rules(ridx).layer]', [rules(ridx).order]']);
        for k = idx'
            prop = winners{i}.names(props(k));
            rule = rules(ridx(k));
            [kind, value] = classify_value(rule.value, prop);
            switch kind
                case "handler"
                    deferred(end + 1, :) = {i, prop, ridx(k)}; %#ok<AGROW>
                case "value"
                    if set_value(nodes(i), prop, value, rule)
                        rows(end + 1, :) = {node_path_label(nodes(i)), prop, value, rule.key}; %#ok<AGROW>
                    end
            end
        end
    end

    % handlers see every plain value, such as the interpreter, already set;
    % the report shows the value a handler leaves
    for k = 1:size(deferred, 1)
        [i, prop, r] = deferred{k, :};
        try
            ran = run_handler(nodes(i), prop, rules(r));
        catch err
            ran = false;
            warning( ...
                "MMGA:prettyplot:handlerFailed", ...
                "[prettyplot] the handler of rule ""%s"" failed on %s.%s: %s", ...
                rules(r).key, node_path_label(nodes(i)), prop, err.message ...
            );
        end
        if ran
            rows(end + 1, :) = {node_path_label(nodes(i)), prop, get(nodes(i).h, prop), rules(r).key}; %#ok<AGROW>
        end
    end

    warn_unknown_props(nodes, rules, matched, debug);

    report = empty_report();
    if ~isempty(rows)
        report = table( ...
            string(rows(:, 1)), string(rows(:, 2)), rows(:, 3), string(rows(:, 4)), ...
            VariableNames = ["Path", "Property", "Value", "Rule"] ...
        );
    end

    if debug
        for k = 1:height(report)
            fprintf( ...
                "[prettyplot] %s: %s = %s  <- ""%s""\n", ...
                report.Path(k), report.Property(k), short_value(report.Value{k}), report.Rule(k) ...
            );
        end
    end
end

function r = match_segs(segs, path)
% Match the selector segments against the last nodes of the path, as a
% chain of direct parents.

    k = numel(segs);
    n = numel(path);
    r = k <= n;
    j = 1;
    while r && j <= k
        node = path(n - k + j);
        if segs(j).kind == "class"
            r = name_match(segs(j).name, node.cls) || name_match(segs(j).name, node.type);
        else
            r = name_match(segs(j).name, node.role);
        end
        j = j + 1;
    end
end

function r = name_match(pattern, name)
    if name == ""
        r = false;
    elseif contains(pattern, "*")
        r = ~isempty(regexp(name, "^" + regexptranslate("wildcard", pattern) + "$", "once", "ignorecase"));
    else
        r = strcmpi(pattern, name);
    end
end

function [props, cache] = matching_props(rule, h, cache)
% Return the properties of h that the rule's property pattern names.

    cls = string(class(h));
    if ~isKey(cache, cls)
        cache(cls) = {string(properties(h))'};
    end
    all_props = cache(cls);
    all_props = all_props{1};

    if rule.glob
        props = all_props(arrayfun(@(p) name_match(rule.prop, p), all_props));
    elseif isprop(h, rule.prop)
        % use MATLAB's spelling; hidden properties keep the rule's
        props = all_props(strcmpi(all_props, rule.prop));
        if isempty(props)
            props = rule.prop;
        end
    else
        props = strings(1, 0);
    end
end

function r = stronger(a, b, use_order)
% Compare rules by layer, then segments, then exact names, then order.

    ka = [a.layer, a.nseg, a.nexact];
    kb = [b.layer, b.nseg, b.nexact];
    if use_order
        ka(end + 1) = a.order;
        kb(end + 1) = b.order;
    end

    d = find(ka ~= kb, 1);
    r = ~isempty(d) && ka(d) > kb(d);
end

function props = inherited_props(part)
% Properties that an axes or colorbar passes down to its parts.

    switch part
        case "text"
            props = ["FontSize", "FontName"];
        case "ruler"
            props = [ ...
                "FontSize", "FontName", "FontAngle", "FontWeight", "LineWidth", ...
                "TickLabelInterpreter", "TickLength", "TickDirection" ...
            ];
        otherwise
            props = strings(1, 0);
    end
end

function [kind, value] = classify_value(value, prop)
% "@name" and function handles run as handlers, except that callback
% properties take a function handle as their value; "@@" escapes "@".

    kind = "value";
    if is_text_scalar(value) && startsWith(value, "@@")
        value = extractAfter(value, 1);
    elseif is_text_scalar(value) && startsWith(value, "@")
        kind = "handler";
    elseif isa(value, "function_handle") && ~endsWith(prop, ["Fcn", "Callback"], IgnoreCase = true)
        kind = "handler";
    end
end

function r = is_text_scalar(v)
    r = (isstring(v) && isscalar(v)) || (ischar(v) && isrow(v));
end

function ok = set_value(node, prop, value, rule)
    ok = true;
    try
        set(node.h, prop, value);
    catch err
        ok = false;
        warning( ...
            "MMGA:prettyplot:setFailed", ...
            "[prettyplot] could not set %s.%s from rule ""%s"": %s", ...
            node_path_label(node), prop, rule.key, err.message ...
        );
    end
end

function ok = run_handler(node, prop, rule)
    ok = true;
    if isa(rule.value, "function_handle")
        rule.value(node.h, prop);
        return
    end

    name = replace(extractAfter(string(rule.value), 1), "-", "_");
    switch name
        case "latex_num"
            latex_num(node.h, prop);
        otherwise
            ok = false;
            warning( ...
                "MMGA:prettyplot:unknownHandler", ...
                "[prettyplot] rule ""%s"" names handler ""%s"", which does not exist", ...
                rule.key, rule.value ...
            );
    end
end

function warn_unknown_props(nodes, rules, matched, debug)
% A user rule whose property no object has is most likely a typo.

    for r = find(~matched)
        rule = rules(r);
        if rule.layer == 0
            continue
        end

        exists = rule.glob;
        for i = 1:numel(nodes)
            if exists
                break
            end
            exists = isprop(nodes(i).h, rule.prop);
        end

        if ~exists
            warning( ...
                "MMGA:prettyplot:unknownProperty", ...
                "[prettyplot] no styled object has a property named ""%s"" (rule ""%s"")", ...
                rule.prop, rule.key ...
            );
        elseif debug
            fprintf("[prettyplot] rule ""%s"" matched no object\n", rule.key);
        end
    end
end

function label = node_path_label(node)
    label = strjoin([node.path.label], "/");
end

function report = empty_report()
    report = table( ...
        strings(0, 1), strings(0, 1), cell(0, 1), strings(0, 1), ...
        VariableNames = ["Path", "Property", "Value", "Rule"] ...
    );
end

function s = short_value(v)
    if isa(v, "function_handle")
        s = func2str(v);
    elseif isstring(v) || ischar(v)
        s = """" + strjoin(string(v), """, """) + """";
    elseif (isnumeric(v) || islogical(v)) && numel(v) <= 16
        s = string(mat2str(v, 4));
    else
        try
            s = strjoin(string(v), ", ");
        catch
            s = "<" + class(v) + ">";
        end
    end
end

function latex_num(ruler, prop)
% @latex-num: write automatic tick labels in LaTeX math. Only MATLAB's
% default formats change, so custom formats and manual labels stay.

    if ~isa(ruler, "matlab.graphics.axis.decorator.NumericRuler") || ~strcmpi(prop, "TickLabelFormat") ...
        || ruler.TickLabelInterpreter ~= "latex"
        return
    end

    switch string(ruler.TickLabelFormat)
        case "%g"
            ruler.TickLabelFormat = "$%g$";
        case "%g" + char(176)
            % the format goes through sprintf, so the backslash is doubled
            ruler.TickLabelFormat = "$%g^{\\circ}$";
    end
end
