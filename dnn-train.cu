#include <iostream>
#include <string>
#include <dnn.h>
#include <dnn-utility.h>
#include <cmdparser.h>
using namespace std;

// void dnn_train(DNN& dnn, mat& trainX, mat& trainY, mat& validX, mat& validY, size_t batchSize);

int main (int argc, char* argv[]) {

  CmdParser cmd(argc, argv);

  cmd.add("training_set_file")
    .add("model_file", false);

  cmd.addGroup("Training options: ")
    .add("-v", "ratio of training set to validation set (split automatically)", "5")
    .add("--epoch", "number of maximum epochs", "inf")
    .add("--batch-size", "number of data per mini-batch", "32")
    .add("--type", "choose one of the following:\n"
	"0 -- classfication\n"
	"1 -- regression", "0");

  cmd.addGroup("Structure of Neural Network: ")
    .add("--hidden-struct", "specify the width of each hidden layer seperated by \"-\":\n"
	"Ex: 1024-1024-1024 for 3 hidden layer, each with 1024 nodes");

  cmd.addGroup("Pre-training options:")
    .add("--pre", "type of Pretraining. Choose one of the following:\n"
	"0 -- RBM (Restricted Boltzman Machine)\n"
	"1 -- Layer-wise", "0");

  if (!cmd.isOptionLegal())
    cmd.showUsageAndExit();

  string train_fn   = cmd[1];
  string model_fn   = cmd[2];
  string structure  = cmd["--hidden-struct"];
  int ratio	    = cmd["-v"];
  size_t batchSize  = cmd["--batch-size"];

  if (model_fn.empty())
    model_fn = train_fn + ".model";

  mat data, labels;
  getFeature(train_fn, data, labels);
  zeroOneLabels(labels);

  mat trainX, trainY, validX, validY;
  splitIntoTrainingAndValidationSet(
      trainX, trainY,
      validX, validY,
      ratio,
      data, labels);

  showSummary(data, labels);

  // Initialize hidden structure
  vector<size_t> dims = splitAsInt(structure, '-');
  dims.insert(dims.begin(), data.getCols());
  dims.push_back(labels.getCols());
  DNN dnn(dims);

  DataSet train(trainX, trainY),
	  valid(validX, validY);

  // Start Training
  dnn.train(train, valid, batchSize, L2ERROR);
  // dnn_train(dnn, trainX, trainY, validX, validY, batchSize);

  // Save the model
  dnn.save(model_fn);

  return 0;
}

/*void dnn_train(DNN& dnn, mat& trainX, mat& trainY, mat& validX, mat& validY, size_t batchSize) {

  printf("Training...\n");
  perf::Timer timer;
  timer.start();

  vector<mat> O(dnn.getNLayer());
  std::vector<mat> gradient;
  dnn.getEmptyGradient(gradient);

  size_t input_dim = trainX.getCols(),
	 output_dim= trainY.getCols();

  size_t Ein, Eout;
  size_t prevEout = validY.size();
  size_t MAX_EPOCH = 1024, epoch;

  size_t nTrain = trainX.getRows(),
	 nValid = validX.getRows();

  size_t nBatch = nTrain / batchSize,
         remained = nTrain - nBatch * batchSize;

  if (remained > 0)
    ++nBatch;

  for (epoch=0; epoch<MAX_EPOCH; ++epoch) {

    for (size_t b=0; b<nBatch; ++b) {

      size_t offset = b*batchSize;
      size_t nData = batchSize;

      if (b == nBatch - 1)
	nData = min(remained - 1, batchSize);

      dnn.feedForward(trainX, &O, offset, nData);

      // mat error = O.back() - trainY;
      mat error = calcError(O.back(), trainY, offset, nData);

      dnn.backPropagate(error, O, gradient);
      dnn.updateParameters(gradient, 5 * 1e-3);
    }

    dnn.feedForward(validX, &O);

    Eout = zeroOneError(O.back(), validY);

    if (Eout > prevEout && (float) Eout / nValid < 0.2)
      break;

    prevEout = Eout;
  }

  // Show Summary
  printf("\n%d epochs in total\n", epoch);
  timer.elapsed();

  dnn.feedForward(trainX, &O);
  Ein = zeroOneError(O.back(), trainY);

  printf("[   In-Sample   ] ");
  showAccuracy(Ein, trainY.size());
  printf("[ Out-of-Sample ] ");
  showAccuracy(Eout, validY.size());
}*/