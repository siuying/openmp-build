
VERSION=16.0.0
build() {
  # Build iOS
  PLATFORM=$1
  DEPLOYMENT_TARGET=$2
  BUILD_PATH="build-${PLATFORM}"
  export MACOSX_DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET
  mkdir -p $BUILD_PATH
  cd $BUILD_PATH
  cmake -G Xcode -DCMAKE_TOOLCHAIN_FILE=../ios.toolchain.cmake -DPLATFORM="${PLATFORM}" -DENABLE_BITCODE=0 -DCMAKE_INSTALL_PREFIX="../lib-${PLATFORM}" \
    -DLIBOMP_ENABLE_SHARED=OFF -DLIBOMP_OMPT_SUPPORT=OFF -DLIBOMP_USE_HWLOC=OFF \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" -DDEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}" ../openmp
  cmake --build . --config Release -- CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED="NO" CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO"
  cmake --install . --config Release
  cd ..
}

wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.0/cmake-${VERSION}.src.tar.xz"
wget "https://github.com/llvm/llvm-project/releases/download/llvmorg-16.0.0/openmp-${VERSION}.src.tar.xz"

# cmake ios toolchain
wget "https://raw.githubusercontent.com/leetal/ios-cmake/4.3.0/ios.toolchain.cmake"

# we need cmake modules to build openmp
tar vxfz "cmake-${VERSION}.src.tar.xz" "cmake-${VERSION}.src"
mv "cmake-${VERSION}.src" "cmake"

# we need openmp source
tar vxfz "openmp-${VERSION}.src.tar.xz" "openmp-${VERSION}.src"
mv "openmp-${VERSION}.src" "openmp"

# Build iOS
for PLATFORM in "OS64" "SIMULATORARM64"; do
  build $PLATFORM "11.0"
done

# Create iOS xcframeworks
mkdir -p "frameworks/ios"
rm -rf "frameworks/ios/OpenMP.xcframework"
xcodebuild -create-xcframework -library lib-OS64/lib/libomp.a -headers lib-OS64/include \
  -library lib-SIMULATORARM64/lib/libomp.a -headers lib-SIMULATORARM64/include \
  -output "frameworks/ios/OpenMP.xcframework"

# Build macOS
for PLATFORM in "MAC" "MAC_ARM64"; do
  build $PLATFORM "10.13"
done

# Create Mac xcframeworks
mkdir -p "frameworks/mac"
rm -rf "frameworks/mac/OpenMP.xcframework"

mkdir -p lib-MAC-universal/lib/
lipo -create -output lib-MAC-universal/lib/libomp.a lib-MAC/lib/libomp.a lib-MAC_ARM64/lib/libomp.a
xcodebuild -create-xcframework -library lib-MAC-universal/lib/libomp.a -headers lib-MAC/include \
  -output "frameworks/mac/OpenMP.xcframework"