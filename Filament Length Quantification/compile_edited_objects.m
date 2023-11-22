function [total_mat_pixels] = compile_edited_objects(standalone_filaments,multi_part_filaments, branches_pixels_mat,skel_matrix_pixels_final); 

%this functions adds edited objects into the object pixel matrix.

%this section makes sure there are the same number of columns between the branches pixel matrix and the total skeleton matrix pixels
if size(branches_pixels_mat,2) > size(skel_matrix_pixels_final,2) 
    skel_matrix_pixels_final(:,(size(skel_matrix_pixels_final, 2) +1):size(branches_pixels_mat,2)) = 0;  
elseif size(branches_pixels_mat,2) < size(skel_matrix_pixels_final,2) 
     branches_pixels_mat(:,(size(branches_pixels_mat, 2) +1):size(skel_matrix_pixels_final,2)) = 0;
end

standalone_filaments = nonzeros(standalone_filaments);
multi_part_rows = multi_part_filaments(multi_part_filaments(:,1)~=0); 
new_branch_mat = zeros((length(standalone_filaments)+length(multi_part_rows)),size(skel_matrix_pixels_final, 2)); %just the new branches 
%it will added to the skel_matrix_pixels_final at end 
new_branch_mat(1:length(standalone_filaments),:) = branches_pixels_mat(standalone_filaments,:);   
idx = length(standalone_filaments) + 1; %the row where multi_part segments will be added

for i = 1:length(multi_part_rows)     
    row_num = multi_part_rows(i); 
    start = 1;   
    multi_part_row = multi_part_filaments(row_num,:); 
    sorted_row = sort(multi_part_row(multi_part_row ~= 0),2,'ascend');
    for j = 1:length(sorted_row)     
    coord = nonzeros(branches_pixels_mat(sorted_row(j),:)); 
    num_coord = length(coord);  
    new_branch_mat(idx, start:start + num_coord - 1) = coord;
    start = start + num_coord;
    end  
    idx = idx + 1;
end   
  
if size(new_branch_mat,2) > size(skel_matrix_pixels_final,2) 
    skel_matrix_pixels_final(:,(size(skel_matrix_pixels_final, 2) +1):size(new_branch_mat,2)) = 0; %makes sure there are the same number of cols
elseif size(new_branch_mat,2) < size(skel_matrix_pixels_final,2) 
     new_branch_mat(:,(size(new_branch_mat, 2) +1):size(skel_matrix_pixels_final,2)) = 0;
end 

total_mat_pixels = [new_branch_mat;skel_matrix_pixels_final];

end 