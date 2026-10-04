function g = gridConvergence(phi, cells)
%GRIDCONVERGENCE  Discretisation error estimate from three meshes.
%   g = GRIDCONVERGENCE(phi, cells) follows the procedure of Celik et al.
%   (2008, J. Fluids Eng. 130, 078001). phi = [fine medium coarse] are the
%   values of a quantity on three 2-D meshes of the same domain and cells
%   their numbers of cells. Fields of g:
%     r21, r32      refinement ratios (medium/fine and coarse/medium cell size)
%     kind          'monotonic' or 'oscillatory' (sign of the ratio of the
%                   two differences), 'none' if a difference is zero
%     order         apparent order p
%     extrapolated  Richardson extrapolation from the fine and medium mesh
%     errFine, errMedium, errCoarse   relative difference from the
%                   extrapolated value
%     gciFine       grid convergence index of the fine mesh (safety factor
%                   1.25)
%     gciMedium     the same for the medium mesh, with the apparent order
%                   and the difference between the medium and coarse mesh
%     asymptotic    gciMedium / (r21^p * gciFine); near 1 if the three
%                   meshes are in the asymptotic range
%   The estimate is not meaningful for oscillatory convergence or when the
%   differences are of the size of the iterative error.

phi = phi(:).';
h = 1 ./ sqrt(cells(:).');                 % representative cell size (2-D, same domain)
r21 = h(2) / h(1);
r32 = h(3) / h(2);
e21 = phi(2) - phi(1);
e32 = phi(3) - phi(2);
g = struct('r21', r21, 'r32', r32, 'kind', 'none', 'order', NaN, 'extrapolated', NaN, 'errFine', NaN, ...
    'errMedium', NaN, 'errCoarse', NaN, 'gciFine', NaN, 'gciMedium', NaN, 'asymptotic', NaN);
if e21 == 0 || e32 == 0, return; end
s = sign(e32 / e21);
if s > 0, g.kind = 'monotonic'; else, g.kind = 'oscillatory'; end
p = abs(log(abs(e32 / e21))) / log(r21);   % start: q = 0
for it = 1:200
    q = log((r21^p - s) / (r32^p - s));
    pNew = abs(log(abs(e32 / e21)) + q) / log(r21);
    if abs(pNew - p) < 1e-12, p = pNew; break; end
    p = pNew;
end
g.order = p;
g.extrapolated = (r21^p * phi(1) - phi(2)) / (r21^p - 1);
g.errFine = abs((g.extrapolated - phi(1)) / g.extrapolated);
g.errMedium = abs((g.extrapolated - phi(2)) / g.extrapolated);
g.errCoarse = abs((g.extrapolated - phi(3)) / g.extrapolated);
g.gciFine = 1.25 * abs(e21 / phi(1)) / (r21^p - 1);
g.gciMedium = 1.25 * abs(e32 / phi(2)) / (r32^p - 1);
g.asymptotic = g.gciMedium / (r21^p * g.gciFine);
end
