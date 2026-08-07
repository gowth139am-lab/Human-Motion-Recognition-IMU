projectRoot = '/MATLAB Drive/HMD_proj_1';
cd(projectRoot)
fprintf('Reloading HMR_IMU project workspace...\n');

cd(fullfile(projectRoot, 'Dataset', 'UCI HAR Dataset'))
y_train = load(fullfile("train", "y_train.txt"));
y_test  = load(fullfile("test", "y_test.txt"));
y_train_cat = categorical(y_train);
y_test_cat  = categorical(y_test);

X_train = load(fullfile("train", "X_train.txt"));
X_test  = load(fullfile("test", "X_test.txt"));
cd(projectRoot)

if exist('Dataset/trainFeatures48.mat', 'file')
    load('Dataset/trainFeatures48.mat')
    load('Dataset/testFeatures48.mat')
    fprintf('Loaded trainFeatures48 / testFeatures48\n');
end

if exist('Models/bestActivityClassifier.mat', 'file')
    load('Models/bestActivityClassifier.mat')
    fprintf('Loaded trainedModel (Cubic SVM, 561-feature)\n');
end

if exist('Models/bestActivityClassifier48.mat', 'file')
    load('Models/bestActivityClassifier48.mat')
    fprintf('Loaded trainedModel48 (Linear SVM, 48-feature)\n');
end

if exist('Dataset/standing_features48.mat', 'file')
    load('Dataset/standing_features48.mat')
    fprintf('Loaded allFeatures (standing phone recording, 94x48)\n');
end

if exist('trainFeatures48', 'var')
    trainingTable48 = array2table(trainFeatures48);
    trainingTable48.Activity = y_train_cat;
    testTable48 = array2table(testFeatures48);
    testTable48.Properties.VariableNames = trainingTable48.Properties.VariableNames(1:48);
    testTable48.Activity = y_test_cat;
    fprintf('Rebuilt trainingTable48 / testTable48\n');
end

fprintf('Workspace reload complete.\n');
whos