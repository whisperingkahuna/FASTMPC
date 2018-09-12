
function [sr,ap] = consys_cent(k,sr,ap,gp)

yalmip('clear');

cons  = [];

xinit = sr.x(:,k);

    % define decision variables for the windfarm
    U  = sdpvar(gp.Nu*gp.Nh,1);
    
    % build wind farm model
    gp = wfmodel(ap,gp);    
    
    % build contraints set
    gp = constset(ap,gp);  
    
    % build matrices horizon
    gp = matsys(gp);         

    
    Yobs = gp.C*xinit  + gp.D*U;                            % power and force
    Z    = gp.Ce*xinit + gp.De*U + gp.Pnref(k:k+gp.Nh-1);   % wind farm error    

    Fobs = Yobs(gp.MF);
    Pobs = Yobs(gp.MP);    

    cons = [cons, gp.ulb <= U <= gp.uub];
     
    if k == 1
        dUt = [ U(1:gp.Na)-sr.u(:,k) ; U(gp.Na+1:end)-U(1:end-gp.Na)];
        cons = [cons, -gp.duc <= dUt <= gp.duc];
    else
        dUt = [ U(1:gp.Na)-sr.u(:,k-1) ; U(gp.Na+1:end)-U(1:end-gp.Na)];
        cons = [cons, -gp.duc <= dUt <= gp.duc];
    end
           
    cons = [cons, gp.ylb(gp.MP) <= Pobs <= gp.yub(gp.MP)];
    cons = [cons, gp.ylb(gp.MF) <= Fobs <= gp.yub(gp.MF)];
    
    if k == 1
        dFt  = [ Fobs(1:gp.Na)-sr.y(gp.Mf,k) ; Fobs(gp.Na+1:end)-Fobs(1:end-gp.Na)];
    else
        dFt = [ Fobs(1:gp.Na)-sr.y(gp.Mf,k-1) ; Fobs(gp.Na+1:end)-Fobs(1:end-gp.Na)];
    end

    cost = Z'*gp.Q*Z + U'*gp.R*U ;

    
%% finite horizon optimization problem

ops = sdpsettings('solver','cplex','verbose',0,'cachesolvers',1);

optimize([],cost,ops)


%% assign the decision variables
Uopt        = value(U);
temp        = reshape(Uopt,[gp.Na,gp.Nh]);
for i=1:gp.Nh
    sr.U(i,k,:)   = temp(:,i); % full horizon optimal action
end

sr.u(:,k)   = sr.U(1,k,:); % 1st step optimal action


end




