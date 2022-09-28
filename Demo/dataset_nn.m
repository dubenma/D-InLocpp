clear
close all
startup;

%% set params 
experiment_name = "randomized_from_database";
% mode = "SPRING_Demo";
mode = "SPRING_Demo";
setenv("INLOC_EXPERIMENT_NAME",mode)
setenv("INLOC_HW","GPU")
[ params ] = setupParams(mode, true);

output_path = "/local1/projects/artwin/datasets/Broca_dataset/nn_dataset/";

% total_n = 15;
% ratio_close = 90; % how many percent should be close, the rest is far
% close_n = floor(total_n*ratio_close/100);


% offset for translation (1. row) and rotation (2. row)
offset = [0, ones(1,5)*0.3,     ones(1,4)*0.5, ones(1,3)*1, ones(1,2)*2; ...
          0, ones(1,12)*15, ones(1,2)*180];
offset(2, [6, 10, 13]) = 30;

t_offsets = offset(1,:); % in meters
th_offsets = offset(2,:); % in degrees

total_n = size(offset,2);

% should the images be resized?
resized = true;
resize_level = 1/3;

%% generate data

load(params.input.dblist.path);

for i = 1 : length(cutout_imgnames_all)
    output_dir = fullfile(output_path, params.dataset.name, experiment_name, string(i));
    output_file = fullfile(output_dir, 'query.mat');
    
    if ~(exist(output_file) == 2)    
        qname = cutout_imgnames_all{i};
        spaceName = split(qname, "/");spaceName = spaceName{1};   
        trueName = split(qname, "/");trueName = trueName{3};
        
        name_parts = split(trueName,"_");
        is_horizontal = name_parts{4} == "-90";
        
        if is_horizontal
            if ~exist(output_dir, 'dir')
                mkdir(output_dir)
            end
            % query
            Iq = imread(fullfile(params.dataset.dir, "cutouts_dynamic", qname));
            if resized
                Iq = imresize(Iq, resize_level);
            end
        %     figure();imshow(Iq)
        %     figure();imshow(fullfile(params.dataset.query.mainDir, spaceName, 'cutouts', string(panoDirId), trueName));

            % query mask
            if strcmp(params.dynamicMode, 'original') % staticky dataset, takze masky neexistuju
                mask = zeros(size(Iq));
            else
                mask_name = fullfile(params.dataset.dir, "masks_dynamic", qname(1:end-4)+".png");
                mask = imread(mask_name);
            end
            if resized
                imresize(mask, resize_level, 'nearest');
            end
        %     figure();imshow(mask)
        %     figure();imshow([rgb2gray(Iq) mask]);

            % query pose
            pose_path = fullfile(params.dataset.dir, "poses", qname + ".mat");
            ref_pose = load(pose_path);

            meshPath = fullfile(params.dataset.models.dir, spaceName, 'model.obj');
            if strcmp(mode, 'B315')
                meshPath = fullfile(params.dataset.models.dir, 'b315', 'model.obj');
            end
            fl = params.camera.fl;
            if resized
                fl = fl * resize_level;
            end

            sensorSize = [size(Iq,2), size(Iq,1)];

            % fixed 
        %     new_pose.C = ref_pose.position';
            rFix = [0., 180., 180.];
            Rfix = rotationMatrix(deg2rad(rFix), 'XYZ');
            if strcmp(mode,"B315")
                new_pose.R =Rfix*ref_pose.R;
            else
                new_pose.R =Rfix*ref_pose.R';
            end

            query = struct();
            query.true_name = trueName;
            query.query_img = Iq;
            query.qt_mask = mask;
            query.qname = qname;
            query.R = new_pose.R';
            query.C = ref_pose.position';

            parfor j = 1 : total_n

    %             if j == 1
    %                 t_max = 0;
    %                 th_max = 0;
    %             elseif j <= close_n
    %                 t_max = t_max_close;
    %                 th_max = th_max_close; 
    %             else
    %                 t_max = t_max_far;
    %                 th_max = th_max_far;
    %             end

                t_max = t_offsets(1,j);
                th_max = th_offsets(1,j);

                % random translation
                v2 =  rand(3,1);
                v2 = v2 / norm(v2);
                t = v2 * rand(1) * t_max;

                % random rotation
                v = rand(3,1);
                v = v / norm(v);
                th = rand(1) * th_max / 180 * pi;
                x_ = @(v) [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0];
                R = (1-cos(th)) * v*v' + cos(th) * eye(3) + sin(th) * x_(v);

                if j == 1
                    rot = new_pose.R';
                    trans = ref_pose.position';              
                else
                    rot = R*new_pose.R';
                    trans = ref_pose.position' + t;
                end

                error_rotation = rotationDistance(new_pose.R', rot);
                error_translation = norm(ref_pose.position' - trans);

                synth = struct();
                synth.R = rot;
                synth.C = trans;
                synth.error_rotation = error_rotation;
                if j == 1
                    synth.error_rotation = 0;
                end
                synth.error_translation = error_translation;
                synth.added_translation = t;
                synth.added_rotation.angle = th;
                synth.added_rotation.axis = v;
                synth.added_rotation.R = R;

                [RGBpersp, XYZpersp, depth] = projectMesh(meshPath, fl, rot, trans, sensorSize, false, -1, params.input.projectMesh_py_path, -1);
                synth.synth_img = RGBpersp;
    %             imshow(RGBpersp.*0.5 + Iq.*0.5)
    %         figure();
    %         imshow([RGBpersp);
        %     figure();
        %     imshow(Iq);
        %     figure();
        %     imshow(mask);
            output_synth_file = fullfile(output_dir, ['synth',num2str(j),'.mat']);
    %         imwrite(synth.synth_img*0.5 + query.query_img*0.5, fullfile(output_dir, 'compare.jpg'))
            parsavesynth(output_synth_file, synth)
            end
            save(output_file, 'query');
        end
    end
end

function parsavesynth(path, synth)
  save(path, 'synth')
end