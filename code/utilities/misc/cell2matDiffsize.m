function mat_var = cell2matDiffsize(cell_var)

if iscell(cell_var)
    n_cell = length(cell_var);
    max_size_x = 0;
    max_size_y = 0;
    for i=1:n_cell
        dim = size(cell_var{i});
        if dim(1) > max_size_x
           max_size_x = dim(1); 
        end  
        if dim(2) > max_size_y
           max_size_y = dim(2); 
        end
    end
    mat_var = zeros([max_size_x max_size_y n_cell]);
    for i=1:n_cell
        padsize_x = max_size_x - size(cell_var{i},1);
        padsize_y = max_size_y - size(cell_var{i},2);
        if padsize_x < 0
            padsize_x = 0;
        end
        if padsize_y < 0
            padsize_y = 0;
        end
        mat_var(:,:,i) = padarray(cell_var{i},[padsize_x padsize_y],0,'post');
    end
    cell_var = mat_var;
    dim = size(cell_var);
else
    disp('input variable is not a cell variable');
    mat_var = [];
end
