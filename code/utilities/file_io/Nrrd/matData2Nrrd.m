function matData2Nrrd(imdata,dest_path,dest_filename,varargin)
% matData2Nrrd - convert matlab data to nrrd format
%
% Usage:
%   matData2Nrrd(imdata,dest_path,dest_filename)
%   matData2Nrrd(imdata,dest_path,dest_filename,PARAM,VALUE)
%
% Required arguments:
%   imdata:  the image data.  If it has 4 dimensions, the multivolume
%            frames should be in the 4th dimension
%
%   dest_path:  destination path for the nrrd file
%
%   dest_filename:  filename of new nrrd file
%
% Parameter value arguments:
%   geometry_nrrd_reference_path:  full file path of another nrrd file
%   which shares the same geometry.  Its geometry information will be
%   copied to the new nrrd file
%
%   vox_size:  if there is no geometry_nrrd_reference_path, a voxel size in
%   mm can be defined (3 element vector).  If nothing specified and no
%   geometry reference, the voxel size is 1mm isotropic by default.
%
%   isCompress: flag for turning on file compression (gzip)
%
% Example usage:
%
% georef_path = '/datadrive/bruker-backup/mriuser/nmr/KWON43_HemPilot_Amethyst.3f1/nrrd/8 P1 07_MGE_sag_MEDIC(modified) - as a 8 frames MultiVolume by EchoTime.nhdr';
% dataset = nrrdread(georef_path);
% data = dataset.pixelData;
% data = squeeze(data(1,:,:,:));
% matData2Nrrd(data,'~','single_echo.nrrd', 'geometry_nrrd_reference_path', georef_path);

ip = inputParser;
ip.addRequired('imdata');
ip.addRequired('dest_path');
ip.addRequired('dest_filename');
ip.addParameter('geometry_nrrd_reference_path','',@(x) isstr(x));
ip.addParameter('vox_size',[]);
ip.addParameter('isCompress','');

ip.parse(imdata,dest_path,dest_filename,varargin{:});

vox_size = ip.Results.vox_size;
geometry_nrrd_reference_path = ip.Results.geometry_nrrd_reference_path;
isCompress = ip.Results.isCompress;

if ~isempty(geometry_nrrd_reference_path)
    isReferenceSpecified = true;
else
    isReferenceSpecified = false;
end

if ~isReferenceSpecified
    if isempty(vox_size)
        vox_size = [1 1 1];
    end
end

dim = size(imdata);
assert(length(dim)<6, 'input image must have 6 dimensions or less');


% the external nrrd read/write functions we use assume the frame
% dimension is in the first dimension
n_dim = length(dim);
if n_dim == 4
    imdata = permute(imdata,[4 1 2 3]);
elseif n_dim == 5
    imdata = permute(imdata,[4 5 1 2 3]);
end
    

if isReferenceSpecified
    georef_im = nrrdread_header(geometry_nrrd_reference_path);

    % the .space and the .ijkToLpsTransform fields are the only fields that
    % need to be provided to the nrrdwrite function - all other fields are
    % populated from this
    output_im = struct();
    output_im.metaData.space_origin = georef_im.metaData.space_origin;
    output_im.metaData.space_directions = georef_im.metaData.space_directions;
    output_im.ijkToLpsTransform = georef_im.ijkToLpsTransform;
    output_im.metaData = georef_im.metaData; 
    if isfield(output_im.metaData,'data_file') % remove datafile from structure to prevent errors attempting to open versions of the file renamed for "outputs"
        output_im.metaData = rmfield(output_im.metaData,'data_file'); 
    end
else
    % if no geometry reference was provided, output nrrd file has no
    % offsets or angles
    output_im.ijkToLpsTransform = [vox_size(1) 0 0 0; 0 vox_size(2) 0 0; 0 0 vox_size(3) 0; 0 0 0 1];
end

output_im.pixelData = imdata;

if isCompress
    output_im.metaData.encoding='gzip';
else
    output_im.metaData.encoding='raw';
end

if length(size(imdata))==3
    if isfield(output_im,'metaData')
        metaDataFieldnames = fieldnames(output_im.metaData);
        n_field = length(metaDataFieldnames);
        for i=1:n_field
            if contains(metaDataFieldnames{i},'MultiVolume')
                output_im.metaData = rmfield(output_im.metaData,metaDataFieldnames{i});
            end
        end
    end
    output_im.metaData.space_directions = strrep(output_im.metaData.space_directions,'none ','');
    output_im.metaData.kinds = strrep(output_im.metaData.kinds,'list ','');   
end

nrrdwrite([dest_path filesep dest_filename],output_im);
