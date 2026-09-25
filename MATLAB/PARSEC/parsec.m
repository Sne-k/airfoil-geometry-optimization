function a=parsec(p)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function determines a=[a1, a2, ...an] to solve the airfoil polynomial.
% Zn=an(p)*X^(n-1/2), where n is the number of coordinates for the upper or
% lower surface.
%
% Input is a vector of PARSEC parameters p=[p1, p2, ...pn] where
% p1=rle          leading-edge radius
% p2=Xup          upper crest position
% p3=Yup          upper crest height
% p4=YXXup        upper crest curvature
% p5=Xlow         lower crest position
% p6=Ylow         lower crest height
% p7=YXXlow       lower crest curvature
% p8=yte          trailing-edge height
% p9=delta yte    trailing-edge thickness
% p10=alpha te    trailing-edge direction angle (deg)
% p11=beta te     trailing-edge wedge angle (deg)
%
% Source: reference implementation used in El Houd & Hallou (2022),
% "Optimization study of NACA airfoil using nonlinear programming & genetic
% algorithms" (ref. [5] of the project report).
% Corrections made for this repository:
%   - curvature row: the x^(9/2) term is (9/2)(7/2) = 63/4 (was 53/4)
%   - lower surface: the leading-edge condition acts on the x^(1/2)
%     coefficient with a negative sign, a1 = -sqrt(2*rle) (it previously
%     fixed the x^(11/2) coefficient to +sqrt(2*rle))
%   - lower surface: trailing-edge height yte - dyte/2 and slope
%     tan(alpha + beta/2) (the upper-surface values were used)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c1=[1,1,1,1,1,1];
c2=[p(2)^(1/2),p(2)^(3/2),p(2)^(5/2),p(2)^(7/2),p(2)^(9/2),p(2)^(11/2)];
c3=[1/2, 3/2, 5/2, 7/2, 9/2, 11/2];
c4=[(1/2)*p(2)^(-1/2), (3/2)*p(2)^(1/2),(5/2)*p(2)^(3/2),(7/2)...
    *p(2)^(5/2),(9/2)*p(2)^(7/2),(11/2)*p(2)^(9/2)];
c5=[(-1/4)*p(2)^(-3/2),(3/4)*p(2)^(-1/2),(15/4)*p(2)^(1/2),(35/4)...
    *p(2)^(3/2),(63/4)*p(2)^(5/2),(99/4)*p(2)^(7/2)];
c6=[1,0,0,0,0,0];
Cup=[c1; c2; c3; c4; c5; c6];
c7=[1,1,1,1,1,1];
c8=[p(5)^(1/2),p(5)^(3/2),p(5)^(5/2),p(5)^(7/2),p(5)^(9/2),p(5)^(11/2)];
c9=[1/2, 3/2, 5/2, 7/2, 9/2, 11/2];
c10=[(1/2)*p(5)^(-1/2), (3/2)*p(5)^(1/2),(5/2)*p(5)^(3/2),(7/2)...
    *p(5)^(5/2),(9/2)*p(5)^(7/2),(11/2)*p(5)^(9/2)];
c11=[(-1/4)*p(5)^(-3/2),(3/4)*p(5)^(-1/2),(15/4)*p(5)^(1/2),(35/4)...
    *p(5)^(3/2),(63/4)*p(5)^(5/2),(99/4)*p(5)^(7/2)];
c12=[1,0,0,0,0,0];
Clo=[c7; c8; c9; c10; c11; c12];
bup=[p(8)+p(9)/2;p(3);tand(p(10)-p(11)/2);0;p(4);sqrt(2*p(1))];
blo=[p(8)-p(9)/2;p(6);tand(p(10)+p(11)/2);0;p(7);-sqrt(2*p(1))];
aup=linsolve(Cup,bup);
alower=linsolve(Clo,blo);
a(:,1)=aup;
a(7:12,1)=alower;
end
