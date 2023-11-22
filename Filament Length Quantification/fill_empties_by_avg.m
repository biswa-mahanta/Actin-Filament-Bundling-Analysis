function [thresh_intensity_ROI] = fill_empties_by_avg(thresh_intensity_ROI,split_number);

a = find(isnan(thresh_intensity_ROI'));  

for i = 1:length(a);  
    if a(i) > split_number && length(thresh_intensity_ROI) >= (a(i) + split_number);   
        avg = mean([thresh_intensity_ROI(a(i) - split_number),thresh_intensity_ROI(a(i) - 1),thresh_intensity_ROI(a(i) + split_number), thresh_intensity_ROI(a(i) + 1)],'omitnan');
    elseif a(i) > 1 && length(thresh_intensity_ROI) >= (a(i) + split_number);
        avg =  mean([thresh_intensity_ROI(a(i) + 1),thresh_intensity_ROI(a(i) -1),thresh_intensity_ROI(a(i) +split_number)],'omitnan'); 
    elseif a(i) == 1; 
        avg =  mean([thresh_intensity_ROI(a(i) + 1),thresh_intensity_ROI(a(i) + split_number),thresh_intensity_ROI(a(i) + split_number + 1)],'omitnan'); 
    elseif length(thresh_intensity_ROI) > (a(i) + 1);  
        avg = mean([thresh_intensity_ROI(a(i) - split_number),thresh_intensity_ROI(a(i) - 1),thresh_intensity_ROI(a(i) + 1)],'omitnan'); 
    elseif length(thresh_intensity_ROI) == a(i);   
        avg =  mean([thresh_intensity_ROI(a(i)- 1),thresh_intensity_ROI(a(i) - split_number),thresh_intensity_ROI(a(i) - (split_number + 1))],'omitnan');  
    end   
    thresh_intensity_ROI(a(i)) = avg; 
end 