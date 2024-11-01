function val = ternary(cond, val_true, val_false)
    if logical(cond)
        val = val_true;
    else
        val = val_false;
    end
end