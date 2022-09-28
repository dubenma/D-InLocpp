function projectedPoints = projectPointsUsingP(points, P)
    % points: 3xn matrix
    nCorrespondences = size(points,2);
    toProject = [points; ones(1,nCorrespondences)];
    projectedPoints = P * toProject;
    projectedPoints = projectedPoints ./ projectedPoints(3,:);
    projectedPoints = projectedPoints(1:2,:);
end