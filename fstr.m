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
                if isvarname(var_name)
                    obj = evalin("caller", var_name);
                else
                    obj = eval(var_name);
                    disp(obj);
                end
                str = obj_to_str(obj, suffix);
            catch ME
                warning("fstr: failed to eval ""%s"" with error ""%s""", var_name, ME.message);
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


function val = disp_str(obj)
    val = strip(formattedDisplayText(obj, LineSpacing="compact", SuppressMarkup=true, UseTrueFalseForLogical=true));
end


function val = general_obj_to_str(obj)
    if isscalar(obj) && (ismethod(obj, "disp") || ~isobject(obj))
        % use disp output as the result only if:
        % the object overload the disp function
        % OR
        % obj is not an object
        val = disp_str(obj);
    else
        if isscalar(obj)
            val = sprintf("<%s object>", class(obj));
        else
            val = sprintf("[<%s object>...]", class(obj));
        end
    end
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

    val = "";

    if format_operator~=""
        val = sprintf(format_operator, obj);
    else

        format_flag = false;
        for class_name = ["numeric", "logical", "char", "string", "struct", "cell", "function_handle"]
            if eval(sprintf("is%s(obj)", class_name))
                fprintf("is%s(obj)\n", class_name);
                val = eval(sprintf("format_%s(obj)", class_name));
                format_flag = true;
                break
            end
        end

        if ~format_flag
            val = general_obj_to_str(obj);
        end

    end

end


function val = isfunction_handle(obj)
    val = isa(obj, "function_handle");
end


function n = max_disp_obj_len()
    n = 10;
end


function val = format_numeric(obj)

    if isscalar(obj)
        val = disp_str(obj);
    else
        val = disp_str(obj);
    end

end

function val = format_logical(obj)
    if isscalar(obj)
        val = disp_str(obj);
    else
        val = disp_str(obj);
    end
end

function val = format_string(obj)
    if isscalar(obj)
        val = sprintf("""%s\""", obj);
    else
        if isvector(obj)
            val = "[""" + join(obj, """, """) + """]";
        else
            val = disp_str(obj);
        end
    end
end

function val = format_char(obj)
    val = "'" + sprintf("%c", obj) + "'";
end

function val = format_struct(obj)
    if isscalar(obj)
        val = disp_str(obj);
    else
        val = disp_str(obj);
    end
end

function val = format_cell(obj)
    if isscalar(obj)
        val = disp_str(obj);
    else
        val = disp_str(obj);
    end
end

function val = format_function_handle(obj)
    if isscalar(obj)
        val = sprintf("<function handle of %s>", general_obj_to_str(obj));
    else
        val = sprintf("[<function handle of %s>...]", general_obj_to_str(obj(1)));
    end
end
