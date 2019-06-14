% David Eriksson, 2019
% ZC Danziger, 2015 (SimLIFNet)

function [spk, NetParams, V, SynInputs, SynCurrents] = SimLIFFeedforwardNet(commonInput,varargin)
   
%
% % The core of this function is based on the code from SimLIFNet, ZC Danziger March 2015 %%%
%

%% Initialize
e1 = clock;
N = size(commonInput,1);


%% Parse inputs
P = inputParser;
P.addParamValue('simTime', 100, @(u)isnumeric(u) && numel(u)==1);
P.addParamValue('tstep', 1e-2, @(u)isnumeric(u) && numel(u)==1);
P.addParamValue('initialConditions', zeros(N,1), @(u)isnumeric(u) && size(u,1)==N);
P.addParamValue('refractoryTime', zeros(N,1), @(u)isnumeric(u) && size(u,1)==N);
P.addParamValue('offsetCurrents', zeros(N,1), @(u)isnumeric(u) && size(u,1)==N);
P.addParamValue('displayProgress', true, @(u)u==1 || u==0);
P.addParamValue('plotResults', true, @(u)u==1 || u==0);
P.addParamValue('forcingFunctions', {@(u) 0, 1}, ...
    @(u)iscell(u) && size(u,2)==2 && ...
    all(cellfun(@(v) strcmp(class(v),'function_handle'),u(:,1))) && ...
    max([u{:,2}])<=N && ~(length(unique([u{:,2}]))<length([u{:,2}])) );
P.addParamValue('synapticDensity', ones(N,1)*4, @(u) isnumeric(u) && ( all(size(u)==[N 1]) || all(size(u)==[N N]) ));
P.addParamValue('noiseAmplitude', zeros(N,1), @(u) isnumeric(u) && all(size(u)==[N 1]));
P.addParamValue('fixedNoise', [], @(u) isnumeric(u) && all(size(u,1)==[N]));

% do not allow changes to these parameters to avoid violation of the
% nondimensionalization constructions
% P.addParamValue('thresholds', ones(N,1), @(u)isnumeric(u) && size(u,1)==N);   
% P.addParamValue('restVoltage', zeros(N,1), @(u)isnumeric(u) && size(u,1)==N);

P.parse(varargin{:});
NetParams = P.Results;



%% Set up simulation
% initialize state variables
ix = repmat(1:N,[N 1]);             % network index (row:from col:to)
spk = num2cell(-1e10*ones(1,N));    % cell array of spikes

% network parameters
vt = 1;
vr = 0;
tr = max([NetParams.refractoryTime repmat(NetParams.tstep,[N 1])],[],2);
Ia = NetParams.offsetCurrents;
V0 = vr;
nAmp = NetParams.noiseAmplitude;

% build up forcing functions
forceFcns = cell(N,1);
forceFcns([NetParams.forcingFunctions{:,2}]) = NetParams.forcingFunctions(:,1);
forceFcns(setxor([NetParams.forcingFunctions{:,2}],1:N)) = {@(u) 0};


% build up synaptic density array
if size(NetParams.synapticDensity,2)==1
    % each cell has constant 'a' when delivering pulses to other neurons
    a  = NetParams.synapticDensity;
    a = a(ix);
else
    % all 'a' between each cell are specified and possibly different
    a  = NetParams.synapticDensity;
end


    
% simulation parameters
t0 = 0;                     % start time
tf = NetParams.simTime;     % stop time
dt = NetParams.tstep;       % time incrememnt
if nargout==5
    % case where user requests all membrane data
    try
        t = t0:dt:tf;           % vector of simulation times
        K = length(t);          % number of total iterations in simulation
        V = nan(N,K);           % membrane voltages
        V(:,1) = V0;            % apply initial conditions
        SynInputs = V;
        SynCurrents = V;
        spikesReg = zeros(size(V)); 
    catch err
        disp(err.message)
        error('Unable to Store Full State Variables: please re-try without 3rd output argument')
    end
else
    t = [nan t0];           % t(1) is a placeholder only, to make indexing convenient
    K = tf/dt+1;
    V = [nan(N,1) V0];
end


spikesAccum = zeros(size(V,1),1);
adapt_time = 0.1;
adapt_strength = 100;

tau = 0.020;
tic;
%% Run simulation
vis = 0; %NetParams.displayProgress;
if vis, hw = waitbar(0,'Integrating Network...'); e2=clock; end
for k=2:K
    startT = toc;
    % index to data
    if nargout==5
        id=k;                       % case where membrane voltage stored
    else
        id=2;                       % case where only spikes are stored
        t(id) = (k-1)*dt;           % increment time
        V(:,1) = V(:,2);            % overwrite old state with new state
    end
    
    
    % exclude driving force because of reseting of membrane potential is not necessarily evident close to synapses
    synapses = commonInput(:,id);
    SynInputs(:,id) = commonInput(:,id);
    
    SynCurrents(:,id) = commonInput(:,id);
    
    % Euler integration
    %V(:,id) = V(:,id-1) + dt*( -V(:,id-1) + ...                     % difference of prior membrane voltage from rest
    %                            Ia + ...                            % bias current
    %                            dt^(-0.5)*nAmp.*randn(N,1) + ...    % addition of simple white noise (noise scaling b/c we are inside dt)
    %                            (-synapses) + ...                      % synaptic contribution
    %                            (-spikesAccum*adapt_strength.*(V(:,id-1)-(-0.1))) + ...                   % adaptation
    %                            cellfun(@(u) u(t(id)),forceFcns) ); % forcing functions
                                
    randVar = nAmp.*NetParams.fixedNoise(:,id);
                                
    V(:,id) = V(:,id-1) + dt/tau*( -V(:,id-1) + dt^(-0.5)*randVar + synapses + (-spikesAccum*adapt_strength.*(V(:,id-1)-(-1)))); % forcing functions
    
    prevSpikes = find(sum(spikesReg(:,(id-1):id),2));
    V(prevSpikes,id) = vr;
    
    % spiking
    isSpk = V(:,id)>=vt;
    spikes = isSpk;
    spikesReg(:,id) = spikes;
    V(isSpk,id) = vr;
    
    spikesAccum = spikesAccum*(1-dt/adapt_time)+spikes*(dt/adapt_time);

    
end

spk = cell(size(V,1),1);
for ui=1:size(V,1)
    spk{ui} = find(spikesReg(ui,:)==1)*dt;
end
  
if vis, close(hw); end

