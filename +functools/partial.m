function handler = partial(func, varargin)
    % handler = functools.partial(@func, arg1, ..., keywords=kw)
    % handler(new_args{:}) calls func(arg1, ..., new_args{:}, kw{:}). kw is a
    % struct or a cell of name-value pairs; a name passed again at call time
    % overrides the bound value, as in Python.

    arguments
        func (1, 1) function_handle
    end
    arguments (Repeating)
        varargin
    end

    % parse keywords by hand: an arguments-block option also matches a prefix,
    % so a bound pair such as "k", 1 would be taken as keywords
    args = varargin;
    keywords = {};
    if numel(args) >= 2 && is_text_scalar(args{end - 1}) && strcmpi(args{end - 1}, "keywords")
        keywords = normalize_keywords(args{end});
        args = args(1:end - 2);
    end

    if isempty(keywords)
        if isempty(args)
            handler = func;
        else
            handler = @(varargin) func(args{:}, varargin{:});
        end
        return
    end

    handler = @(varargin) call_with_keywords(func, args, keywords, varargin);
end

function varargout = call_with_keywords(func, args, keywords, call_args)
    % drop the bound keywords that the call's trailing name-value pairs name
    for j = numel(call_args) - 1:-2:1
        name = call_args{j};
        if ~is_text_scalar(name)
            break
        end

        is_named = strcmpi(keywords(1:2:end), name);
        if any(is_named)
            keywords(repelem(is_named, 2)) = [];
        end
    end

    [varargout{1:nargout}] = func(args{:}, call_args{:}, keywords{:});
end

function keywords = normalize_keywords(keywords)
    if isstruct(keywords) && isscalar(keywords)
        keywords = namedargs2cell(keywords);
    end

    is_valid = iscell(keywords) && (isempty(keywords) || isvector(keywords)) ...
        && mod(numel(keywords), 2) == 0;
    if is_valid
        is_valid = all(cellfun(@is_text_scalar, keywords(1:2:end)));
    end
    if ~is_valid
        error( ...
            "MMGA:partial:invalidKeywords", ...
            "keywords must be a scalar struct or a cell of name-value pairs with text names." ...
        );
    end

    % strcmpi matches a cell only where its elements are character vectors
    keywords = reshape(keywords, 1, []);
    keywords(1:2:end) = cellfun(@char, keywords(1:2:end), UniformOutput=false);
end

function tf = is_text_scalar(value)
    tf = isstring(value) && isscalar(value) || ischar(value) && isrow(value);
end
