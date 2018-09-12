function [gp,ap,sr] =  InitializeController(Wp)


%% global parameters

gp            = struct;

gp.Nsim       = Wp.N/(2*Wp.h);      % total simulation time
gp.Nh         = 20;                 % # samples in prediction horizon
gp.Na         = Wp.Nt;              % # wind turbines
gp.Nu         = gp.Na;              % #inputs
gp.Nx         = gp.Na*28;           % #states (28 is number of states one turbine model)
gp.Ny         = gp.Na*2;            % #states (2 is number of outputs one turbine model)

gp.MF         = logical(repmat(repmat([0 1]',gp.Na,1),gp.Nh,1));
gp.Mf         = logical(repmat([0 1]',gp.Na,1));
gp.MP         = logical(repmat(repmat([1 0]',gp.Na,1),gp.Nh,1));
gp.Mp         = logical(repmat([1 0]',gp.Na,1));

gp.Q          = 1e4*eye(gp.Nh);                 % weigth on tracking
gp.R          = 0*eye(gp.Nh*gp.Nu);           % weigth on control signal

gp.duc        = Inf;                            % limitation on du/dt
gp.dfc        = Inf;                            % limitation on dF/dt

% wind farm reference
gp.Pnref      = zeros(gp.Nsim+gp.Nh,1); 

load(strcat('MPC/libraries/Power_reference')); gp.AGCdata = AGCdata(:,2); 

gp.Pgreedy            = 7.490235760251439e+06; % Simulation horizon of 900s

gp.Pnref(1:Wp.N0)     = -1e6; 
gp.Pnref(Wp.N0+1:end) = -1e6 ;%+ .5*gp.Pgreedy*gp.AGCdata(1:gp.Nsim+gp.Nh-Wp.N0);

%% turbine parameters

ap              = struct;

ap.uM           = Inf;          % maximum power input
ap.um           = -Inf;            % minimum power input
ap.PM           = Inf;        % upperbounds and lower bounds output
ap.Pm           = -Inf;
ap.FM           = Inf;
ap.Fm           = -Inf;

for kk = 1:gp.Na
    WINDSPEED    = 8;
    ap.T{kk}     = FetchTurbineModel(WINDSPEED,Wp.h);
    ap.a{kk}     = ap.T{kk}.A; %load model turbine i from Pref to [Pi Fi]
    ap.b{kk}     = ap.T{kk}.B;
    ap.c{kk}     = ap.T{kk}.C;   
    ap.d{kk}     = ap.T{kk}.D;
end                                                                                                                              

%% simulation results

sr                = struct;

sr.x              = zeros(gp.Nx,gp.Nsim);       % state x
sr.U              = zeros(gp.Nh,gp.Nsim,gp.Na);
sr.u              = zeros(gp.Na,gp.Nsim);       % control signal Pr
sr.y              = zeros(gp.Ny,gp.Nsim);       % output 
sr.e              = zeros(1,gp.Nsim);           % wind farm error

% dummy variables
sr.xs             = zeros(gp.Nx,gp.Nsim);       % state x
sr.ys             = zeros(gp.Ny,gp.Nsim);       % output y

end
