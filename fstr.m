function val = fstr(varargin)
    % convert a Python like f-string into string,
    % accept multiple f-string input.
    % Example: A=rand(2, 3); fstr("A={A}")

    % Internal functions:
    % disp_str: wrapped formattedDisplayText, convert everything into string
    % format_ndim_obj: convert a n-dim matrix into string
    % elem_to_str: convert a scalar into string

    val = "";
    % fstr_regex_pattern = "(?<!{{)(?<={)([^{}]+)(?=})(?!}})";

    for k = 1:nargin
        fchar = varargin{k};

        if isstring(fchar)
            fchar = char(fchar);
        end

        if ~ischar(fchar)
            if k==1
                warning("fstr: expected string but got %s", class(fchar));
            else
                warning("fstr: expected string but got %s at varargin{%d}", class(fchar), k);
            end

            val = val + disp_str(fchar);

            continue
        end


        len = length(fchar);
        pos = 1;

        % [start_idx, end_idx] = regexp(fchar, fstr_regex_pattern);
        [start_idx, end_idx] = find_fstr_pattern(fchar);

        for idx = 1:length(start_idx)
            l = start_idx(idx);
            r = end_idx(idx);

            if l-1>pos
                val = val + safe_sprintf(fchar(pos:l-2));
            end
            pos = r+2;

            % parse the f-expr like {varname} {varname:.3f}
            [var_name, suffix] = parse_f_expr(string(fchar(l:r)));
            if suffix~=""
                % eg. ".3f" -> "%.3f"
                suffix = "%" + suffix;
            end

            if var_name==""
                str = "";
            else
                try
                    obj = evalin("caller", var_name);
                    str = format_ndim_obj(obj, suffix);
                catch ME
                    warning("fstr: failed to eval ""%s"" with error:\n  %s\n%s", var_name, ME.message, stack_str(ME.stack));
                    str = "";
                end
            end

            val = val + str;

        end

        % handle the content after the last f_expr
        if pos<=len
            val = val + safe_sprintf(fchar(pos:len));
        end


    end

end


function val = safe_sprintf(str)
    val = replace(str, "{{", "{");
    val = replace(val, "}}", "}");
    val = sprintf(val);
end


function val = disp_str(obj)
    val = strip(formattedDisplayText(obj, LineSpacing="compact", SuppressMarkup=true, UseTrueFalseForLogical=true));
end


function [start_idx, end_idx] = find_fstr_pattern(fchar)
    len = length(fchar);
    pos = 0;
    depth = 0;

    start_idx = NaN(1, floor(len/2));
    end_idx = NaN(1, floor(len/2));

    if len<2
        return
    end

    % last_char = ' ';
    curr_char = ' ';
    next_char = fchar(1);

    for k = 1:len-1
        last_char = curr_char;
        curr_char = next_char;
        next_char = fchar(k+1);

        if curr_char=='{'
            depth = ternary(next_char=='{', depth+len, depth+1);
            if depth==1
                pos = pos + 1;
                start_idx(pos) = k+1;
            end
        elseif curr_char=='}'
            depth = ternary(last_char=='}', depth-len, depth-1);
            if (depth<=0 && pos>0 && isnan(end_idx(pos)))
                end_idx(pos) = k-1;
            end
        end

        depth = ternary(depth<0, 0, depth);
        % fprintf("%d ", depth);
    end

    if next_char=='}'
        depth = ternary(curr_char=='}', depth-len, depth-1);
        if depth<=0 && pos>0 && isnan(end_idx(pos))
            end_idx(pos) = len-1;
        end
    end

    idx = ~isnan(end_idx);
    start_idx = start_idx(idx);
    end_idx = end_idx(idx);

end


function [var_name, suffix] = parse_f_expr(f_expr)
    suffix = "";

    f_expr = split(f_expr, ":");
    var_name = f_expr(1);

    if length(f_expr)>1
        suffix = join(f_expr(2:end), ":");
    end
end


function val = elem_to_str(v, format_operator)

    arguments
        v
        format_operator string = ""
    end

    if format_operator~=""
        val = sprintf(format_operator, v);
    elseif isnumeric(v)
        val = disp_str(v);
    elseif islogical(v)
        val = ternary(v, "true", "false");
    elseif ischar(v)
        val = sprintf("'%c'", v);
    elseif isstring(v)
        val = sprintf("""%s""", v);
    elseif isstruct(v)
        val = disp_str(v);
    elseif iscell(v)
        val = disp_str(v);
    elseif isa(v, "function_handle")
        val = sprintf("<function handle of %s>", disp_str(v));
    elseif ismethod(v, "disp") || ~isobject(v)
        val = disp_str(v);
    else
        val = sprintf("<%s object>", class(v));
    end

end


function n = max_disp_obj_len(action, new_n)
    arguments
        action string = "GET"
        new_n         = 20
    end
    persistent n_config;
    if action~="GET" || isempty(n_config)
        n_config = new_n;
    end
    n = n_config;
end
function n = truncate_obj_len(action, new_n)
    arguments
        action string = "GET"
        new_n         = 5
    end
    persistent n_config;
    if action~="GET" || isempty(n_config)
        n_config = new_n;
    end
    n = n_config;
end


function val = format_ndim_obj(A, format_operator, depth)

    arguments
        A
        format_operator string = ""
        depth                  = 1
    end

    margin = pad("", depth);
    index_func = @index_first_dim;
    nd_size = flip(size(A));


    if isempty(A)
        val = sprintf("<empty %s>", class(A));
    elseif isscalar(A)
        val = elem_to_str(A, format_operator);
    elseif isvector(A)

        if ischar(A)
            val = sprintf("'%s'", string(A));
            return
        end

        len_A = length(A);
        val = "[";
        if len_A<=max_disp_obj_len
            for k = 1:(length(A)-1)
                val = val + elem_to_str(A(k), format_operator) + ", ";
            end
        else
            for k = 1:truncate_obj_len
                val = val + elem_to_str(A(k), format_operator) + ", ";
            end
            val = val + "..., ";
            for k = (len_A-truncate_obj_len+1):(len_A-1)
                val = val + elem_to_str(A(k), format_operator) + ", ";
            end
        end
        val = val + elem_to_str(A(end), format_operator) + "]";
    else
        val = "[";
        if nd_size(end)<=max_disp_obj_len
            for k = 1:(nd_size(end)-1)
                if k~=1
                    val = val + margin;
                end
                val = val + format_ndim_obj( ...
                    index_func(A, k), ...
                    format_operator, ...
                    depth + 1 ...
                ) + sprintf(",\n");
            end
        else
            for k = 1:truncate_obj_len
                if k~=1
                    val = val + margin;
                end
                val = val + format_ndim_obj( ...
                    index_func(A, k), ...
                    format_operator, ...
                    depth + 1 ...
                ) + sprintf(",\n");
            end
            val = val + margin + sprintf("...,\n");
            % val = val + margin + sprintf("(%d lines)...,\n", nd_size(end) - 2*truncate_obj_len);
            for k = (nd_size(end)-truncate_obj_len+1):(nd_size(end)-1)
                val = val + margin + ...
                    format_ndim_obj( ...
                        index_func(A, k), ...
                        format_operator, ...
                        depth + 1 ...
                    ) + sprintf(",\n");
            end
        end
        val = val + margin + format_ndim_obj( ...
            index_func(A, nd_size(end)), ...
            format_operator, ...
            depth + 1 ...
        ) + "]";
    end

end

function A_sub = index_last_dim(A, k)
    S = struct('type', '()', 'subs', '');
    S.subs = repmat({':'}, 1, ndims(A));
    S.subs{end} = k;

    A_sub = subsref(A, S);
end

function A_sub = index_first_dim(A, k)
    S = struct('type', '()', 'subs', '');
    S.subs = repmat({':'}, 1, ndims(A));
    S.subs{1} = k;

    A_sub = subsref(A, S);
end

function val = stack_str(stack)
    val = "";
    for k = 1:length(stack)
        sk = stack(k);
        val = val + sprintf("  > %s > %s (line %d)\n", sk.file, sk.name, sk.line);
    end
end

function val = ternary(cond, val_true, val_false)
    if logical(cond)
        val = val_true;
    else
        val = val_false;
    end
end