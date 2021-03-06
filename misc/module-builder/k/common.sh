# set variables to be used by all module builders
# expects PACKAGE and VERSION to be set

GROUP='fun3d_users'

MPT_VERSION='2.17r14'
INTEL_VERSION='2018.0.033'
PARMETIS_VERSION='4.0.3'
ZOLTAN_VERSION='3.82'
ESP_VERSION='113.1'

INTEL_MODULE="intel_${INTEL_VERSION}"
MPT_MODULE="mpt-${MPT_VERSION}"

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -gt 0 ] && [ $1 == "jenkinsbuild" ] ; then
  echo "install modules in local directory"
  PREFIX="$script_dir/_modules_jenkinsbuild/${GROUP}"
  mkdir -p $PREFIX/modules
  mkdir -p $PREFIX/modulefiles
else
  PREFIX="/u/shared/${USER}/${GROUP}"     # where everything is anchored
fi


MODULE_ROOT="${PREFIX}/modules"         # where the built artifacts reside
MODFILE_ROOT="${PREFIX}/modulefiles"    # where the modulefiles reside

# artifacts
MODULE_BASE="${MODULE_ROOT}/${PACKAGE}"
MODULE_DEST="${MODULE_BASE}/${VERSION}"

# module system file
MODFILE_BASE="${MODFILE_ROOT}/${PACKAGE}"
MODFILE_DEST="${MODFILE_BASE}/${VERSION}"

. /usr/local/pkgs/modules/init/bash
module use ${MODFILE_ROOT}

skipbuild(){
   if [ -e $2 ] ; then
       echo "$2 exists."
       echo "===Exit $1 build.=="
       exit 
   fi
}
