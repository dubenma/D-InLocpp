function show_boundary_of_render_on_sfere(iQ, C, img_size)
    X = [zeros(1,100)                     linspace(0,img_size(1)-1,100)     (img_size(1)-1)*ones(1,100)     linspace(img_size(1)-1,0,100)]; 
    Y = [linspace(0,img_size(2)-1,100)    (img_size(2)-1)*ones(1,100)       linspace(img_size(2)-1,0,100)   zeros(1,100)];
    proj = iQ * [X; Y; ones(1,length(X))];
    proj = proj .* (ones(3,1) * 1./sqrt(sum(proj.^2))) + C;  
    plot3(proj(1,:),proj(2,:),proj(3,:),'r-','LineWidth',3);
end

