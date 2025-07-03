function [w, h] = get_screen_size()
    s = get(0, "ScreenSize");
    w = s(3);
    h = s(4);
end