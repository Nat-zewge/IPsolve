% -----------------------------------------------------------------------------
% ipSolve: General Interior Point Solver for PLQ functions Copyright (C) 2013
% Authors: Aleksandr Y. Aravkin: sasha.aravkin at gmail dot com
% License: Eclipse Public License version 1.0
% -----------------------------------------------------------------------------


function [ yOut ] = run_example( H, z, measurePLQ, processPLQ, params )
%RUN_EXAMPLE Runs simple examples for ADMM comparison
%   Input:
%       H: linear model
%       z: observed data
%    meas: measurement model
%    proc: process model, can be 'none'
%  lambda: tradeoff parameter between process and measurement

t_start = tic;

if(~isfield(params, 'silent'))
   params.silent = 0; 
end

if(isfield(params, 'lambda'))
    par.lambda = params.lambda;
else
    par.lambda = 1;
end

if(isfield(params,'kappa'))
    par.kappa = params.kappa;
else
    par.kappa = 1;
end



if(isfield(params, 'tau'))
    par.tau = params.tau;
end

if(~isfield(params, 'constraints'))
   params.constraints = 0; 
end

if(~isfield(params, 'procLinear'))
    params.procLinear = 0;
end

params.AA = H;
params.b = z;

m = size(params.AA, 1);
par.m = m;

n = size(params.AA, 2);

if(params.procLinear)
    params.pSparse = 0;
    pLin = params.K;
    k = params.k;
    par.size = length(k);
    par.n = par.size;
else
    params.pSparse = 1;
    pLin = speye(n);
    k = zeros(n,1);
    par.size = n;
    par.n = n;
end



% Define process PLQ
pFlag = 1;
if(isempty(processPLQ))
    pFlag = 0;
end




if(pFlag)
    [Mw Cw cw bw Bw] = loadPenalty(pLin, k, processPLQ, par);
end

% Define measurement PLQ

par.size = m;
par.lambda = 1; 
[Mv Cv cv bv Bv] = loadPenalty(H, z, measurePLQ, par);


%%%%%%

K = size(Bv, 1);
params.pFlag = pFlag;
params.m = m;
params.n = n;
if(pFlag)
    [b, c, C, M] = addPLQ(bv, cv, Cv, Mv, bw, cw, Cw, Mw);
    Bm = Bv;
    params.B2 = Bw;
    K = K + size(Bw,1);
else
    b = bv; Bm = Bv; c = cv; C = Cv; M = Mv;
end
C = C';


L = size(C, 2);

sIn = 100*ones(L, 1);
qIn = 100*ones(L, 1);
uIn = zeros(K, 1);
yIn   = zeros(n, 1);

if(params.constraints)
    P = size(params.A, 2);
    rIn = 100*ones(P, 1);
    wIn = 100*ones(P, 1);
else
   rIn = [];
   wIn = [];
end


params.mu = 0;

Fin = kktSystem(b, Bm, c, C, M, sIn, qIn, uIn,  rIn, wIn, yIn,params);

[yOut, uOut, qOut, sOut, rOut, wOut, info] = ipSolver(b, Bm, c, C, M, sIn, qIn, uIn, rIn, wIn, yIn, params);

Fout = kktSystem(b, Bm, c, C, M, sOut, qOut, uOut, rOut, wOut, yOut, params);

ok = norm(Fout) < 1e-6;

fprintf('In, %f, Final, %f, mu, %f, itr %d\n', norm(Fin), norm(Fout), info.muOut, info.itr);

toc(t_start);


end
