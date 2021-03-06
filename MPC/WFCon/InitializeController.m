function [gp,ap,sr] =  InitializeController(Wp)


%% global parameters

gp            = struct;

gp.Nsim       = Wp.N/(2*Wp.h);      % total simulation time
gp.Nh         = 100;                 % # samples in prediction horizon
gp.Na         = Wp.Nt;              % # wind turbines
gp.Nu         = gp.Na;              % #inputs
%gp.Nx         = gp.Na*15;           % #states (15 is number of states one turbine model)
%gp.Ny         = gp.Na*2;            % #states (2 is number of outputs one turbine model)
gp.Nx         = gp.Na*14;           % #states (15 is number of states one turbine model)
gp.Ny         = gp.Na*1;            % #states (2 is number of outputs one turbine model)
gp.W          = 3e2;
gp.V          = gp.W;

% gp.MF         = logical(repmat(repmat([0 1]',gp.Na,1),gp.Nh,1));
% gp.Mf         = logical(repmat([0 1]',gp.Na,1));
% gp.MP         = logical(repmat(repmat([1 0]',gp.Na,1),gp.Nh,1));
% gp.Mp         = logical(repmat([1 0]',gp.Na,1));

gp.MF         = logical(repmat(repmat([1]',gp.Na,1),gp.Nh,1));
gp.Mf         = logical(repmat([1]',gp.Na,1));
gp.MP         = logical(repmat(repmat([1]',gp.Na,1),gp.Nh,1));
gp.Mp         = logical(repmat([1]',gp.Na,1));

gp.Q          = .1*eye(gp.Nh);                 % weigth on tracking
gp.R          = 1*eye(gp.Nh*gp.Nu);           % weigth on control signal

gp.duc        = 1e5;                          % limitation on du/dt
gp.dfc        = 1e3;                          % limitation on dF/dt

gp.sc         = 1e-6;                         % scaling in the MPC

% wind farm reference
gp.Pnref      = zeros(gp.Nsim+gp.Nh,1); 

load(strcat('MPC/libraries/Power_reference')); gp.AGCdata = AGCdata(:,2); 

gp.Pgreedy            = 7.490235760251439e+06; % Simulation horizon of 900s

gp.Pnref(1:Wp.N0)     = 5e6; 
gp.Pnref(Wp.N0+1:end) = 5e6;%+ .5*gp.Pgreedy*gp.AGCdata(1:gp.Nsim+gp.Nh-Wp.N0);

%% turbine parameters

ap              = struct;

ap.uM           = 1e6;              % maximum power input for one turbine
ap.um           = -ap.uM;           % minimum power input for one turbine
ap.PM           = ap.uM;            % upperbounds and lower bounds output
ap.Pm           = ap.um;
ap.FM           = Inf;
ap.Fm           = -Inf;

WINDSPEEDS      = [10 10 6 6 5 5];
for kk = 1:gp.Na
    ap.T{kk}     = FetchTurbineModel(WINDSPEEDS(kk),Wp.h);
    ap.a{kk}     = ap.T{kk}.A;  % load model turbine i from Prefi to [Pi Fi]
    ap.b{kk}     = ap.T{kk}.B;
    ap.bn{kk}    = ones(size(ap.a{kk},1),1);
    ap.c{kk}     = ap.T{kk}.C;   
    ap.d{kk}     = ap.T{kk}.D;
    ap.dn{kk}    = ones(size(ap.d{kk},1),1);
end                                                                                                                              

%% simulation results

sr                = struct;

sr.x              = zeros(gp.Nx,gp.Nsim);       % state x
sr.U              = zeros(gp.Nh,gp.Nsim,gp.Na);
sr.u              = zeros(gp.Na,gp.Nsim);       % control signal Pr
sr.y              = zeros(gp.Ny,gp.Nsim);       % output 
sr.Y              = zeros(gp.Nh,gp.Nsim,gp.Ny);
sr.e              = zeros(1,gp.Nsim);           % wind farm error
sr.Z              = zeros(gp.Nh,gp.Nsim,1);     % wind farm error
sr.n              = gp.W*randn(gp.Na,gp.Nsim);  % noise

% observer variables
sr.xe             = zeros(gp.Nx,gp.Nsim);       % state x
sr.ye             = zeros(gp.Ny,gp.Nsim);       % output y

% dummy variables
sr.xs             = zeros(gp.Nx,gp.Nsim);       % state x
sr.ys             = zeros(gp.Ny,gp.Nsim);       % output y
sr.es             = zeros(1,gp.Nsim);           % error

end
