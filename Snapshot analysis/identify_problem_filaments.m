
function [problem_filaments] = identify_problem_filaments(skeleton)

endpts = bwmorph(skeleton, 'endpoints'); 
endpts_props = regionprops(endpts,'PixelList','Centroid');  
endpts_centroids=cat(1,endpts_props.Centroid);  
skeleton_pixels=regionprops(skeleton,'PixelList'); 
branchpoints=bwmorph(skeleton,'branchpoints');  
branchpoint_props=regionprops(branchpoints,'PixelList','Centroid','PixelIdxList'); 
branchpoint_centroids=cat(1,branchpoint_props.Centroid);

num_endpts=zeros(length(skeleton_pixels),1);  
num_branchpts=zeros(length(skeleton_pixels),1);
problem_filaments=zeros(1,length(num_endpts));

for filament = 1:length(skeleton_pixels); 
    for endpt_num = 1:length(endpts_centroids);  
        endpt_pixels=endpts_props(endpt_num).PixelList;  
        object_pixels=skeleton_pixels(filament).PixelList;   
        if ismember(endpt_pixels,object_pixels,'rows')
            num_endpts(filament)=num_endpts(filament)+1; 
        end  
    end
    for branchpoint_num=1:size(branchpoint_centroids,1); 
        branchpt_pixels=branchpoint_props(branchpoint_num).PixelList; 
        if ismember(branchpt_pixels,object_pixels,'rows')
            num_branchpts(filament)=num_branchpts(filament)+1; 
        end 
    end 
end 
    
for object_num =1:length(num_endpts); 
    if num_endpts(object_num)>2 || num_branchpts(object_num)>=1; 
        problem_filaments(object_num)=object_num;  
    end  
end  
problem_filaments(problem_filaments==0)=[];  
end 
    