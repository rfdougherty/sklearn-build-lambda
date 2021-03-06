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
    pip install --no-binary pandas pandas==0.22.0
    pip install sklearn
    test -f /outputs/requirements.txt && pip install -r /outputs/requirements.txt
}

strip_virtualenv () {
    echo "venv original size $(du -sh $VIRTUAL_ENV | cut -f1)"
    find $VIRTUAL_ENV/lib64/python3.6/site-packages/ -name "*.so" | xargs strip
    # Remove unit tests
    find $VIRTUAL_ENV/lib64/python3.6/site-packages/ -type d -name tests -prune -exec rm -rf {} \;
    echo "venv stripped size $(du -sh $VIRTUAL_ENV | cut -f1)"

    pushd $VIRTUAL_ENV/lib/python3.6/site-packages/ && zip -yrq9 /tmp/partial-venv.zip * ; popd
    pushd $VIRTUAL_ENV/lib64/python3.6/site-packages/ && zip -yr9 --out /outputs/venv.zip -q /tmp/partial-venv.zip * ; popd
    echo "site-packages compressed size $(du -sh /outputs/venv.zip | cut -f1)"

    #pushd $VIRTUAL_ENV && zip -yrq9 /outputs/full-venv.zip * ; popd
    #echo "venv compressed size $(du -sh /outputs/full-venv.zip | cut -f1)"
}

shared_libs () {
    libdir="$VIRTUAL_ENV/lib64/python3.6/site-packages/lib/"
    mkdir -p $libdir || true
    cp -L /usr/lib64/atlas/libatlas.so.3 $libdir
    cp -L /usr/lib64/atlas/libptcblas.so $libdir
    cp -L /usr/lib64/libquadmath.so.0 $libdir
    cp -L /usr/lib64/libgfortran.so.3 $libdir
    cp -L /usr/lib64/atlas/libptf77blas.so.3.0 $libdir
    cp -L /usr/lib64/atlas/libf77blas.so.3 $libdir
    cp -L /usr/lib64/atlas/libcblas.so.3 $libdir
    cp -L /usr/lib64/atlas/liblapack.so.3 $libdir
    cp -L /usr/lib64/libopenblas.so.0 $libdir
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
