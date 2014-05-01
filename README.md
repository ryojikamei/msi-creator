msi-creator
===========

### MSI image creator

- make-builder-kvm.sh: make native build environment from generated target tree by nnl-builder's *target* scripts. It must be run beyond the host/cross environemnt.
- make-installer.sh: make installer iso from generated packages. It must be run on the build/native environment.


### Process Overview

**(nnl-builder/host)** run *cross* scripts on *host*  
		V  
**(nnl-builder/host)** 'cross-tools' is generated  
		V  
**(nnl-builder/host)** run *target* scripts on *host*  
		V  
**(nnl-builder/host)** 'target-tree' is generated  
		V  
**(msi-creator/host)** run build image script on *host*  
		V  
**(msi-creator/host)** build image is generated  
		V  
		V  
**(nnl-builder/build)** run *native* scripts on *build*  
		V  
**(nnl-builder/build)** native packages are generated and installed  
		V  
**(msi-creator/build)** run install image script on *build*  
		V  
**(msi-creator/build)** installation image is generated  
		V  
		V  
**(msi,etc./target)** Run installer onto the target machine  
		V  
**(msi,etc./target)** Desirable environment are run on the target machine  

