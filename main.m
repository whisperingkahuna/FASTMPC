clear;clc;

addpath(genpath('MPC'));
addpath(genpath('C:/Program Files/IBM/ILOG/CPLEX_Studio128')); % add cplex

Wp.Nt    = 6;                        % #turbines
Wp.N     = 2*floor(100/2);           % simulation time ( real simulation time is N-h )
Wp.h     = .5;                       % SOWFA sample period 
Wp.k     = 0;                        % time index
Wp.N0    = round(.1*Wp.N/(2*Wp.h));  % First n% of the simulation constant reference
Wp.cl    = 1;

% initialize controller parameters/variables
[gp,ap,sr] =  InitializeController(Wp);


% start simulation SOWFA


% start loop
while Wp.k<Wp.N/(2*Wp.h)
    
    tic
    Wp.k = Wp.k + 1;
    
    
    % 1) run controller
    if Wp.cl
        [sr,ap]      = consys_cent(Wp.k,sr,ap,gp); 
    else
        sr.u(:,Wp.k) = 1e6;
    end
    
    % 2) write control signals to SOWFA and read measurements
    sr       = run_sowfa(Wp.k,sr,ap,gp);
    
    xmes     = sr.xs(:,Wp.k);
    ymes     = sr.ys(:,Wp.k);

    % 5) store measurements in controller variables  
    sr.e(Wp.k)         = gp.Pnref(Wp.k) - sum(ymes(gp.Mp));     % wind farm error      
    sr.x(:,Wp.k+1)     = xmes;                                  % wind farm state
    sr.y(:,Wp.k)       = ymes;                                  % wind farm output  
    
    
    disp(['Sample ' num2str(Wp.k) '       CPU: ' num2str(toc,3) ' s.' ...
        '          error: ' num2str( sr.e(Wp.k)/1e6,3 ) ' MW.']);    

end

%%
Power = sr.y(gp.Mp,:);
Force = sr.y(gp.Mf,:);
Pwf   = sum(Power);

% plot
figure(1);clf
seq   = [2 4 6 1 3 5];
figure(1);clf
ll = 0;
for kk=seq
    ll = ll + 1;
    subplot(2,3,ll)
    stairs(Power(kk,:)/1e6,'b','linewidth',1.2);hold on;
    str = strcat('$\delta P_',num2str(kk,'%.0f'),'$');
    ylabel([str,' [MW]'],'interpreter','latex');
    xlabel('$k$','interpreter','latex')
    grid;
    if ll==1;annotation(gcf,'arrow',[0.017 0.08],[0.51 0.51]);end;
end

figure(2);clf
seq   = [2 4 6 1 3 5];
ll = 0;
for kk=seq
    ll = ll + 1;
    subplot(2,3,ll)
    stairs(Force(kk,:)/1e6,'b','linewidth',1.2);hold on;
    str = strcat('$\delta M_',num2str(kk,'%.0f'),'$');
    ylabel([str,' [MNm]'],'interpreter','latex');
    xlabel('$k$','interpreter','latex')
    grid;
    if ll==1;annotation(gcf,'arrow',[0.017 0.08],[0.51 0.51]);end;
end

figure(3);clf
seq   = [2 4 6 1 3 5];
ll = 0;
for kk=seq
    ll = ll + 1;
    subplot(2,3,ll)
    stairs(sr.u(kk,:)/1e6,'b','linewidth',1.2);hold on;
    str = strcat('$\delta P_',num2str(kk,'%.0f'),'^{\rm{ref}}$');
    ylabel([str,' [MW]'],'interpreter','latex');
    xlabel('$k$','interpreter','latex')
    grid;
    if ll==1;annotation(gcf,'arrow',[0.017 0.08],[0.51 0.51]);end;
end

figure(4);clf
stairs(Pwf/1e6,'b','linewidth',1.2);hold on;
stairs(gp.Pnref/1e6,'r--','linewidth',1.2);grid;xlim([0 length(Pwf)]);
ylabel('$\delta P$ [MW]','interpreter','latex')
xlabel('$k$','interpreter','latex')
title('$P^{\rm{ref}}$ (red dashed), $\sum_i P_{i}$ (blue)','interpreter','latex');
