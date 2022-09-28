function printErrors(errors)
    errorsTable = struct2table(errors);
    errors = table2struct(sortrows(errorsTable, 'queryId'));
    nErrors = size(errors,1);
    fprintf('id\ttranslation [m]\torientation [deg]\n');
    for i=1:nErrors
        fprintf('%d\t%0.2f\t%0.2f\n', errors(i).queryId, errors(i).translation, errors(i).orientation);
    end
    meanTranslation = mean([errors(~isnan([errors.translation])).translation]);
    meanOrientation = mean([errors(~isnan([errors.orientation])).orientation]);
    fprintf('Mean\t%0.2f\t%0.2f\n', meanTranslation, meanOrientation);
end