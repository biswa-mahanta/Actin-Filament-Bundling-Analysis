function [matrix_pixels] = pixel_struct_to_mat(num_objects,stats) 

%the purpose of this function is to reformat a structure containing a list
%of pixel coordinates into a matrix, which I found easier to use and cuts
%down on the number of loops needed.
%this will turn a pixel_list field intro a matrix with the following
%format where the row number is the object number and the columns are: [x1 y1 x2 y2 x3 y3...] 
%will fill have 0s at the end since col number must be the same
matrix_pixels= zeros(num_objects, 700);  
%wanted to choose a large pixel size in case there is a very large object, don't want to throw an error. 
for i =1:num_objects; 
    matrix_pixels(i,1:2*length(stats(i).PixelList(:,2)))= reshape(stats(i).PixelList',1,[]);  
end   

matrix_pixels=matrix_pixels(:,any(matrix_pixels)); %removes any columns that only contain zeros

end 