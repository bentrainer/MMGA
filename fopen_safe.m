function fp = fopen_safe(varargin)
    fp = fopen(varargin{:});

    % a failed open returns -1 and leaves nothing to close
    if fp < 0
        return
    end

    % record what fp refers to: after an early fclose, a later fopen can reuse
    % the identifier for another file, which the cleanup must leave open
    file_info = cell(1, 4);
    [file_info{:}] = fopen(fp);

    % put a variable of random name in the caller for onCleanup()
    cleanup = onCleanup(@() close_if_same(fp, file_info));
    [~, tmp_fn] = fileparts(tempname());
    assignin("caller", "persist_fopen_safe_" + tmp_fn, cleanup);
end

function close_if_same(fp, file_info)
    current_info = cell(1, 4);
    [current_info{:}] = fopen(fp);
    if isequal(current_info, file_info)
        fclose(fp);
    end
end
