function set_fig_resolution(fig_optional, width, height, opts)

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

    if isnumeric(fig_optional)
        if isempty(groot().CurrentFigure)
            warning("no matlab.ui.Figure found, do nothing");
            return
        end

        height = width;
        width = fig_optional;
        fig = gcf();
    else
        fig = fig_optional;
    end

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