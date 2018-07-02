Installing OpenMediaVault (OMV) for UEFI-only device ( WD DX4000 ). 

What we have:
 - VirtualBox
 - OMV installation iso image ( https://www.openmediavault.org/download.html )
 - 4G USB flash drive attached as /dev/sdX device.
 - existing Arch ( x64 UEFI installed system. Refer to this how-to https://gist.github.com/elerch/678941eb670324ffc3f261eabba81310 )

Zeroing the targed USB flash drive.
 # dd  status=progress if=/dev/zero of=/dev/sdX

Make "raw" Virtual disk.
 # VBoxManage internalcommands createrawvmdk -filename "</path/to/file>.vmdk" -rawdisk /dev/sdX

Create VM with OMV iso and your disk attached. ( 2G RAM, CPU -- up to you )
Start VM and install OMV as usual.
Stop VM.

Resize "root" partition on the USB flash ( /dev/sdX1 ) with your favorit tool
( gparted ) to free about 200M space. 
Create new partition with gdisk on the free space to hold EFI system.
Refer to 1) and 2) at https://askubuntu.com/questions/84501/how-can-i-change-convert-a-ubuntu-mbr-drive-to-a-gpt-and-make-ubuntu-boot-from

Make vfat filesystem on newly created partition.
  # mkfs.vfat /dev/sdX2

Now start to transfer boot files from Arch to OMV:

Mount Arch ELF partition:
  # mount  /dev/sd<Arch>1 /mnt/arch/
Mount OMV ELF partitions:
  # mount /dev/sdX2/ /mnt/omv/
Mount OMV root partition:
  # mount /dev/sdX1/ /mnt/omvroot/

Copy EFI files:
  # cp -r /mnt/arch/* /mnt/omv/
Copy kernel and initrd files from OMV boot:
  # cp /mnt/omvroot/boot/* /mnt/omv/

Run blkid and remember PARTUUID for omvroot filesystem.

Edit /mnt/omv/syslinux.cfg to reflect you new kernel and image files and put
proper PARTUUID for root filesystem:
   APPEND root=PARTUUID=????????-????-????-????-???????????? rw

unmount /mnt/arch/, /mnt/omv/ and /mnt/omvroot/

Now you should be able to boot in VirtualBox in EFI mode (check EFI boot at
VM system tab).

For some reason networking service does not start correctly on DX4000, so
replace it with dhcpcd:

  # apt-get install dhcpcd5
  # systemctl disable networking
  # mv /etc/network /etc/network.old
  # systemctl enable dhcpcd
  # systemctl start dhcpcd

Here you are ready to plug your USB stick to DX4000, wait some time,
find IP using nmap and login to the system using ssh as a root.

But it will be better to make some additional changes:

Tweak the /etc/fstab:
- add noatime,nodiratime optins to root partition
- comment swap partition to disable swap

Install lcdproc for lcd support:
  # apt-get install lcdproc
  # apt-get  install lcdproc-extra-drivers
Edit /etc/LCDd.conf file and add following in [server] section:
  Driver=hd44780
  Goodbye="Goodbye!"
  ServerScreen=blank
Fix drivers path:
  DriverPath=/usr/lib/x86_64-linux-gnu/lcdproc/
Add settings for hd44780:
 [hd44780]
 ConnectionType=winamp
 Size=16x2
Enable and start LCDd
  # systemctl enable LCDd
  # systemctl start LCDd

Add lcdshow.pl to crontab:
* * * * * /root/lcdshow.pl

  
Configure OMV:
  Login to web interface as user admin password: openmediavault
Get OPVExtras plugins from: http://omv-extras.org/joomla/index.php/guides
Select Plugins on the web interface, upload and install extras package.
Check for new plugins and install minidlna server.

Good idea is to install flashmemory plugin to minimize writes to USB flash.


Some useful mdadmin commands. 
Reassembling RAID:
# umount /dev/md127
# mdadm --stop /dev/md127
# mdadm --assemble --force --verbose /dev/md127 /dev/sd[acde]

Remove disk from array:
# mdadm --remove /dev/md127 /dev/sde

Add disk to array:
# mdadm --add /dev/md127 /dev/sde

