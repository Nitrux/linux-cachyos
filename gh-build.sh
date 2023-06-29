#! /bin/sh


# Prepare the build environment.
# We also need gem to be able to install fpm.
pacman -Syu --noconfirm \
    base-devel \
    squashfs-tools \
    rubygems

gem install fpm

# If there are Debian control files, we want to copy them to the
# new packages, so we save their location.
test -f control-headers \
    && ctrl_h=$PWD/control-headers

test -f control-kernel \
    && ctrl_k=$PWD/control-kernel


# Download sources and build the package.
git clone --depth=1 https://github.com/CachyOS/linux-cachyos

cd linux-cachyos/linux-cachyos-bore/
makepkg

mkdir pkgs
mv *.pkg.* pkgs/
cd pkgs


# Convert the packages to Debian format.
for p in *; do
    # Name the new package in a Debian fashion.
    deb=${p%-x86_64*}_amd64.deb

    case $p in
        # This repackages the kernel headers.
        ( *-headers-* )
            fpm -t deb \
                -s pacman \
                -p $deb \
                ${ctrl_h:+--deb-custom-control $ctrl_h} \
                $p;;

        # This repackages the kernel and modules.
        ( * )
            fpm -t deb \
                -s pacman \
                -p $deb \
                ${ctrl_k:+--deb-custom-control $ctrl_k} \
                $p;;
    esac
done
