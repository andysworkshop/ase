#
# Build script for Andy's Sprite Engine (ASE)
#

# These variables must be set correctly

STM32PLUS_INSTALL_DIR = "/usr/local/arm-none-eabi"
STM32PLUS_VERSION     = "030300"

import os
import platform
import subprocess

def usage():

  print """
Usage scons [fpga=<FPGA>] mode=<MODE>

  <FPGA>: synthesize/translate/map/par/bitgen. Default = bitgen.
    synthesize = xst
    translate  = ngdbuild
    map        = map
    par        = place & route + static timing
    bitgen     = create .bit file

  <MODE>: debug/fast/small.
    debug = -O0
    fast  = -O3
    small = -Os

  Examples:
    scons mode=debug
    scons mode=fast
    scons mode=small
"""

# mode argument must be supplied

mode=ARGUMENTS.get('mode')

if not (mode in ['debug', 'fast', 'small']):
    usage()
    Exit(1)

# get the FPGA option

fpga=ARGUMENTS.get("fpga")

if fpga is None:
  fpga="bitgen"
elif not (fpga in ["synthesize","translate","map","par","bitgen"]):
  usage()
  Exit(1)

# set up build environment and pull in OS environment variables

env=Environment(ENV=os.environ)

# verify that stm32plus is installed in the defined location

stm32plus_lib=STM32PLUS_INSTALL_DIR+"/lib/stm32plus-"+STM32PLUS_VERSION+"/libstm32plus-"+mode+"-f4-8000000-hard.a"
if not os.path.isfile(stm32plus_lib):
    print stm32plus_lib+" does not exist."
    print "Please edit SConstruct and check the STM32PLUS_INSTALL_DIR and STM32PLUS_VERSION variables."
    Exit(1)

# replace the compiler values in the environment

env.Replace(CC="arm-none-eabi-gcc")
env.Replace(CXX="arm-none-eabi-g++")
env.Replace(AS="arm-none-eabi-as")

# create the C and C++ flags that are needed. We can't use the extra or pedantic errors on the ST library code.

env.Replace(CCFLAGS=["-Wall","-Werror","-mfloat-abi=hard","-ffunction-sections","-fdata-sections","-fno-exceptions","-mthumb","-gdwarf-2","-pipe","-mcpu=cortex-m4","-DSTM32PLUS_F4","-DHSE_VALUE=8000000"])
env.Replace(CXXFLAGS=["-Wextra","-pedantic-errors","-fno-rtti","-std=gnu++0x","-fno-threadsafe-statics"])
env.Append(ASFLAGS="-mcpu=cortex-m4")
env.Append(LINKFLAGS=["-Xlinker","--gc-sections","-mthumb","-g3","-gdwarf-2","-mcpu=cortex-m4","-mfloat-abi=hard","-mfpu=fpv4-sp-d16"])
env.Append(LINKFLAGS=["-Wl,-wrap,__aeabi_unwind_cpp_pr0","-Wl,-wrap,__aeabi_unwind_cpp_pr1","-Wl,-wrap,__aeabi_unwind_cpp_pr2"])

# mode specific debug/optimisation levels

if mode=="debug":
    env.Append(CCFLAGS=["-O0","-g3"])
elif mode=="fast":
    env.Append(CCFLAGS=["-O3"])
elif mode=="small":
    env.Append(CCFLAGS=["-Os"])

# set the include directories - not a simple task on cygwin

if "cygwin" in platform.system().lower():

  # g++ must see the windows style C:/foo/bar path, not the cygwin /usr/foo/bar style so we must translate the
  # paths here. also, scons will try to interpret ":" as a separator in cygwin which gives us the additional problem
  # of not being able to use the interpreted CPPPATH. We have to use CXX flags instead. 

  proc=subprocess.Popen("cygpath --mixed "+STM32PLUS_INSTALL_DIR,stdout=subprocess.PIPE,shell=True)
  (cygbasepath,err)=proc.communicate()
  cygbasepath=cygbasepath.rstrip("\n");     # chomp the newline

  env.Append(CCFLAGS="-I"+cygbasepath+"/include/stm32plus-"+STM32PLUS_VERSION)
  env.Append(CXXFLAGS="-I"+cygbasepath+"/include/stm32plus-"+STM32PLUS_VERSION+"/stl")
  env.Append(LINKFLAGS="-L"+cygbasepath+"/lib/stm32plus-"+STM32PLUS_VERSION)

else:
  env.Append(CPPPATH=[
      STM32PLUS_INSTALL_DIR+"/include/stm32plus-"+STM32PLUS_VERSION,
      STM32PLUS_INSTALL_DIR+"/include/stm32plus-"+STM32PLUS_VERSION+"/stl"])
  
  env.Append(LIBPATH=STM32PLUS_INSTALL_DIR+"/lib/stm32plus-"+STM32PLUS_VERSION)

# common include directory

env.Append(CPPPATH="#common/stm32f429")

# set the library path

env.Append(LIBS="stm32plus-"+mode+"-f4-8000000-hard.a")

# replace the compiler values in the environment. The GNU ARM compilers first

env.Replace(CC="arm-none-eabi-gcc")
env.Replace(CXX="arm-none-eabi-g++")
env.Replace(AS="arm-none-eabi-as")
env.Replace(AR="arm-none-eabi-ar")
env.Replace(RANLIB="arm-none-eabi-ranlib")

# and now the Xilinx tools

env.Replace(XST="xst")
env.Replace(NGDBUILD="ngdbuild")
env.Replace(MAP="map")
env.Replace(PAR="par")
env.Replace(TRCE="trce")

# main design

main_bit=SConscript("main/xc3s50/SConscript",exports=["env","fpga"],duplicate=0);

# FPGA blink test

fpga_blink_bit=SConscript("tests/fpga_blink/xc3s50/SConscript",exports=["env","fpga"],duplicate=0);
fpga_blink_hex=SConscript("tests/fpga_blink/stm32f429/SConscript",
                          exports=["env","fpga_blink_bit","mode"],
                          variant_dir="tests/fpga_blink/stm32f429/build/"+mode,
                          duplicate=0);

# FPGA SRAM test

fpga_sram_bit=SConscript("tests/fpga_sram/xc3s50/SConscript",exports=["env","fpga"],duplicate=0);
fpga_sram_hex=SConscript("tests/fpga_sram/stm32f429/SConscript",
                          exports=["env","fpga_sram_bit","mode"],
                          variant_dir="tests/fpga_sram/stm32f429/build/"+mode,
                          duplicate=0);

# MCU LCD test

mcu_lcd_hex=SConscript("tests/lcd/SConscript",
                       exports=["env","mode","main_bit"],
                       variant_dir="tests/lcd/build/"+mode,
                       duplicate=0);

# MCU blink test

mcu_blink_hex=SConscript("tests/mcu_blink/SConscript",
                         exports=["env","mode"],
                         variant_dir="tests/mcu_blink/build/"+mode,
                         duplicate=0);

# MCU EEPROM test

mcu_eeprom_hex=SConscript("tests/mcu_eeprom/SConscript",
                          exports=["env","mode"],
                          variant_dir="tests/mcu_eeprom/build/"+mode,
                          duplicate=0);

# MCU SDIO test

mcu_sdio_hex=SConscript("tests/mcu_sdio/SConscript",
                        exports=["env","mode"],
                        variant_dir="tests/mcu_sdio/build/"+mode,
                        duplicate=0);

# flash programmer utility

flash_programmer_bit=SConscript("utilities/flash_programmer/xc3s50/SConscript",exports=["env","fpga"],duplicate=0);
flash_programmer_hex=SConscript("utilities/flash_programmer/stm32f429/SConscript",
                          exports=["env","flash_programmer_bit","mode"],
                          variant_dir="utilities/flash_programmer/stm32f429/build/"+mode,
                          duplicate=0);

# sprites demo

sprites_demo_hex=SConscript("main/stm32f429/sprites_demo/SConscript",
                          exports=["env","main_bit","mode"],
                          variant_dir="main/stm32f429/sprites_demo/build/"+mode,
                          duplicate=0);
