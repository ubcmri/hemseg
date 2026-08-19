function id_string = getCommitString(repo_path,varargin)

orig_path = pwd;
cd(repo_path);
if nargin == 1 || strcmp(varargin{1},'long')
    [status,id_string] = system('git rev-parse HEAD');
elseif strcmp(varargin{1},'short')
    [status,id_string] = system('git rev-parse --short HEAD');
end    

if status
   id_string = 'git commit hash could not be found';
else
   id_string = id_string(1:end-1);
end

cd(orig_path);