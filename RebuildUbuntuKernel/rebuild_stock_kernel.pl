#!/usr/bin/perl

# rebuild_hwe.pl - rebuild Ubuntu HWE kernel with custom config
# Copyright (C) 2019 Luke Ross - luke@lukeross.name
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use strict;
use warnings;

######### START CONFIG ########
my $ARCH = "amd64";
my $NEW_FLAVOUR = "lukeross";
my $BASE_FLAVOUR = "generic";
my $CUSTOM_PATCH = "build.patch";
my $BUILD_TYPE = "master";
########## END CONFIG #########

use Cwd;
use Tie::File;

sub apply_patch($) {
	open(my $fh, "|-", "patch", "-p1") or die $!;
	print $fh shift();
	close $fh or die $!;
}

sub perl_i($&) {
	tie my @f, 'Tie::File', shift() or die;
	my $handler = shift;
	foreach(@f) {
		$handler->($_);
	}
	untie @f;
}

my $dir = shift || getcwd();

print "Building into $dir...\n";

my $prevdir = getcwd();
chdir($dir);

if ($CUSTOM_PATCH) {
	print "Applying custom patch file $CUSTOM_PATCH...\n";
	open(my $fh, "<", $CUSTOM_PATCH) or die $!;
	my $custom = join("", <$fh>);
	close $fh;
	apply_patch($custom);
}

print "Updating files...\n";
# Mash the relevant files
perl_i("debian.$BUILD_TYPE/rules.d/$ARCH.mk", sub { $_ = shift; m/flavours\s*=.*$BASE_FLAVOUR/ and $_ .= " $NEW_FLAVOUR"; });
perl_i("debian.$BUILD_TYPE/etc/getabis", sub { $_ = shift; m/getall\s+$ARCH\s+.*$BASE_FLAVOUR/ and $_ .= " $NEW_FLAVOUR"; });

# Create the vars file
open(my $in, "<", "debian.$BUILD_TYPE/control.d/vars.$BASE_FLAVOUR") or die $!;
open(my $out, ">", "debian.$BUILD_TYPE/control.d/vars.$NEW_FLAVOUR") or die $!;
while(<$in>) {
	if (m/^arch\s*=\s*".*?"$/) {
		print $out "arch=\"$ARCH\"\n";
	}
	elsif (m/^supported\s*=\s*".*?"$/) {
		print $out "supported=\"$NEW_FLAVOUR\"\n";
	}
	elsif (m/^target\s*=\s*".*?"$/) {
		print $out "target=\"$NEW_FLAVOUR is a patched variant of $BASE_FLAVOUR\"\n";
	}
	else {
		print $out $_;
	}
}
close($in);
close($out) or die $!;

# Create the config
open($in, "<", "debian.$BUILD_TYPE/config/$ARCH/config.flavour.$BASE_FLAVOUR") or die $!;
open($out, ">", "debian.$BUILD_TYPE/config/$ARCH/config.flavour.$NEW_FLAVOUR") or die $!;
while(<$in>) {
	print $out $_;
}
while(<DATA>) {
	print $out $_;
}
close($in);
close($out) or die $!;

print "Configuring build...\n";
system("chmod", "a+x", "debian/rules");
system("chmod", "a+x", glob("debian/scripts/*"));
system("chmod", "a+x", glob("debian/scripts/misc/*"));
system("fakeroot", "debian/rules", "clean");

print "Building binary-$NEW_FLAVOUR...\n";
system("fakeroot", "debian/rules", "binary-$NEW_FLAVOUR");

END { chdir($prevdir) if $prevdir; }

__DATA__
# CONFIG_RD_BZIP2 is not set
# CONFIG_SGETMASK_SYSCALL is not set
# CONFIG_SYSFS_SYSCALL is not set
# CONFIG_KALLSYMS_ALL is not set
# CONFIG_PC104 is not set
# CONFIG_SLUB_DEBUG is not set
# CONFIG_X86_MPPARSE is not set
# CONFIG_X86_EXTENDED_PLATFORM is not set
# CONFIG_HYPERVISOR_GUEST is not set
CONFIG_MATOM=y
# CONFIG_GENERIC_CPU is not set
# CONFIG_CPU_SUP_HYGON is not set
# CONFIG_CPU_SUP_CENTAUR is not set
# CONFIG_CPU_SUP_ZHAOXIN is not set
# CONFIG_GART_IOMMU is not set
# CONFIG_CALGARY_IOMMU is not set
# CONFIG_MAXSMP is not set
CONFIG_NR_CPUS=4
# CONFIG_X86_MCELOG_LEGACY is not set
# CONFIG_X86_16BIT is not set
# CONFIG_MICROCODE_OLD_INTERFACE is not set
# CONFIG_AMD_MEM_ENCRYPT is not set
# CONFIG_NUMA is not set
# CONFIG_X86_PMEM_LEGACY is not set
# CONFIG_HIBERNATION is not set
# CONFIG_PM_DEBUG is not set
CONFIG_PMIC_OPREGION=y
# CONFIG_CRC_PMIC_OPREGION is not set
CONFIG_XPOWER_PMIC_OPREGION=y
# CONFIG_BXT_WC_PMIC_OPREGION is not set
# CONFIG_CHT_WC_PMIC_OPREGION is not set
# CONFIG_CHT_DC_TI_PMIC_OPREGION is not set
# CONFIG_ISA_BUS is not set
# CONFIG_KPROBES is not set
# CONFIG_AIX_PARTITION is not set
# CONFIG_OSF_PARTITION is not set
# CONFIG_AMIGA_PARTITION is not set
# CONFIG_ATARI_PARTITION is not set
# CONFIG_MAC_PARTITION is not set
# CONFIG_MINIX_SUBPARTITION is not set
# CONFIG_SOLARIS_X86_PARTITION is not set
# CONFIG_UNIXWARE_DISKLABEL is not set
# CONFIG_LDM_PARTITION is not set
# CONFIG_SGI_PARTITION is not set
# CONFIG_ULTRIX_PARTITION is not set
# CONFIG_SUN_PARTITION is not set
# CONFIG_KARMA_PARTITION is not set
# CONFIG_SYSV68_PARTITION is not set
# CONFIG_CMDLINE_PARTITION is not set
# CONFIG_MEMORY_HOTPLUG is not set
# CONFIG_HAMRADIO is not set
# CONFIG_CAN is not set
# CONFIG_CAIF is not set
# CONFIG_NET_IFE is not set
# CONFIG_EISA is not set
# CONFIG_HOTPLUG_PCI is not set
# CONFIG_PCCARD is not set
# CONFIG_RAPIDIO is not set
# CONFIG_PARPORT is not set
# CONFIG_C2PORT is not set
# CONFIG_GENWQE is not set
# CONFIG_SATA_INIC162X is not set
# CONFIG_SATA_ACARD_AHCI is not set
# CONFIG_SATA_SIL24 is not set
# CONFIG_ATA_SFF is not set
# CONFIG_ARCNET is not set
# CONFIG_ATM_DRIVERS is not set
# CONFIG_ISDN is not set
CONFIG_SERIAL_8250=m
CONFIG_SERIAL_8250_PCI=m
# CONFIG_SERIAL_8250_RSA is not set
# CONFIG_SERIAL_8250_RT288X is not set
CONFIG_SERIAL_MAX310X=m
CONFIG_SERIAL_CORE=m
CONFIG_SERIAL_SCCNXP=m
CONFIG_SERIAL_MCTRL_GPIO=m
# CONFIG_AGP is not set
CONFIG_INTEL_GTT=m
# CONFIG_VGA_ARB is not set
# CONFIG_VGA_SWITCHEROO is not set
CONFIG_USB_OHCI_HCD=m
CONFIG_USB_OHCI_HCD_PCI=m
# CONFIG_USB_OHCI_HCD_SSB is not set
CONFIG_USB_OHCI_HCD_PLATFORM=m
# CONFIG_INFINIBAND is not set
# CONFIG_VIRTIO_PCI is not set
# CONFIG_VIRTIO_MMIO is not set
# CONFIG_MELLANOX_PLATFORM is not set
# CONFIG_MCB is not set
# CONFIG_FPGA is not set
# CONFIG_SIOX is not set
# CONFIG_SLIMBUS is not set
# CONFIG_INTERCONNECT is not set
# CONFIG_REISERFS_FS is not set
# CONFIG_JFS_FS is not set
# CONFIG_XFS_FS is not set
# CONFIG_GFS2_FS is not set
# CONFIG_OCFS2_FS is not set
# CONFIG_BTRFS_FS is not set
# CONFIG_NILFS2_FS is not set
# CONFIG_ORANGEFS_FS is not set
# CONFIG_ADFS_FS is not set
# CONFIG_AFFS_FS is not set
# CONFIG_BEFS_FS is not set
# CONFIG_BFS_FS is not set
# CONFIG_VXFS_FS is not set
# CONFIG_MINIX_FS is not set
# CONFIG_OMFS_FS is not set
# CONFIG_HPFS_FS is not set
# CONFIG_QNX4FS_FS is not set
# CONFIG_QNX6FS_FS is not set
# CONFIG_SYSV_FS is not set
# CONFIG_NFS_FS is not set
# CONFIG_NFSD is not set
# CONFIG_CEPH_FS is not set
# CONFIG_CODA_FS is not set
# CONFIG_AFS_FS is not set
# CONFIG_9P_FS is not set
# CONFIG_SECURITY_SELINUX is not set
# CONFIG_SECURITY_SMACK is not set
# CONFIG_SECURITY_TOMOYO is not set
# CONFIG_IMA is not set
# CONFIG_DYNAMIC_DEBUG is not set
# CONFIG_DEBUG_INFO is not set
# CONFIG_MAGIC_SYSRQ is not set
# CONFIG_DEBUG_MISC is not set
# CONFIG_SCHED_DEBUG is not set
# CONFIG_SCHEDSTATS is not set
# CONFIG_STACKTRACE is not set
# CONFIG_DEBUG_BUGVERBOSE is not set
# CONFIG_FTRACE is not set
# CONFIG_RUNTIME_TESTING_MENU is not set
# CONFIG_MEMTEST is not set
# CONFIG_SAMPLES is not set
# CONFIG_KGDB is not set
# CONFIG_X86_DEBUG_FPU is not set
# CONFIG_PUNIT_ATOM_DEBUG is not set
# CONFIG_UNWINDER_FRAME_POINTER is not set
CONFIG_UNWINDER_GUESS=y
