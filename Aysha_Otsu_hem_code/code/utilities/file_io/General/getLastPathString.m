function last_path_str = getLastPathString(path_str)

path_parts = regexp(path_str,filesep,'split');
last_path_str = path_parts{end};
