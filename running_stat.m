function self = running_stat(self,value)
% pseudo object hacking by berend to have yauhen's implementation of the
% running variance mean and std statistics parfor compatible. Call: 
%
% self = running_stat()
%
% to initialize a new running_stat structure, and then call:
%
% self = running_stat(self, matImage) to add the image to the calculation

if nargin==0
    self = struct();

    % *(running) mean
    self.mean = 0;
    % * counter of updates
    self.count = 0;
    % (running) sum of the recurrence form: 
    % M(2,n) = M(2,n-1) + (x - mean(x_n))*(x - mean(x_{n-1}))
    self.runningsum = 0;
    % * (running) variance
    self.var = 0;
    % * (running) standard deviation
    self.std = 0;    
end

if nargin==1
    warning('BS:Bla','this amount of inputs does not make sense... either give a runnin_stat struct and image, or nothing at all to initialize a new instance')
end

if nargin==2
    
    if ~isfield(self,'runningsum')
        warning('BS:Bla','The passes running_stat struct is not valid. Reinitializing from scratch!')
        self = running_stat();
    end
    
    % Update running stats
    self.count = self.count + 1;
    if (self.count <= 1)
        self.mean = double(value);
        self.runningsum = zeros(size(value));
        self.count = 1;
        return
    end

    % update running moments
    delta = value - self.mean;
    if delta == 0
        return
    end
    self.mean = self.mean + delta ./ self.count;
    if self.count > 1
        self.runningsum = self.runningsum + delta .* (value - self.mean);
    end       

    % running variance
    if self.count > 2
        self.var = self.runningsum ./ (self.count - 1);
    else
        self.var = self.runningsum ./ self.count;
    end

    % running std
    self.std = sqrt(self.var);
end