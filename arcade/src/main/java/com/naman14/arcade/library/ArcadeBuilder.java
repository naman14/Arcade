package com.naman14.arcade.library;

import android.content.Context;

/**
 * Created by naman on 12/05/16.
 */
public class ArcadeBuilder {

    private Context context;

    public String styleimage;
    public String contentImage;
    public String outputImage;
    public int gpu;
    public int iterations;
    public int imageSize;
    public String optimizer;
    public String modelFile;
    public String protoFIle;
    public String backend;
    public long styleScale;
    public String styleBlendWeights;
    public String styleLayers;
    public String contentLayers;
    public String pooling;
    public long tvWeight;
    public long styleWeight;
    public long contentWeight;
    public int seed;
    public int learningRate;
    public String init;
    public boolean normalizeGradients;
    public int printIterations;
    public int saveIterations;


    public ArcadeBuilder(Context context) {
        this.context = context;
        this.gpu = -1;
        this.styleimage = "/sdcard/examples/inputs/starry_night_crop.png";
        this.contentImage = "/sdcard/examples/outputs/golden_gate_scream.png";
        this.outputImage = "/storage/emulated/0/Arcade/output.png";
        this.iterations = 40;
        this.backend = "nn";
        this.optimizer = "adam";
        this.imageSize = 128;
        this.contentLayers = "relu0,relu3,relu7,relu12";
        this.styleLayers = "relu0,relu3,relu7,relu12";
        this.protoFIle = "/storage/emulated/0/models/train_val.prototxt";
        this.modelFile = "/storage/emulated/0/models/nin_imagenet_conv.caffemodel";
        this.contentWeight = 20;
        this.styleWeight = 200;
        this.printIterations = 1;
        this.saveIterations = 1;
        this.styleScale = 1L;
        this.pooling = "max";
        this.tvWeight = (long) 0.01;
        this.seed = 123;
        this.learningRate = 10;
        this.init = "image";
        this.styleBlendWeights = "nil";
        this.normalizeGradients = false;

    }

    public void setStyleimage(String styleimage) {
        this.styleimage = styleimage;
    }

    public void setContentImage(String contentImage) {
        this.contentImage = contentImage;
    }

    public void setOutputImage(String outputImage) {
        this.outputImage = outputImage;
    }

    public void setIterations(int iterations) {
        this.iterations = iterations;
    }

    public void setImageSize(int imageSize) {
        this.imageSize = imageSize;
    }

    public void setOptimizer(String optimizer) {
        this.optimizer = optimizer;
    }

    public void setModelFile(String modelFile) {
        this.modelFile = modelFile;
    }

    public void setProtoFIle(String protoFIle) {
        this.protoFIle = protoFIle;
    }

    public void setStyleScale(long styleScale) {
        this.styleScale = styleScale;
    }

    public void setStyleBlendWeights(String styleBlendWeights) {
        this.styleBlendWeights = styleBlendWeights;
    }

    public void setStyleLayers(String styleLayers) {
        this.styleLayers = styleLayers;
    }

    public void setContentLayers(String contentLayers) {
        this.contentLayers = contentLayers;
    }

    public void setPooling(String pooling) {
        this.pooling = pooling;
    }

    public void setGpu(int gpu) {
        this.gpu = gpu;
    }

    public void setBackend(String backend) {
        this.backend = backend;
    }

    public void setTvWeight(long tvWeight) {
        this.tvWeight = tvWeight;
    }

    public void setStyleWeight(long styleWeight) {
        this.styleWeight = styleWeight;
    }

    public void setContentWeight(long contentWeight) {
        this.contentWeight = contentWeight;
    }

    public void setSeed(int seed) {
        this.seed = seed;
    }

    public void setLearningRate(int learningRate) {
        this.learningRate = learningRate;
    }

    public void setInit(String init) {
        this.init = init;
    }

    public void setNormalizeGradients(boolean normalizeGradients) {
        this.normalizeGradients = normalizeGradients;
    }

    public void setPrintIterations(int printIterations) {
        this.printIterations = printIterations;
    }

    public void setSaveIterations(int saveIterations) {
        this.saveIterations = saveIterations;
    }

    public Arcade build() {
        return new Arcade(context, this);
    }
}
