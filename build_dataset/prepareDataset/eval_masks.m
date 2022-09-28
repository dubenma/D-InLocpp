path = "/local1/homes/dubenma1/data/localization_service_dataset/Cache_Broca_dataset_dynamic_1/dynamic_1/hospital_real_objects_180_queries/yolact_masks_final/inputs-SPRING_Demo/queries_masks/";
masks = dir(path);

masks = masks(3:end);
dynamic_ratio = zeros(length(masks),1);

for i = 1 : length(masks)
    mask_img = imread(fullfile(masks(i).folder, masks(i).name));
    [h, w] = size(mask_img);
    n = sum(sum(logical(mask_img)));
    s = h*w;
    
    dynamic_ratio(i) = n/s;
end

dynamic_ratio = dynamic_ratio*100;
mean(dynamic_ratio)

N = 10;
bar_graph = zeros(N,1);

for i = 1 : N - 1
    bar_graph(i) = sum((dynamic_ratio > (i - 1)*10) & (dynamic_ratio <= i*10));
end

bar_graph = [sum(dynamic_ratio == 0); bar_graph];
bar_graph = bar_graph/length(masks)*100;

x = {'0','(0,10>','(10,20>','(20,30>','(30,40>','(40,50>','(50,60>','(60,70>','(70,80>','(80,90>','(90,100>'};
X = categorical(x);
X = reordercats(X,x);

bar(X, bar_graph);
xlabel('Area of the dynamic masks [%]');
ylabel('Percentage of queries with the masks [%]')
title('Broca\_dataset\_dynamic\_1')
ylim([0,50])
