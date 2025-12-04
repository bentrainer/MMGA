function set_fig_resolution(fig_optional, width, height, opts)
%set_fig_resolution.m sets a figure with given resolution
% Usages:
%     set_fig_resolution() -> set gcf() to default 1280x800
%     set_fig_resolution(width, height) -> set gcf() to width x height
%     set_fig_resolution(some_fig, width, height) -> set "some_fig" to width x height

    arguments
        fig_optional = []
        width = 1280
        height = 720
        opts.position = "center"
    end

    if opts.position ~= "center"
        warning("position=""%s"" not implemented yet", opts.position);
        opts.position = "center";
    end

    if ~isempty(fig_optional) && isnumeric(fig_optional)
        height = width;
        width = fig_optional;
    end

    if isnumeric(fig_optional)
        if ~isempty(groot().CurrentFigure)
            fig_optional = gcf();
        else
            warning("no matlab.ui.Figure found, do nothing");
            return
        end
    end


    fig = fig_optional;


    s  = get(0, "ScreenSize");
    sw = s(3);
    sh = s(4);

    switch opts.position
        case "center"
            x = floor((sw - width) / 2);
            y = floor((sh - height) / 2);
    end

    fig.Position = [x, y, width, height];

end
