function val = fstr(varargin)
    val = "";
    fstr_regex_pattern = "((?<!\\{)(?<={)).*?((?!\\})(?=}))";

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

            val = val + general_obj_to_str(fchar);

            continue
        end


        len = length(fchar);
        pos = 1;

        [start_idx, end_idx] = regexp(fchar, fstr_regex_pattern);

        for idx = 1:length(start_idx)
            l = start_idx(idx);
            r = end_idx(idx);

            if l-1>pos
                val = val + string(fchar(pos:l-2));
            end
            pos = r+2;

            [var_name, suffix] = parse_f_expr(string(fchar(l:r)));
            if suffix~=""
                suffix = "%" + suffix;
            end

            try
                obj = evalin("caller", var_name);
                str = obj_to_str(obj, suffix);
            catch ME
                warning("fstr: failed to eval '%s' with error '%s'", var_name, general_obj_to_str(ME));
                str = "";
            end

            val = val + str;

        end

        % handle the content after the last f_expr
        if pos<=len
            val = val + string(fchar(pos:len));
        end


    end

end


function val = general_obj_to_str(obj)
    val = strip(formattedDisplayText(obj, LineSpacing="compact", SuppressMarkup=true, UseTrueFalseForLogical=true));
end


function [var_name, suffix] = parse_f_expr(f_expr)
    suffix = "";

    f_expr = split(f_expr, ":");
    var_name = f_expr(1);

    if length(f_expr)>1
        suffix = join(f_expr(2:end), ":");
    end
end


function val = obj_to_str(obj, format_operator)

    if format_operator~=""
        val = sprintf(format_operator, obj);
    else

        % TODO: check class to dispatch
        val = general_obj_to_str(obj);

    end

end