function prettyplot(varargin, opts)

    arguments (Repeating)
        varargin
    end

    arguments
        opts.config = nan
        opts.strict logical = false
        opts.masks = ["CurrentAxes", "Parent"]
        opts.debug logical = false
        opts.auto_update logical = true
        opts.white_background logical = true
    end


    pp_start = tic;

    if opts.debug
        fprintf("[prettyplot] varargin =");
        disp(varargin);
    end

    obj_name = "fig";
    offset = mod(length(varargin), 2);

    if offset==1
        fig = varargin{1};
    else
        if isempty(groot().Children)
            fprintf("[prettyplot] found no figure\n");
            return
        else
            fig = gcf();
        end
    end

    if opts.white_background
        fig.Color = "White";
    end

    if isnan(opts.config)
        config = get_default_config();
    elseif class(opts.config)=="dict"
        config = opts.config;
    else
        config = get_default_config();
        warning("[prettyplot] unknown config type: %s", string(class(opts.config)));
    end

    for i = 1+offset:length(varargin)
        if mod(i-offset, 2)==1
            k = varargin{i};
        else
            v = varargin{i};
            config.update(k, v);
        end
    end

    if opts.debug
        fprintf("\n[prettyplot] config =\n");
        disp(config.items());
    end

    % plot, subplot -> fig.Children(:) -> Axes
    % tiledlayout   -> fig.Children().Children(:) -> Axes
    %                              ↑ TiledChartLayout
    prefix = ternary( ...
        opts.strict, ...
        ternary( ...
            string(class(fig.Children))=="matlab.graphics.layout.TiledChartLayout", ...
            sprintf("%s.Children.Children", obj_name), ...
            sprintf("%s.Children", obj_name) ...
        ), ...
        "" ...
    );


    % make sure the TickLabels are correct after changing the font size
    for k = 1:2
        recursive_set( ...
            fig, config, ...
            prefix=prefix, ...
            masks=opts.masks, ...
            stack=obj_name, ...
            debug=opts.debug ...
        );
    end

    function size_changed_callback_func(fig, event)
        if event.EventName~="SizeChanged"
            return
        end
        try
            recursive_set( ...
                fig, config, ...
                prefix=prefix, ...
                masks=opts.masks, ...
                stack=obj_name, ...
                debug=opts.debug ...
            );
        catch ME
            disp(ME);
        end
    end
    if opts.auto_update && isempty(fig.SizeChangedFcn)
        fig.SizeChangedFcn = @size_changed_callback_func;
    end

    if opts.debug
        fprintf("[prettyplot] elapsed %.2fs\n", toc(pp_start));
    end

end


function recursive_set(obj, config, opts)

    arguments
        obj
        config
        opts.prefix = ""
        opts.level = 0
        opts.masks = ["CurrentAxes", "Parent"]
        opts.stack = "obj"
        opts.debug = false
    end


    if ~isobject(obj) || isstring(obj)
        return
    end

    if ~isscalar(obj) && ~ischar(obj)
        for k = 1:numel(obj)
            recursive_set( ...
                obj(k), config, ...
                prefix=opts.prefix, ...
                level=opts.level, ...
                masks=opts.masks, ...
                stack=sprintf("%s(%d)", opts.stack, k), ...
                debug=opts.debug ...
            );
        end
        return
    end

    obj_fields = fields(obj);
    cfg_fields = config.keys();
    masks = dictionary(opts.masks, true(size(opts.masks)));

    for i = 1:length(obj_fields)
        k = obj_fields{i};
        field_value = obj.(k);

        if masks.isKey(k)
            continue
        end

        current_stack = sprintf("%s.%s", opts.stack, k);

        for ci = 1:length(cfg_fields)
            ck = cfg_fields{ci};
            if startsWith(opts.stack, opts.prefix) && endsWith(k, ck)
                new_value = config.get(ck);

                if isstrlike(new_value) && startsWith(new_value, "@")
                    new_value = char(new_value);
                    new_value = string(new_value(2:end));
                    func_name = replace(new_value, "-", "_");
                    if ~exist(func_name, "file")
                        warning("[prettyplot] ""%s"" in config is set to ""@%s"", which no corresponding function is found", ...
                            ck, new_value ...
                        );
                        continue
                    end

                    command = sprintf("%s(obj, ""%s"")", func_name, k);
                    if opts.debug
                        fprintf("[prettyplot] run %s\n", replace(command, "(obj", ...
                            sprintf("(%s", opts.stack) ...
                        ));
                    end

                    eval(command);
                elseif is_same_shape(field_value, new_value)
                    if opts.debug
                        fprintf("[prettyplot] %s = %s\n", current_stack, sdisp(new_value));
                    end
                    obj.(k) = new_value;
                else
                    % warning("failed to set %s.%s: incompatible size %s <-> %s", ...
                    %     opts.stack, k, size_str(v), size_str(new_value) ...
                    % );
                    fprintf("[prettyplot] %s = %s(%s) incompatible with %s(%s)\n", ...
                        current_stack, ...
                        sdisp(field_value), size_str(field_value), ...
                        sdisp(new_value), size_str(new_value) ...
                    );
                end
            end
        end

        recursive_set( ...
            field_value, config, ...
            prefix=opts.prefix, ...
            level=opts.level+1, ...
            masks=opts.masks, ...
            stack=current_stack, ...
            debug=opts.debug ...
        );
    end
end


function config = get_default_config()
    config = dict( ...
        "Box", "on", ...
        "FontName", "Times New Roman", ...
        "FontSize", 14, ...
        "Legend.Location", "best", ...
        "Legend.Interpreter", "latex", ...
        "TickLabel", "@latex-num", ...
        "TickLabelInterpreter", "latex", ...
        "TickLength", [0.02 0.05], ...
        "Label.Interpreter", "latex" ...
    );
end


function r = ternary(cond, a, b)
    if logical(cond)
        r = a;
    else
        r = b;
    end
end

function r = isstrlike(v)
    r = ischar(v) || isstring(v);
end

function r = is_same_shape(a, b)
    if isstrlike(a) && isstrlike(b)
        r = true;
    elseif ndims(a)==ndims(b)
        for k = 1:ndims(a)
            if size(a, k)~=size(b, k)
                r = false;
                return
            end
        end
        r = true;
    else
        r = false;
    end
end

function s = sdisp(v)
    s = formattedDisplayText( ...
        v, ...
        LineSpacing="compact", ...
        UseTrueFalseForLogical=true ...
    );
    s = strip(s);
end

function s = size_str(v)
    s = sprintf("%d", size(v, 1));
    for k = 2:ndims(v)
        s = sprintf("%sx%d", s, size(v, k));
    end
end


function safe_eval(command)
    evalin("caller", command);
end

function thresh = threshold()
    thresh = 1e-8;
end

function latex_num(obj, key)
    vals = obj.(key);
    if endsWith(key, "Label")
        data_key = char(key);
        data_key = string(data_key(1:end-5));

        if isprop(obj, data_key)
            data = obj.(data_key);
            data_scale = "linear";

            for k = 2:length(data)
                % TODO: more robust implementation
                if data(k-1)>0 && data(k)>0 && abs(log10(data(k)/data(k-1)))>0.99
                    data_scale = "log";
                    break
                end
            end

            for k = 1:min(length(data), length(vals))
                if strlength(vals{k})>0
                    vals{k} = num_to_latex(data(k), scale=data_scale);
                end
            end

            obj.(key) = vals;
            return
        end
    end
end

function r = is_latex_str(s)
    r = contains(s, "$");
end

function ls = num_to_latex(v, opts)

    arguments
        v
        opts.scale string = "linear"
    end

    if opts.scale=="log"
        ls = sprintf("%.2e", v);
    else
        ls = num2str(v);
    end

    ls = lower(ls);
    if contains(ls, "e")
        s_parts = split(ls, "e");
        l = s_parts{1};
        r = s_parts{end};

        if abs(str2double(l)-1)<threshold
            ls = sprintf("10^{%d}", str2double(r));
        else
            ls = sprintf("%s\\times10^{%d}", l, str2double(r));
        end
    end

    ls = sprintf("$%s$", ls);
end