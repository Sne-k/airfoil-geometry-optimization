function s = cycleStatistics(iteration, cl, cd, varargin)
%CYCLESTATISTICS  Mean forces of an iterative solution that may not settle.
%   s = CYCLESTATISTICS(iteration, cl, cd) takes the force reports of the
%   second-order stage of a run (equally spaced in iterations) and returns
%   a structure with
%     steady     true if, over the last 'Window' iterations, CL varies by
%                less than 1e-4 and CD by less than 1e-5
%     period     period of the force cycle in iterations (NaN if the run
%                is steady or no period is found)
%     mismatch   how well the drag history repeats after one period: mean
%                square difference between the history and the history one
%                period earlier, divided by twice the variance (0 for an
%                exact repetition, about 1 for unrelated values)
%     cycles     number of whole periods in the averaging window (0 if no
%                period is found)
%     window     length of the averaging window in iterations (number of
%                reports times their spacing)
%     first      iteration of the first report in the averaging window
%     CL, CD     means over the averaging window
%     LD         ratio of the mean lift to the mean drag
%     CL_min, CL_max, CD_min, CD_max, LD_min, LD_max
%                lowest and highest value in the averaging window (LD: of
%                the ratio CL/CD of the single reports)
%     use        logical vector: the reports in the averaging window
%   The averaging window is the last 'Window' iterations for a steady run
%   and for a run without a period, and the last whole periods for a run
%   that cycles.
%
%   The period is the smallest lag at which the drag history repeats: the
%   first lag (of at least 'MinPeriod' iterations) where the mismatch has a
%   local minimum below 'Match'. The first 'Skip' iterations of the stage
%   are left out of this search and of the periods that are averaged, and a
%   lag is only tried if at least 16 reports remain to compare.
%
%   Options (name, value), defaults in brackets:
%     'Window'     iterations for the steadiness test and the fallback (1000)
%     'Skip'       iterations at the start of the stage to leave out   (600)
%     'MinPeriod'  shortest period that is looked for, in iterations   (400)
%     'Match'      largest mismatch accepted for a period              (0.1)
%     'Tol'        [CL CD] ranges below which a run is steady  ([1e-4 1e-5])

ip = inputParser;
ip.PartialMatching = false;
ip.addParameter('Window', 1000);
ip.addParameter('Skip', 600);
ip.addParameter('MinPeriod', 400);
ip.addParameter('Match', 0.1);
ip.addParameter('Tol', [1e-4 1e-5]);
ip.parse(varargin{:});
o = ip.Results;
iteration = iteration(:);  cl = cl(:);  cd = cd(:);
n = numel(cd);
step = median(diff(iteration));
if isnan(step) || step <= 0, step = 1; end

use = iteration > iteration(end) - o.Window;
s.steady = (max(cl(use)) - min(cl(use))) <= o.Tol(1) && (max(cd(use)) - min(cd(use))) <= o.Tol(2);
s.period = NaN;  s.mismatch = NaN;  s.cycles = 0;
if ~s.steady
    k0 = find(iteration >= iteration(1) + o.Skip, 1);
    x = cd(k0:end);
    m = numel(x);
    lagMin = max(2, ceil(o.MinPeriod / step));
    lagMax = m - 16;
    v = var(x, 1);
    if lagMax > lagMin && v > 0
        lags = lagMin-1:min(lagMax+1, m-1);
        d = arrayfun(@(L) mean((x(1+L:m) - x(1:m-L)).^2) / (2 * v), lags);
        for j = 2:numel(d)-1
            if d(j) < o.Match && d(j) <= d(j-1) && d(j) <= d(j+1)
                s.period = lags(j) * step;
                s.mismatch = d(j);
                s.cycles = floor(m / lags(j));
                use = false(n, 1);
                use(n - s.cycles * lags(j) + 1:n) = true;
                break;
            end
        end
    end
end
ld = cl(use) ./ cd(use);
s.window = sum(use) * step;
s.first = min(iteration(use));
s.CL = mean(cl(use));
s.CD = mean(cd(use));
s.LD = s.CL / s.CD;
s.CL_min = min(cl(use));  s.CL_max = max(cl(use));
s.CD_min = min(cd(use));  s.CD_max = max(cd(use));
s.LD_min = min(ld);  s.LD_max = max(ld);
s.use = use;
end
