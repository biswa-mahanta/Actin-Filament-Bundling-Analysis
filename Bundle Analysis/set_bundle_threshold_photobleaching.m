

function [bundled_fils,brightness_threshold] = set_bundle_threshold_photobleaching(max_intensities, final_matrix_pixels)   
%figure;hist(max_intensities); xlabel('Normalized Brightness (\mum)','FontSize',18);
%ylabel('Frequency','FontSize',18);     

group = uibuttongroup('Position',[0.6861, 0.06335, 0.11730, 0.124165],'SelectedObject',[]);
higher_thresh = uicontrol(group,'Style','togglebutton','Position',[7 58 150 30],'String', 'Raise Threshold','FontSize',13,'FontWeight','bold',... 
    'Callback','uiresume');  
lower_thresh = uicontrol(group,'Style','togglebutton','Position',[7 30 150 30],'String', 'Lower Threshold','FontSize',13,'FontWeight','bold',  'Callback', 'uiresume');  
done = uicontrol(group,'Style','togglebutton','Position', [7 2 150 30],'String', 'Done','FontSize',13,'FontWeight','bold','Callback','uiresume;');  
brightness_threshold = mean(max_intensities) + std(max_intensities); %basically randomly set 
bundled_fils = find(max_intensities > brightness_threshold);
yellow_lines = plot(final_matrix_pixels(bundled_fils,1:2:end),... 
                    final_matrix_pixels(bundled_fils,2:2:end),'y.','MarkerSize',8);    
higher_thresh.Value = 0;
while done.Value == 0       
    title("Press the buttons below to adjust the bundle brightness threshold.",'FontSize',16); 
    uiwait;
    title({'Processing button press...'},'FontSize',16);
    delete(yellow_lines);  
     if lower_thresh.Value == 1
        brightness_threshold = brightness_threshold - 5;
        delete(lower_thresh); 
        lower_thresh = uicontrol(group,'Style','togglebutton','Position',[7 30 150 30],'String', 'Lower Threshold','FontSize',13,'FontWeight','bold',... 
        'Callback', 'uiresume');    
     elseif higher_thresh.Value == 1  
         brightness_threshold = brightness_threshold + 5; 
         delete(higher_thresh); 
         higher_thresh = uicontrol(group,'Style','togglebutton','Position',[7 58 150 30],'String', 'Raise Threshold','FontSize',13,'FontWeight','bold',... 
         'Callback','uiresume');   
     end   
     bundled_fils = find(max_intensities > brightness_threshold);
     yellow_lines = plot(final_matrix_pixels(bundled_fils,1:2:end),... 
                    final_matrix_pixels(bundled_fils,2:2:end),'y.','MarkerSize',8);
 end


delete(group); 
end 