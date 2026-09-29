function [A, maxThickness] = airenaca(p)
    % Cross-sectional area and maximum thickness of a PARSEC airfoil
    % (201 cosine-spaced stations). Used as the GA fitness in GAairfoil.m.
    % Source: airenaca.m of the El Houd & Hallou (2019) reference
    % implementation, https://github.com/anasselhoud/Airfoil-Shape_optimization
    % Copyright (c) 2020 Anass El Houd, MIT licence; see THIRD_PARTY_NOTICES.md.
    % The code is unchanged; only comments were added.
    dbeta = pi / 200;
    Z_u0 = [];
    Z_d0 = [];
    x0 = [];
    bet = 0;
    k = 1;

    % Assuming parsec(p) returns the required coefficients
    a = parsec(p);  % PARSEC coefficients

    for i = 0 : dbeta : pi
        x0(k) = (1 - cos(bet)) / 2;
        [Z_u0(k), Z_d0(k)] = yCoord2(a, x0(k));   % coordinate array
        bet = bet + dbeta;
        k = k + 1;
    end

    maxThickness = max(abs(Z_u0 - Z_d0));  % Maximum thickness

    yu = Z_u0;
    yl = Z_d0;

    % Calculate the area using trapezoidal integration
    z1 = trapz(x0, yu);
    z2 = trapz(x0, yl);
    A = z1 - z2;  % Airfoil area
end





