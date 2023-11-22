function  [new_multi_perimeters, skeleton, multi_branch_fil] = resolve_multisegment_fil(clicked_branch,branches_pixels_mat,... 
                                                                     branches_of_interest,branches_of_interest_pixels, ... 
                                                                     branches_props,branches_og_perimeters,skeleton);   
   
                                                                 
multiseg_perimeter = zeros(1,10);  
%program will eventually be expanded to have a multi-part segment rather than just a two parter
segment_count = 1; 
multi_branch_fil= zeros(1,10);

multiseg_perimeter(1)=branches_og_perimeters(clicked_branch);  
multi_branch_fil(1)= clicked_branch;

xlabel({'Select the remaining segments of this filament.';'Press enter when finished.'},'FontSize',16,'FontWeight','bold');
[x2,y2]=myginput(1,'arrow');   
while length(x2)==1   
        new_clicked_branch = closest_to_click(x2,y2,branches_of_interest_pixels); 
        if isempty(new_clicked_branch) || branches_of_interest(new_clicked_branch) == clicked_branch; 
            xlabel({'No additional segment selected.';'Try clicking again.'},'FontSize',16,'FontWeight','bold'); 
            [x2,y2]=myginput(1,'arrow'); 
        else; 
            new_clicked_branch = branches_of_interest(new_clicked_branch);
            skeleton(branches_props(new_clicked_branch).PixelIdxList)=0;  
            segment_count = segment_count + 1;  
            multi_branch_fil(segment_count) = new_clicked_branch; 
            multiseg_perimeter(segment_count) = branches_og_perimeters(new_clicked_branch); 
            plot(branches_pixels_mat(new_clicked_branch,1:2:end),branches_pixels_mat(new_clicked_branch,2:2:end),... 
                'g.','MarkerSize',8);   
            if ismember(nonzeros(multi_branch_fil),branches_of_interest); 
                x2 =[]; 
            else;
             xlabel({'Select another segment or press enter to move on.'},'FontSize',16,'FontWeight','bold'); 
            [x2,y2]=myginput(1,'arrow');      
            end
        end
end 
        multiseg_perimeter(multiseg_perimeter == 0) = []; 
        new_multi_perimeters= sum(multiseg_perimeter);    
        
end 