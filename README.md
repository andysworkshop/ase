# Andy's Workshop Sprite Engine (ASE)

![Xilinx XC3S50](http://www.andybrown.me.uk/wk/wp-content/images/ase/fpga.jpg)

Welcome to the source repository that contains all the VHDL and C++ firmware associated with the ASE sprite graphics accelerator. If you got here without seeing the writeup for this project then I strongly recommend that you take the time to [read the writeup](http://andybrown.me.uk/wk/2014/06/01/ase) because this repo isn't going to make much sense otherwise.

# Building the firmware

I'm going to show you how to do a debug build. `fast` and `small` optimised build options are also available. Only the C++ builds are affected by the optimisation option. The VHDL designs are compiled the same regardless of the optimisation option you choose.

## Prerequisites

There are a few pre-requisites that we need to take care of before you can go ahead with the build.

1. I can provide advice for builds done on Linux or Windows with a Unix-alike build system. I use Cygwin on Windows 7 x64. Inevitably the Linux users are going to have a smoother ride.

2. Download and unpack the free [GNU Tools for ARM Embedded Processors](https://launchpad.net/gcc-arm-embedded) package. I require support for the hardware FPU in the STM32F429 and this toolchain supports it.

3.	[stm32plus](https://github.com/andysworkshop/stm32plus). Clone the `master` branch and do an `install` build for the `f4` configuration with the hard float option. Basically you'll be doing `scons mode=debug hse=8000000 mcu=f4 float=hard install`.

2. By the time you've built stm32plus your system is almost ready. Now you just need to download and install the free Xilinx ISE Webpack from their website. At the time of writing I'm using release 14.7. It's an absolute monster package so make sure you've got many gigabytes of free disk space.

## Build it

1. `cd` into this repo's top level directory and edit the `SConstruct` file. Check that the two variables at the top are correct for your system:

		STM32PLUS_INSTALL_DIR = "/usr/local/arm-none-eabi"
		STM32PLUS_VERSION     = "030400"
If you don't know which version of `stm32plus` that you installed then just take a look in the installation directory and you'll soon see it encoded into the directory names.

2. Ensure that the `arm-none-eabi` compiler from the GNU Tools for ARM Embedded Processors toolchain is in your `PATH`. That's the directory that contains the `arm-none-eabi-g++` executable and many others.

3. Ensure that the Xilinx tools are in your `PATH` environment variable. That's the directory that contains `xst` and others. On Cygwin I set that up like this: `export PATH=$PATH:/cygdrive/c/Xilinx/14.7/ISE_DS/ISE/bin/nt64`. You should be able to use that to figure out the correct path for your system.

4. `cd` into this repo's top level directory that contains the `SConstruct` file and run the build: `scons mode=debug`. Don't use the `-j` option, it doesn't play well with the VHDL dependencies. To clean up afterwards you can do `scons mode=debug -c`. 
<br/>
<br/>
The build will create the `.bit` Xilinx files and the C++ `.hex` files for uploading to the MCU. Where necessary the `.hex` files automatically compile in the associated `.bit` file for programming into the FPGA on startup.
