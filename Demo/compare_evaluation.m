eval_name = "correctly_localized_queries";
thr = 60;
eval_name = sprintf('%s_occupance_%d%%.mat', eval_name, thr);


% without filtering
static = load(fullfile('/local1/homes/dubenma1/data/localization_service_dataset/Results_Broca_dataset_dynamic_1/static_1/hospital_real_objects_180_queries/evaluation-SPRING_Demo', eval_name));

% with filtering
dynamic = load(fullfile('/local1/homes/dubenma1/data/localization_service_dataset/Results_Broca_dataset_dynamic_1/dynamic_1/hospital_real_objects_180_queries/evaluation-SPRING_Demo', eval_name));

figure();

% plot3d([(0:size(scores,2))/2; 0 scores],'-b');
plot3d([static.thr_t;static.inMapScores],'-b','Marker','.','MarkerSize',20); hold on;
plot3d([dynamic.thr_t;dynamic.inMapScores],'-r','Marker','.','MarkerSize',20); hold on;
grid on;
% ax = gca
xticks(gca,[0.1,0.15,0.2,(1:8)/4])
xtickangle(-75)
ylim([0 100])
xlim([0 2])
% xticklabels(gca,strsplit(num2str(thr_t)))
hold on;
xlabel('Distance threshold [m]');
ylabel('Correctly localised queries [%]');
legend('without filtering', 'with filtering')
title(eval_name(1:end-4), 'Interpreter','none')

saveas(gcf,fullfile('tmp', eval_name(1:end-4)+".jpg"))