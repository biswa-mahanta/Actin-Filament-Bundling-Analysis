function write_videos(frame_count,movie,time_snapshots,scale_bar_x,scale_bar_y,skeletons,pixel_lists,all_bundled_coords);  
fig = figure('Position', [0 0 1440 900]); %make analysis figure 
vid = VideoWriter(replace(movie.Name,'.avi','_analysis'));  
vid.FrameRate = 5; 
open(vid);  
for frame = 1:frame_count-1;  
    subplot(1,2,1);imshow(time_snapshots{frame},[],'InitialMagnification','fit');  
    title("Original Movie",'FontSize',24);    
    subplot(1,2,2); 
    imshow(skeletons{frame},[],'InitialMagnification','fit'); hold on; title("Detected Crosslinking",'FontSize',24);
    plot(pixel_lists{frame,1},pixel_lists{frame,2}, 'm.','MarkerSize',8);  %green
    plot(all_bundled_coords{frame,1},all_bundled_coords{frame,2},'y.','MarkerSize',8); %yellow  
%     if frame < 10; % this part adds scale bar for the first ten frames, saves time in later frames
%        plot(scale_bar_x,scale_bar_y, 'LineWidth',7,'Color','white'); %scale bar 
%        text(min(scale_bar_x) + (length(scale_bar_x)/10*.1), scale_bar_y(1) +10,... 
%             '10 \mum', 'Color','white','FontSize',13,'FontWeight','bold'); %scale bar label
%     end  
        analysis_frame = getframe(fig);  
        writeVideo(vid,analysis_frame); 
        clf(fig);
end     
    close(vid);     
    close(fig);
end 