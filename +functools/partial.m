function handler = partial(varargin)

    if nargin==0
        error("usage: new_func = functools.partial(@func, param1, param2, ...), where new_func(new_param1, new_param2, ...) <-> func(param1, param2, ..., new_param1, new_param2, ...)");
    end

    foo = varargin{1};
    if ~isa(foo, "function_handle")
        error("functools.partial expects ""function_handle"" but got ""%s""", class(foo));
    end

    if nargin==1
        warning("new_func = functools.partial(@func) is equal to new_func = @func");
        handler = foo;
        return
    end

    freeze_params = varargin(2:end);

    function varargout = wrapper_func(varargin)
        [varargout{1:nargout}] = foo(freeze_params{:}, varargin{:});
    end

    handler = @wrapper_func;
end