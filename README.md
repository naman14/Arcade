# Arcade
Neural style in Android

Arcade is an experimental Android port of Torch-7 implementation of [neural-style](https://github.com/jcjohnson/neural-style).

Get the demo app from [Google Play](https://play.google.com/store/apps/details?id=com.naman14.arcade)

<img src="https://raw.githubusercontent.com/naman14/Arcade/master/graphics/screenshot1.png" width="400" height="730"/>
<img src="https://raw.githubusercontent.com/naman14/Arcade/master/graphics/screenshot2.png" width="400" height="730"/>
<img src="https://raw.githubusercontent.com/naman14/Arcade/master/graphics/screenshot3.png" width="400" height="730"/>
<img src="https://raw.githubusercontent.com/naman14/Arcade/master/graphics/screenshot5.png" width="400" height="730"/>

##Building
This repository contains prebuilt shared libraries needed to build [torch-android](https://github.com/soumith/torch-android) and libarcade.so. If you want to build the shared libraries go to [neural-style-android](https://github.com/naman14/neural-style-android) which is based on top of torch-android and adds support for Protobuf and loadcaffe. NIN ImageNet models are used in Arcade due to smaller size than VVG models. Models have to be seperately downloaded. Demo app module have a [ModelDownloader](https://github.com/naman14/Arcade/blob/master/app/src/main/java/com/naman14/arcade/ModelDownloader.java) class to download and place models in correct path

Build the libraries by NDK `ndk-build` and then directly run from Android studio. The build configuration is taken from `Android.mk ` in `src/main/jni` and Gradle's native build system is ignored (Gradle currently ignores existing Android.mk and I was unable to figure out how to include prebuilt shared libraries from Gradle).

Note - only `armeabi-v7a` libraries are built currently and app will not work on other architectures.

Arcade is built as a seperate Android library and contains a Builder for all styling settings and helper functions. You can use this library to create your own implementation. Regular callbacks are also provided from Lua -> C -> Java for progress, iteration updates, completion and Images saved listeners.

Most of the middelware code between java and lua is located in [arcade.cpp](https://github.com/naman14/Arcade/blob/master/arcade/src/main/jni/arcade.cpp)

##Usage
Usage is pretty straightforward. Compile library project and use builder to setup configuration.
```java
 ArcadeBuilder builder = new ArcadeBuilder(this);
      
  builder.setStyleimage(stylePath);
  builder.setContentImage(contentPath);
  builder.setModelFile(modelPath);
  builder.setProtoFIle(protoPath);
  builder.setImageSize(512);
  builder.setIterations(30);
   ....
  Arcade arcade = builder.build();
        
  //initialize and load lua script
  arcade.initialize();
  //set listeners
  arcade.setProgressListener(progressListener);
  //begin styling
  arcade.stylize();
         
```

##Results
Due to no no GPU and limited processing power and memory, the styling is pretty slow and unusable for image sizes greater than 512. Due to speed limitations, getting respectable result is only unlikely. Better results can be achieved by trying different combination of style settings like style weight, content weight and number of iterations.

##### 30 iterations,Image Size - 256, Device - Nexus 6, Time taken - 25 minutes
<img src="https://raw.githubusercontent.com/naman14/Arcade/master/graphics/outputs/goldengatestarry.png"/>

##### 15 iterations,Image Size - 512, Device - Nexus 6, Time taken - 40 minutes
<img src="https://raw.githubusercontent.com/naman14/Arcade/master/graphics/outputs/scream.png"/>

##Conclusion
I started this project just for experimenting the end result of this thing. I wouldn't say that results are great though can be better by trying different combinations and improving things in the code. On CUDA enabled devices (Tegra K1), this should be a lot faster but support for cutorch is not there currently. Contributions are welcome!

