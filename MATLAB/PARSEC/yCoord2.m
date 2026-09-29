function [yu,yl]=yCoord2(a,x)
%this function calculates the y-coordinates for a given PARSEC coeffecients
%and x-coordinate points
%Source: yCoord2.m of the El Houd & Hallou (2019) reference implementation,
%https://github.com/anasselhoud/Airfoil-Shape_optimization
%Copyright (c) 2020 Anass El Houd, MIT licence; see THIRD_PARTY_NOTICES.md.
%The code is unchanged; only comments were added.
yu=a(1)*x^.5+a(2)*x^(1.5)+a(3)*x^(2.5)+a(4)*x^(3.5)+a(5)*x^(4.5)+a(6)*x^(5.5);
yl=a(7)*x^.5+a(8)*x^(1.5)+a(9)*x^(2.5)+a(10)*x^(3.5)+a(11)*x^(4.5)+a(12)*x^(5.5);
end