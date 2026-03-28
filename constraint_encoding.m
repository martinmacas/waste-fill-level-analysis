function x = constraint_encoding(wr,b,u)
    % Scale parameters
    b = b / 168;
    u = u / 168;

    eps_val = 1e-12;

    % Adjust boundaries but keep zeros untouched
    wr_adj = wr;
    mask_boundary = abs(wr*7 - round(wr*7)) < eps_val & wr > 0;
    wr_adj(mask_boundary) = wr_adj(mask_boundary) - eps_val;

    % Segment index
    d = floor(7 * wr_adj) / 7;

    % Forward mapping
    x = (wr - d - b) ./ (7 * (u - b)) + d;
end

% function x = constraint_encoding(wr,b,u)
% 
% b=b/168;
% u=u/168;
% d=floor(7*wr)/7;
% 
% x=(wr-d-b)/(7*(u-b))+d;
