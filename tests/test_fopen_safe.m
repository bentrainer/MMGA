function pass = test_fopen_safe(verbose)

    arguments
        verbose logical = true
    end

    pass = false;
    cases = cell(0, 3);

    folder = tempname();
    mkdir(folder);
    remove_folder = onCleanup(@() rmdir(folder, "s"));
    file_a = fullfile(folder, "a.txt");
    file_b = fullfile(folder, "b.txt");

    % an onCleanup that throws warns with MATLAB:class:DestructorError;
    % lastwarn records it even while it is turned off
    old_state = warning("off", "MATLAB:class:DestructorError");
    restore = onCleanup(@() warning(old_state));

    lastwarn("", "");
    [fp, open_inside, num_vars] = write_text(file_a, "hello");
    cases(end + 1, :) = {"open until the caller returns", string(open_inside), "true"};
    cases(end + 1, :) = {"one cleanup variable in the caller", string(num_vars), "1"};
    cases(end + 1, :) = {"closed after the caller returns", string(is_open(fp)), "false"};
    cases(end + 1, :) = {"text written", string(fileread(file_a)), "hello"};
    cases(end + 1, :) = {"no warning after return", last_warning_id(), ""};

    % open_then_throw puts its file identifier in the error message
    lastwarn("", "");
    try
        open_then_throw(file_a);
        fp = -1;
    catch err
        fp = str2double(err.message);
    end
    cases(end + 1, :) = {"open before the error", string(fp >= 3), "true"};
    cases(end + 1, :) = {"closed after an error", string(is_open(fp)), "false"};
    cases(end + 1, :) = {"no warning after an error", last_warning_id(), ""};

    lastwarn("", "");
    [fp, num_vars] = open_missing(fullfile(folder, "missing", "c.txt"));
    cases(end + 1, :) = {"failed open returns -1", string(fp), "-1"};
    cases(end + 1, :) = {"failed open stores no cleanup", string(num_vars), "0"};
    cases(end + 1, :) = {"no warning after a failed open", last_warning_id(), ""};

    lastwarn("", "");
    close_early(file_a);
    cases(end + 1, :) = {"no warning after an early fclose", last_warning_id(), ""};

    % fopen reuses the lowest free identifier, so b gets the one a released
    lastwarn("", "");
    [a, b] = close_and_reopen(file_a, file_b, "w");
    cases(end + 1, :) = {"other file reuses the identifier", string(a == b), "true"};
    cases(end + 1, :) = {"other file stays open", string(fopen(b)), string(file_b)};
    cases(end + 1, :) = {"no warning after another file reuses the identifier", last_warning_id(), ""};
    close_if_open(b);

    lastwarn("", "");
    [a, b] = close_and_reopen(file_a, file_a, "r");
    cases(end + 1, :) = {"same file reopened reuses the identifier", string(a == b), "true"};
    [~, permission] = fopen(b);
    cases(end + 1, :) = {"same file with another permission stays open", string(permission), "rb"};
    cases(end + 1, :) = {"no warning after the same file reuses the identifier", last_warning_id(), ""};
    close_if_open(b);

    [a, b, num_vars] = open_two(file_a, file_b);
    cases(end + 1, :) = {"two cleanup variables", string(num_vars), "2"};
    cases(end + 1, :) = {"both files closed", string(is_open(a) || is_open(b)), "false"};

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

% Each function below calls fopen_safe directly, because its cleanup lives in
% the workspace of the function that calls it.

function [fp, open_inside, num_vars] = write_text(filename, text)
    fp = fopen_safe(filename, "w");
    fprintf(fp, "%s", text);
    open_inside = is_open(fp);
    num_vars = numel(who("persist_fopen_safe_*"));
end

function open_then_throw(filename)
    fp = fopen_safe(filename, "r");
    error("MMGA:test:boom", "%d", fp);
end

function [fp, num_vars] = open_missing(filename)
    fp = fopen_safe(filename, "r");
    num_vars = numel(who("persist_fopen_safe_*"));
end

function close_early(filename)
    fp = fopen_safe(filename, "w");
    fclose(fp);
end

function [a, b] = close_and_reopen(filename_a, filename_b, permission_b)
    a = fopen_safe(filename_a, "w");
    fclose(a);
    b = fopen(filename_b, permission_b);
end

function [a, b, num_vars] = open_two(filename_a, filename_b)
    a = fopen_safe(filename_a, "w");
    b = fopen_safe(filename_b, "w");
    num_vars = numel(who("persist_fopen_safe_*"));
end

function result = is_open(fp)
    result = fp >= 3 && ~isempty(fopen(fp));
end

function close_if_open(fp)
    if is_open(fp)
        fclose(fp);
    end
end

function id = last_warning_id()
    [~, id] = lastwarn();
    id = string(id);
end
