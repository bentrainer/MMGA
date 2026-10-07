function pass = test_set_fig_resolution(verbose)

    arguments
        verbose logical = true
    end

    pass = false;
    cases = cell(0, 3);

    old_current = groot().CurrentFigure;
    restore_current = onCleanup(@() set(groot(), "CurrentFigure", old_current));
    close_figs = onCleanup(@() delete(findall(groot(), "Type", "figure", "Tag", "test_set_fig_resolution")));
    f = figure(Visible = "off", Units = "pixels", Tag = "test_set_fig_resolution");

    s = get(0, "ScreenSize");
    centered = @(w, h) string(mat2str([floor((s(3) - w) / 2), floor((s(4) - h) / 2), w, h]));

    set_fig_resolution(f, 400, 300);
    cases(end + 1, :) = {"given figure", string(mat2str(f.Position)), centered(400, 300)};

    set(groot(), "CurrentFigure", f);
    set_fig_resolution(500, 200);
    cases(end + 1, :) = {"current figure", string(mat2str(f.Position)), centered(500, 200)};

    set_fig_resolution(f);
    cases(end + 1, :) = {"default size", string(mat2str(f.Position)), centered(1280, 720)};

    % lastwarn records a warning's identifier even while it is turned off
    old_state = warning();
    restore_warnings = onCleanup(@() warning(old_state));
    warning("off", "MMGA:set_fig_resolution:positionNotImplemented");
    warning("off", "MMGA:set_fig_resolution:noFigure");

    lastwarn("", "");
    set_fig_resolution(f, 400, 300, position = "left");
    cases(end + 1, :) = {"other position warns", last_warning_id(), ...
        "MMGA:set_fig_resolution:positionNotImplemented"};
    cases(end + 1, :) = {"other position centers", string(mat2str(f.Position)), centered(400, 300)};

    lastwarn("", "");
    num_figs = numel(findall(groot(), "Type", "figure"));
    set(groot(), "CurrentFigure", []);
    set_fig_resolution(800, 600);
    cases(end + 1, :) = {"no current figure warns", last_warning_id(), "MMGA:set_fig_resolution:noFigure"};
    cases(end + 1, :) = {"no figure created", string(numel(findall(groot(), "Type", "figure")) - num_figs), "0"};
    cases(end + 1, :) = {"other figure unchanged", string(mat2str(f.Position)), centered(400, 300)};

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

function id = last_warning_id()
    [~, id] = lastwarn();
    id = string(id);
end
