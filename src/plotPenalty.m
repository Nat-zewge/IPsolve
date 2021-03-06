function [ ok ] = plotPenalty( plq, params )
%PLOTPENALTY plots a given PLQ penalty
%   plq:    name of penalty. If it's in the library, the system will generate
%           a 2D plot.
%   params: structure containing parameters,
%           e.g. tau (quantile)
%                lambda(quantile, l1)
%                kappa (huber, quantile huber).


% these should later be added to the automated parameter
% checking code. 
params.relOpt = 1e-5;
params.optTol = 1e-5;
params.inexact = 0; 
params.mehrotra = 0; 


H = -1;
z = 0;
switch(plq)
    case{'vapnik'}
        K = 2;
    case{'hybrid', 'student', 'studentPL'}
        K = 1;
        params.uConstraints = 1;
        params.uMax = params.scale;
        params.uMin = -params.scale;
    otherwise
        K = 1;
end
params.size = 1;
params.m = 1;
n = 1;
params.n = 1;
P = 2; % constraints

params.pFlag = 0;

if(~isfield(params, 'uConstraints'))
    params.uConstraints = 0;
end
if(~isfield(params, 'pSparse'))
    params.pSparse = 1;
end
if(~isfield(params, 'pFlag'))
    params.pFlag = 0;
end
if(~isfield(params, 'silent'))
    params.silent = 1;
end
if(~isfield(params, 'procLinear'))
    params.procLinear = 0;
end
if(~isfield(params, 'mMult'))
    params.mMult = 1;
end
if(~isfield(params, 'lambda'))
    params.lambda = 1;
end
if(~isfield(params,'kappa'))
    params.kappa = 1;
end
if(~isfield(params, 'tau'))
    params.tau = 1;
end

[ M C c b B ] = loadPenalty( H, z, plq, params );
C = C'; % this is funny.
L = size(C, 2);
sIn = 100*ones(L, 1);
qIn = 100*ones(L, 1);
uIn = zeros(K,1);
rIn = 100*ones(P, 1);
wIn = 100*ones(P, 1);

params.constraints = 1;
params.A = [1, -1];

mus = -3:.05:3;
len = length(mus);
vals = zeros(len,1);

for i = 1:len
    params.a = [mus(i);-mus(i)]; % constrains x = \mu.
    yIn = mus(i);
    [yOut, uOut, ~, ~, ~, ~, ~] = ipSolver(b, B, c, C, M, sIn, qIn, uIn, rIn, wIn, yIn, params);
    %    fprintf('yOut value us: %5.3f\n', yOut);
    if(isa(M, 'function_handle'))
        Mfun = M;
        [~,~,f] = Mfun(uOut); 
    else
        f = 0.5*uOut'*M*uOut;
    end
    vals(i) = uOut'*(B*yOut - b) - f;
end


plot(mus, vals);
hold on;
switch(plq)
    case{'hybrid'}
        plot(mus, sqrt(1 + (mus*params.scale).^2) - 1);
    case{'student', 'studentPL'}
        plot(mus, log(1 + (mus*params.scale).^2));
    otherwise
        % do nothing
end
hold off;
%end
ok = 1;

end