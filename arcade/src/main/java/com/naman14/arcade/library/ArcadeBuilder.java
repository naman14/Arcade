package com.naman14.arcade.library;

/**
 * Created by naman on 12/05/16.
 */
public class ArcadeBuilder {

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


    public ArcadeBuilder() {

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
}
