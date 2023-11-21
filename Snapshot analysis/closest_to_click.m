
function [closest_object] = closest_to_click(og_x,og_y,matrix_pixels); 

x_vals_pixels = matrix_pixels(:,1:2:end); %list of all x coordinates for objects
y_vals_pixels = matrix_pixels(:,2:2:end); %list of all y coordinates for objects 

%gives range of acceptable values based off of user click 
x=round(og_x);x=(x-15:x+15)';x(x<=0)=[]; 
y=round(og_y);y=(y-15:y+15)';y(y<=0)=[];

%finds objects that include the same x value as the user click 
[objects_same_x,colnum,~]=find(ismember(x_vals_pixels,intersect(x_vals_pixels,x))); 
%initializes variables for loop 
points_same_xy = zeros(length(objects_same_x),2); 
closest_object = zeros(length(objects_same_x),1);
for i = 1:length(objects_same_x);   %cycles through x intersections
    y_hit = y_vals_pixels(objects_same_x(i),colnum(i)); 
    if intersect(y_hit,y);  %if y also intersects with the user click
        closest_object(i) = objects_same_x(i); %place that object index into the closest_object matrix 
        points_same_xy(i,1:2) = matrix_pixels(objects_same_x(i),colnum(i):colnum(i)+1);  
    end 
end 
        points_same_xy = points_same_xy(any(points_same_xy,2),:); %removes extra zeros, keeps format intact 
        closest_object(closest_object==0)=[];   %removes extra zeros from closest_object matrix 


if length(closest_object)> 1; %if more than one object was within 15 pixels of the click in both the x and y direction
   distance = sqrt((og_x - points_same_xy(:,1)).^2 + (og_y - points_same_xy(:,2)).^2); 
   % the above line finds the distance between the click and the nearest pixel
   [~,row_num]=(min(distance));  %finds the object with the minimum distance from click
   closest_object = closest_object(row_num); %closest_object is index of the closest object from the user click.
end   

end  
 

