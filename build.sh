#!/bin/bash
set -ex

yum update -y
yum install -y \
    atlas-devel \
    atlas-sse3-devel \
    openblas-devel \
    gcc \
    gcc-c++ \
    lapack-devel \
    python36-devel \
    python36-virtualenv \
    findutils \
    zip \
    git

do_pip () {
    pip install --upgrade pip wheel
    pip install --no-binary numpy numpy
    pip install --no-binary scipy scipy
    pip install sklearn
    test -f /outputs/requirements.txt && pip install -r /outputs/requirements.txt
    # Remove unit tests
    rm -rf */tests/
}

strip_virtualenv () {
    echo "venv original size $(du -sh $VIRTUAL_ENV | cut -f1)"
    find $VIRTUAL_ENV/lib64/python3.6/site-packages/ -name "*.so" | xargs strip
    echo "venv stripped size $(du -sh $VIRTUAL_ENV | cut -f1)"

    pushd $VIRTUAL_ENV/lib/python3.6/site-packages/ && zip --symlinks -r -9 -q /tmp/partial-venv.zip * ; popd
    pushd $VIRTUAL_ENV/lib64/python3.6/site-packages/ && zip --symlinks -r -9 --out /outputs/venv.zip -q /tmp/partial-venv.zip * ; popd
    echo "site-packages compressed size $(du -sh /outputs/venv.zip | cut -f1)"

    pushd $VIRTUAL_ENV && zip --symlinks -r -q /outputs/full-venv.zip * ; popd
    echo "venv compressed size $(du -sh /outputs/full-venv.zip | cut -f1)"
}

shared_libs () {
    libdir="$VIRTUAL_ENV/lib64/python3.6/site-packages/lib/"
    mkdir -p $VIRTUAL_ENV/lib64/python3.6/site-packages/lib || true
    cp --preserve=links /usr/lib64/atlas/*.so* $libdir
    cp --preserve=links /usr/lib64/libopenblas.so.0 $libdir
    cp --preserve=links /usr/lib64/libquadmath.so.0 $libdir
    cp --preserve=links /usr/lib64/libgfortran.so.3 $libdir
}

main () {
    /usr/bin/virtualenv-3.6 \
        --python /usr/bin/python3.6 /sklearn_build \
        --always-copy \
        --no-site-packages
    source /sklearn_build/bin/activate

    do_pip

    shared_libs

    strip_virtualenv
}
main
