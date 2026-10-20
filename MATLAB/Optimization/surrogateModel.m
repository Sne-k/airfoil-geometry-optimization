function model = surrogateModel(file)
%SURROGATEMODEL  Loads a neural-network surrogate of XFOIL for the surrogate-assisted optimiser.
%   model = SURROGATEMODEL(file) reads a model written by train_export.py:
%   an ensemble of fully connected networks (ReLU hidden layers, linear
%   output) that predicts an objective (for example the mean of the peak
%   CL/CD with free and tripped transition) from the 14 absolute CST
%   coefficients of a shape [Au(1:7) Al(1:7)]. The inputs are standardised
%   with the stored mean and scale.
%
%   [m, s] = model.predict(X) returns the ensemble mean m and standard
%   deviation s for every row of X (n x 14).
%
%   The surrogate only ranks candidates; every design the optimiser keeps is
%   evaluated with XFOIL (see optimize_airfoil, 'Algorithm', 'surrogate').

raw = jsondecode(fileread(file));
model.target = raw.target;
model.mu = raw.mean(:).';
model.sd = raw.scale(:).';
model.heldOut = raw.held_out;
model.nets = cell(numel(raw.networks), 1);
for k = 1:numel(raw.networks)
    n = raw.networks(k);
    W = n.weights;  b = n.biases;
    if ~iscell(W), W = num2cell(W, [2 3]); end      % jsondecode returns arrays when the layers have equal size
    model.nets{k} = struct('W', {cellfun(@double, W, 'UniformOutput', false)}, 'b', {cellfun(@(v) double(v(:).'), b, 'UniformOutput', false)});
end
model.predict = @(X) predictEnsemble(model, X);
end

function [m, s] = predictEnsemble(model, X)
Z = (X - model.mu) ./ model.sd;
P = zeros(size(X, 1), numel(model.nets));
for k = 1:numel(model.nets)
    h = Z;
    net = model.nets{k};
    for l = 1:numel(net.W)
        h = h * net.W{l} + net.b{l};
        if l < numel(net.W), h = max(h, 0); end
    end
    P(:, k) = h;
end
m = mean(P, 2);
s = std(P, 0, 2);
end
