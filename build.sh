#!/bin/bash

# Get the system's architecture
arch=$(uname -m)

# Check if the architecture is not x86 or x86-64
if [ "$arch" != "x86_64" ] && [ "$arch" != "x86" ]; then
  echo "Unsupported architecture: $arch"
  exit 1
fi

#!/bin/bash

# Function to check if a command is available
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to install packages on Debian-based distributions
install_debian_packages() {
  sudo apt update
  sudo apt install -y flex bc
}

# Function to install packages on Red Hat-based distributions
install_redhat_packages() {
  sudo dnf install -y flex bc   # For Fedora, CentOS, RHEL
  #sudo yum install -y flex bc  # For older versions of CentOS and RHEL
}

# Function to install packages on Arch Linux
install_arch_packages() {
  sudo pacman -Syu --noconfirm flex bc
}

# Check if the required packages are already installed
if ! command_exists flex || ! command_exists bc; then
  # Detect the Linux distribution
  if command_exists lsb_release; then
    distro=$(lsb_release -si)
  else
    distro=$(cat /etc/*-release | grep '^ID=' | awk -F'=' '{print tolower($2)}' | tr -d '"')
  fi

  # Install packages based on the detected distribution
  case $distro in
    debian|ubuntu)
      install_debian_packages
      ;;
    fedora|centos|rhel)
      install_redhat_packages
      ;;
    arch)
      install_arch_packages
      ;;
    *)
      echo "Unsupported distribution: $distro"
      echo "Please install it manually!"
      echo "Packages: bc flex"
      exit 1
      ;;
  esac
fi

# Clone GCC & Proton Clang.
if [ -d "$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/" ]; then
  echo "GCC exist"
else
  echo "GCC not exist"
  echo "Downloading GCC Toolchain!"
  wget -q --show-progress https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/0a0604336d4d1067aa1aaef8d3779b31fcee841d.tar.gz
  mkdir -pv $(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/
  tar xfv 0a0604336d4d1067aa1aaef8d3779b31fcee841d.tar.gz -C $(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/
  rm -v 0a0604336d4d1067aa1aaef8d3779b31fcee841d.tar.gz
fi

if [ -d "$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/" ]; then
  echo "Clang exist"
else
  echo "Clang not exist"
  echo "Downloading Clang Toolchain!"
  wget -q --show-progress https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/tags/android-11.0.0_r3/clang-r383902.tar.gz
  mkdir -pv $(pwd)/toolchain/clang/host/linux-x86/clang-r383902/
  tar xfv clang-r383902.tar.gz -C $(pwd)/toolchain/clang/host/linux-x86/clang-r383902/
  rm -v clang-r383902.tar.gz
fi

# Export ARCH/SUBARCH flags.
export ARCH="arm64"
export SUBARCH="arm64"

# Export toolchain/clang/llvm flags
export CROSS_COMPILE="$(pwd)/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-"
export CLANG_TRIPLE="aarch64-linux-gnu-"
export CC="$(pwd)/toolchain/clang/host/linux-x86/clang-r383902/bin/clang"
export KCFLAGS=-w
export CONFIG_SECTION_MISMATCH_WARN_ONLY=y

threads=$(nproc)
ram=$(free -h --si | awk '/^Mem:/ {print $2}')

# Build
echo ""
echo "Starting Building"
echo "Threads" $threads
echo "RAM" $ram
make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y a03s_defconfig
#make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y menuconfig
make -C $(pwd) O=$(pwd)/out KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y -j`$threads`

echo "Building done!"
echo "You can check the result in out/arch/arm64/boot/Image "
