function im_synth = getSynthView(params,ImgList,q_id,db_rank,showMontage,savePth,prefix)
            qname =  ImgList(q_id).queryname;
            dbname = ImgList(q_id).topNname;  dbname= dbname{db_rank};
            Iq = imread(fullfile(params.dataset.query.mainDir, qname));
            fl = params.camera.fl;
            P = ImgList(q_id).Ps; P = P{db_rank}{1};
            R = P(1:3,1:3);
            t = P(1:3,4);
            spaceName = strsplit(dbname, '/');
            spaceName = spaceName{1};
            meshPath = fullfile(params.dataset.models.dir, spaceName, 'model.obj');
%             meshPath = fullfile(params.dataset.models.dir, 'model_rotated.obj');
%             t = -inv(R)*t;
             rFix = [0.0, 180.0, 180.0];
             Rfix = rotationMatrix(deg2rad(rFix), 'XYZ');
            sensorSize = [size(Iq,2), size(Iq,1)];
            headless = ~strcmp(environment(), 'laptop');          
            rot = inv(R)*Rfix';
            trans = -inv(R)*t;
            disp(qname);
            [RGBpersp, XYZpersp, depth] = projectMesh(meshPath, fl, rot, trans, sensorSize, false, -1, params.input.projectMesh_py_path, headless);
            if showMontage
%                 errmaps =load(fullfile(params.output.synth.dir, ImgList(q_id).queryname, sprintf('%d%s', db_rank, params.output.synth.matformat)),'errmaps');
%                 errmaps= grs2rgb(errmaps.errmaps{1});
                blend = Iq/2 + RGBpersp/2;
                comparison = {Iq,RGBpersp,blend,imread(fullfile(params.dataset.db.cutout.dir, dbname))};
                f = figure('visible','off');
                montage(comparison,'Size',[1 4]);
                if nargin >= 6
                    if nargin >=7
                        mkdirIfNonExistent(savePth);
                        saveas(f,fullfile(savePth,sprintf('%s_results_q_id_%d_best_db_%d.jpg',prefix,q_id,db_rank)));
                    else
                    saveas(f,fullfile(savePth,sprintf('results_q_id_%d_best_db_%d.jpg',q_id,db_rank)));
%                     close(f);
                    end
                end
                
            end
            im_synth = RGBpersp;
end