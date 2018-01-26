#!/bin/bash
if [ -z "$1" ]; then
  cat <<EOF
usage:
  ./make_spec.sh PACKAGENAME [BRANCH]
EOF
  exit 1
fi

packagename=$1
branch=${2:-master}
safe_branch=${branch//\//-}

bundle version 2>/dev/null
if [ $? != 0 ];then
  echo "bundler is not installed. Please install it."
  exit -1
fi
cd $(dirname $0)

if [ $TRAVIS_BRANCH ];then
  branch=$TRAVIS_BRANCH
  safe_branch=${branch//\//-}
fi
if [ $TRAVIS_COMMIT ];then
  commit=$TRAVIS_COMMIT
  revision="travis"
else
  revision=$(git rev-list HEAD | wc -l)
  commit=$(git rev-parse HEAD)
fi
version=$(sed s/-/~/g ../../VERSION)
version="$version+git_r$revision\_$commit"
date=$(date --rfc-2822)
year=$(date +%Y)

# clean
[ ! -d build ] || rm -rf build

additional_native_build_requirements() {
  if [ $1 == "nokogiri" ];then
    echo "BuildRequires: libxml2-devel libxslt-devel\n"
  elif [ $1 == "mysql2" ];then
    # if Tumbleweed
    echo "%if 0%{?suse_version} > 1500\nBuildRequires: libmariadb-devel\nRequires: mariadb-client\n%else\nBuildRequires: libmysqlclient-devel < 10.1\nRequires: libmysqlclient18 < 10.1\n%endif\nRecommends: mariadb\n"
  elif [ $1 == "ethon" ];then
    echo "BuildRequires: libcurl-devel\nRequires: libcurl4\n"
  elif [ $1 == "ffi" ];then
    echo "BuildRequires: libffi-devel\n"
  fi
}

mkdir -p build/$packagename-$safe_branch
cp -v ../../Gemfile* build/$packagename-$safe_branch
cp -v patches/*.patch build/$packagename-$safe_branch

pushd build/$packagename-$safe_branch/
  echo "apply patches if needed"
  if ls *.patch >/dev/null 2>&1 ;then
      for p in *.patch;do
          number=$(echo "$p" | cut -d"_" -f1)
          patchsources="$patchsources\nPatch$number: $p\n"
          patchexecs="$patchexecs\n%patch$number -p1\n"
          # skip applying rpm patches
          [[ $p =~ .rpm\.patch$ ]] && continue
          echo "applying patch $p"
          patch -p1 < $p || exit -1
      done
  fi
  echo "generate the Gemfile.lock for packaging"
  export BUNDLE_GEMFILE=$PWD/Gemfile
  cp Gemfile.lock Gemfile.lock.orig
  bundle config build.nokogiri --use-system-libraries
  bundle install --retry=3 --no-deployment --path .bundler --without development test
  grep "git-review" Gemfile.lock
  if [ $? == 0 ];then
    echo "DEBUG: ohoh something went wrong and you have devel packages"
    diff Gemfile.lock Gemfile.lock.orig
    exit -1
  fi
  extracted_requires=$(ruby -rbundler -e 'Bundler.definition.specs_for([:default, :production, :assets]).any? { |s| puts "BuildRequires:  %{rubygem #{s.name} = #{s.version}}" }')
  echo "get requirements from Gemfile.lock"
  IFS=$'\n' # do not split on spaces
  build_requires=""
  for build_require in $extracted_requires; do
    gem_name=$(echo $build_require | cut -d" " -f4)
    build_requires="$build_requires\n$build_require"
    build_requires="$build_requires\n$(additional_native_build_requirements $gem_name)"
  done
popd

echo "create ${packagename}.spec based on ${packagename}.spec.in"
cp ${packagename}.spec.in ${packagename}.spec
sed -e "s/__BRANCH__/$safe_branch/g" -i ${packagename}.spec
sed -e "s/__RUBYGEMS_BUILD_REQUIRES__/$build_requires/g" -i ${packagename}.spec
sed -e "s/__DATE__/$date/g" -i ${packagename}.spec
sed -e "s/__COMMIT__/$commit/g" -i ${packagename}.spec
sed -e "s/__VERSION__/$version/g" -i ${packagename}.spec
sed -e "s/__CURRENT_YEAR__/$year/g" -i ${packagename}.spec
sed -e "s/__PATCHSOURCES__/$patchsources/g" -i ${packagename}.spec
sed -e "s/__PATCHEXECS__/$patchexecs/g" -i ${packagename}.spec

if [ -f ${packagename}.spec ];then
  echo "Done!"
  exit 0
else
  echo "A problem occured creating the spec file."
  exit -1
fi
