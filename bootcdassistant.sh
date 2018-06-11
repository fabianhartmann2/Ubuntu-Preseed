#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

dumpiso() {
	iso=$1
	randomfolder=$(echo $RANDOM)
	mkdir -p /mnt/$randomfolder
	mount -o loop $iso /mnt/$randomfolder
	mkdir -p /opt/$randomfolder
	cp -rT /mnt/$randomfolder /opt/$randomfolder
	chmod -R 777 /opt/$randomfolder
	echo Files have been placet into: /opt/$randomfolder/
}

createiso() {
	src=$1
	name=$2
	dest=$3
  cd $dest
	sudo mkisofs -D -r -V "$name" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $dest $src
}

modify() {
  dumpdirectory=$1
  cp ./autoinstall.seed $dumpdirectory/autoinstall.seed
  cd $dumpdirectory
  sed -i 's/\(prompt \).*/\110/' $dumpdirectory/isolinux/isolinux.cfg
  sed -i 's/\(timeout \).*/\110/' $dumpdirectory/isolinux/isolinux.cfg
  sed -i 's/\(default \).*/\1autoinstall/' $dumpdirectory/isolinux/txt.cfg
  sed -i '/default*/a append  file=/cdrom/autoinstall.seed auto=true priority=critical initrd=/install/initrd.gz ramdisk_size=16384 root=/dev/ram rw quiet --' $dumpdirectory/isolinux/txt.cfg
  sed -i '/default*/a kernel /install/vmlinuz' $dumpdirectory/isolinux/txt.cfg
  sed -i '/default*/a menu label ^Autoinstall' $dumpdirectory/isolinux/txt.cfg
  sed -i '/default*/a label autoinstall' $dumpdirectory/isolinux/txt.cfg
}
case $1 in
	dump )
		dumpiso $2
		;;
	create )
		createiso $2 $3 $4
		;;
  modify )
    modify $2
    ;;
  setup )
    apt-get update
    apt-get install mkisofs
    ;;
	*)
		echo "################################################"
		echo "# NOTHING SPECIFIED - WHAT DO YOU WANT TO DO?  #"
		echo "################################################"
		echo "* Specify what you want to do: dump | create | modify *"
		echo "* dump {Path to ISO}                           *"
    echo "* modify {Path to dumped folder}               *"
		echo "* create {Path to dumped folder} {Name for CD} {destination folder} *"
    echo "* You need to place a kickstart File called    *"
    echo "* autoinstall.seed into the working directory  *"
		echo "************************************************"
		;;
esac
