# os-image-tools

This is a collection of some hopefully usefull tools, for c15 development.

### [install_nuc_sdk.sh](install_nuc_sdk.sh):

Download and install an SDK for NUC development. This contains a cross toolchain, a debugger and the complete rootfs. 
The SDK has been created by hand using [yocto](https://www.yoctoproject.org/docs/2.1/sdk-manual/sdk-manual.html) and is downloaded from our [buildserver](http://home.nonlinear-labs.de/images/nuc_sdk/)

### [mk_bbb_image.sh](mk_bbb_image.sh):

Creates an SD card for the bbb using an image, created by yocto. Image Creation is also available in [TeamCity](http://home.nonlinear-labs.de:8111/project.html?projectId=NonlinearYoctoBbb&tab=projectOverview)

### [mk_nuc_install_media.sh](mk_nuc_install_media.sh):

Creates an USB Installation Medium for the NUC. Image Creation is also available in [TeamCity](http://home.nonlinear-labs.de:8111/project.html?projectId=NonlinearYoctoNuc&tab=projectOverview)

### [setup_nlaudio_debug_environment.sh](setup_nlaudio_debug_environment.sh):

Set's up and starts a debug environment for QtCreator for remote debugging on the NUC. This is not very stable, but get's you started easily.

