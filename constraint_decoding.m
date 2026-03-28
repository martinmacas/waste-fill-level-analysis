function wr = constraint_decoding(x,b,u)
    % Scale parameters
    b = b / 168;
    u = u / 168;

    eps_val = 1e-12;

    % Adjust boundaries but keep zeros untouched
    x_adj = x;
    mask_boundary = abs(x*7 - round(x*7)) < eps_val & x > 0;
    x_adj(mask_boundary) = x_adj(mask_boundary) - eps_val;

    % Segment index
    d = floor(7 * x_adj) / 7;

    % Inverse mapping
    wr = d + b + 7 * (u - b) .* (x - d);
end


% function wr = constraint_decoding(x,b,u)
% 
% b=b/168;
% u=u/168;
% eps_val = 0%1e-12;
% d=floor(7*(x-eps_val))/7;
% wr=d+7*(u-b)*(x-d)+b;
