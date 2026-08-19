function fixNrrdMultiVolume(bruker_study_path,varargin)
% fixNrrdMultiVolume - fix a scan session's eispac-generated nrrd files,
% imported from PV360 DICOM files
%
% Usage:
%
% Required arguments:
%   bruker_study_path:
%
% Parameter value arguments:
%
%   isCompress: flag for turning on file compression (gzip)
%
% Example usage:
%

ip = inputParser;
ip.addRequired('bruker_study_path');
ip.addParameter('isCompress',false);

ip.parse(bruker_study_path,varargin{:});

isCompress = ip.Results.isCompress;

file_list =  rdir([bruker_study_path filesep 'nrrd' filesep '*.*']);
n_file = length(file_list);
for i_file = 1:n_file
    filepath = file_list(i_file).name;
    [~,filename,ext] = fileparts(filepath);
    tokens = regexp([filename ext],'(?<expno>[0-9]+) P(?<procno>[0-9]+).*\.(?:nrrd|nhdr)','names');
    expno = tokens.expno;
    procno = tokens.procno;
    dataset = getBrukerDatasetInfo([bruker_study_path filesep expno],str2num(procno));
    if length(dataset.dim)>3
        % only modify if multiple frames are detected
        dataset = get2dseq([bruker_study_path filesep expno],str2num(procno));
        imdata = dataset.data;
        isPV360 = strcmp(dataset.methodparx.pvVersion,'PV360');
        dim = dataset.dim;
        z_thickness = dataset.methodparx.PVM_SpatResol(3);
        n_frame = dim(4);
        
        assert(length(dim)==4, 'input image must have 4 dimensions exactly');
        
        % the external nrrd read/write functions we use assume the frame
        % dimension is in the first dimension
        
        % FIX 1: the rest of the processing code assumes that multivolumes
        % are defined with the frame dimension in the front.  This is the
        % case for DICOM data created by PV5.1, but not for PV360.
        % Therefore we take the data directly from 2dseq and permute it
        % ourselves
        imdata = permute(imdata,[4 1 2 3]);
        
        georef_header = nrrdread_header(filepath);
        
        % FIX 2: Slicer doesn't read the 3rd spatial dimension correctly,
        % and sets it to 1 by default.  We look up the proper voxel length
        % from the Bruker method file and change the 'space' and
        % ijkToLpsTransform parameters

        % the .space and the .ijkToLpsTransform fields are the only fields that
        % need to be provided to the nrrdwrite function - all other fields are
        % populated from this
        
        output_im.metaData.space = georef_header.metaData.space;
        output_im.ijkToLpsTransform = georef_header.ijkToLpsTransform;
        output_im.ijkToLpsTransform(:,3) = output_im.ijkToLpsTransform(:,3)*z_thickness;
        
        % populate some of the Multivolume fields in the nrrd header.
        
        output_im.metaData.MultiVolume_FrameIdentifyingDICOMTagName = 'Frame';
        output_im.metaData.MultiVolume_FrameIdentifyingDICOMTagUnits = 'Count';
        output_im.metaData.MultiVolume_NumberOfFrames = n_frame; 
        
        output_im.pixelData = imdata;
        
        if isCompress
            output_im.metaData.encoding='gzip';
        end
        
        nrrdwrite(filepath,output_im);
    end
    
end

