function [branches_of_interest] =highlight_branches(boxes,skeleton_stats,problem_index,num_branches,branches_pixels_mat)
 % highlight_box  
 
 subplot(1,2,2); 
 rectangle('Position',[boxes(problem_index,1)-12,boxes(problem_index,2)-12,... 
     boxes(problem_index,3)+20,boxes(problem_index,4)+20],'EdgeColor','w','LineWidth',2);    
 
 %find branches in original_filament
 object_pixels = skeleton_stats(problem_index).PixelList;  
 %the object that I want to separate into branches
 
x_vals_branches = branches_pixels_mat(:,1:2:end);  
y_vals_branches = branches_pixels_mat(:,2:2:end);
common_xvals= intersect(x_vals_branches,object_pixels(:,1));   
%finds intersecting x_values between branches and object  
[xrows,xcols] = find(ismember(x_vals_branches,common_xvals)); 
%finds the branches (xrows) and at what points (xcols) is there an intersection?
branches_of_interest = zeros(num_branches,1);
xy_hit=zeros(length(xrows),2);
for i = 1:length(xrows);  
    xy_hit(i,1:2) = [x_vals_branches(xrows(i),xcols(i)),y_vals_branches(xrows(i),xcols(i))];
    if intersect(xy_hit(i,1:2),object_pixels,'rows');  
        branches_of_interest(i) = xrows(i);
    end 
end   
branches_of_interest=unique(branches_of_interest); branches_of_interest(branches_of_interest==0)=[];
color_options = repmat(['m';'y';'c';'w'],4);  
%plots branches in different colors 
for i = 1:length(branches_of_interest); 
    plot(branches_pixels_mat(branches_of_interest(i),1:2:end),branches_pixels_mat(branches_of_interest(i),2:2:end),... 
        strcat(color_options(i),'.'),'MarkerSize',6);    
end 

end

