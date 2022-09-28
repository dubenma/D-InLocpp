function [ inliers, model ] = verify_matches( obs1, obs2, pair_matches, ransac_threshold, K1, K2 )
%VERIFY_MATCHES - verify matches and compute F, l1, l2 parameters 
    
    % Ransac parameters
    params = struct();
    params.ransac_iters = 1000;
    params.ransac_threshold = ransac_threshold;
    params.match_threshold = ransac_threshold;
    params.lmax = 2;
    params.lmin = -10;

    % Calibration matrix
    dts = struct();
    dts.K1 = K1;
    dts.K2 = K2;
    dts.pts1 = double(obs1);
    dts.pts2 = double(obs2);
    dts.matches = pair_matches;

    % Fundamental matrix + radial distortion using F10e method
    params.method = getmethod_F10e;
    modelF10e = ransac(dts, params);
    
    % set output
    inliers = pair_matches(:,modelF10e.cset);
    model = modelF10e.geom;
   
%     % find focal
%     PP = E2PP(model.F');
%     for j = 1:length(PP{2})
%         [K2,R2,C2] = P2KRC(PP{2}{j});
%         K12 = K * K2;
%         model.fx = K12(1,1);
%         model.fy = K12(2,2);
%     end
end

