
function output = tif2nrrd(tif_path,varargin)
% tif2nrrd - converts tif or tiff image(s) into nrrd format. A single tif
%            image can be converted into a single-slice 2D nrrd, or a stack
%            of tif images can be converted into a multi-slice 3D nrrd.
%
% Usage:
%     output = tif2nrrd(tif_path);
%     output = tif2nrrd(tif_path,...,PARAM,VALUE);
%
% Required Arguments:
%     tif_path:  A path leading to a single tif file or a directory
%                containing a stack of tif files. Assumes tif files are
%                named in an alphanumeric order easily understood by the
%                sort function. 
%
% Parameter-Value Arguments:
%     path_type:    String: 'directory' or 'file'. Indicates whether the input
%                   is a single tif (for conversion to 2D nrrd) or stack of
%                   tifs (for conversion to 3D nrrd).
%     vox_size:     An array indicating the size of the image voxel. Default
%                   is [1 1 1].
%     nrrd_prefix:  String. Desired prefix of output nrrd.
%
% Returns:
%     output: A path leading to a nrrd file
%
% Example Usage:
% nrrd_file = tif2nrrd('');
%

% parse variables
ip = inputParser;
ip.addRequired('tif_path');
ip.addParameter('path_type', []);
ip.addParameter('vox_size', []);
ip.addParameter('nrrd_prefix',[])

ip.parse(tif_path,varargin{:});
tif_path = ip.Results.tif_path;
path_type = ip.Results.path_type;
vox_size = ip.Results.vox_size;
nrrd_prefix = ip.Results.nrrd_prefix;

% fill empty parameter variables
if isempty(path_type)
    if exist(tif_path,'dir')
        path_type = 'directory';
    elseif exist(tif_path,'file')
        path_type = 'file';
    else
        error('tif_path must be an existing file or directory');
    end
end

if isempty(nrrd_prefix)
    path_elems = split(tif_path,'/');
    path_elems = path_elems(~cellfun(@isempty,path_elems)); % remove empty cells
    tif_name = path_elems{end};
    if strcmp(path_type,'directory')
        nrrd_prefix = replace(tif_name,' ','-');
    else
        file_elems = split(tif_name,'.');
        nrrd_prefix = strjoin(file_elems(1:end-1),'.');
        nrrd_prefix = replace(nrrd_prefix,' ','-');
    end
end

% create array to be saved as nrrd
if strcmp(path_type,'directory')
    tif_dir = dir(tif_path);
    tif_dir = tif_dir(3:end); % remove . and .. dirs from list
    num_slices = length(tif_dir);
    nrrd_img = [];
    for j = 1:num_slices
        filepath = strcat(tif_path,filesep,tif_dir(j).name);
        img_slice = importdata(filepath);
        if length(size(img_slice)) == 3
            img_slice = mean(img_slice,3);
        end
        nrrd_img = cat(3,nrrd_img,img_slice);
    end
else
    nrrd_img = [];
    filepath = tif_path;
    img = importdata(filepath);
    if length(size(img)) == 3
        img = mean(img,3);
    end
    nrrd_img = cat(3,nrrd_img,img);
end
nrrd_img = rot90(nrrd_img);

% compile meta-data
space = 'left-posterior-superior';
if ~isempty(vox_size)
    if size(vox_size) == [3 3]
        space_directions = vox_size;
    elseif (size(vox_size) == [1 3]) || (size(vox_size) == [3 1])
        space_directions = [vox_size(1) 0 0; 0 vox_size(2) 0; 0 0 vox_size(3)];
    else
        warning('vox_size dimensions incompatible; defaulting to 1x1x1')
        space_directions = [1 0 0; 0 1 0; 0 0 1];
    end
else
    space_directions = [1 0 0; 0 1 0; 0 0 1];
end

sizes = size(nrrd_img);
dim = length(sizes);

metadata = struct('spacedirections',space_directions,'type','unsigned char','dimension',dim,'space',space,'sizes',sizes,'encoding','gzip');

% save nrrd file
if strcmp(path_type,'directory')
    source_dir = tif_dir(1).folder;
else
    nrrdpath = split(tif_path,'/');
    source_dir = fullfile(nrrdpath(1:end-1));
end
if nrrd_prefix
    filename = nrrd_prefix;
else
    filename = split(source_dir,'/');
    filename = replace(filename(end),' ','-');
    filename = strrep(filename(end),' ','-');
    filename = filename{1};
end

save_dir = split(source_dir,'/');
save_dir = strjoin(save_dir(1:end-1),'/');


filepath = strcat(save_dir,filesep,filename,'.nrrd');

nrrd_file = struct('pixelData',nrrd_img,'metaData',metadata);
nrrdwrite(filepath,nrrd_file)
end
