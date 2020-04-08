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
my $NEW_FLAVOUR = "lr";
my $BASE_FLAVOUR = "generic";
my $CUSTOM_PATCH = "/home/lukeross/enable_additional_cpu_optimizations_for_gcc_v8.1+_kernel_v4.13+.patch";
my $BUILD_TYPE = "hwe";
########## END CONFIG #########

use Cwd;
use LWP::Simple qw(get);
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
# CONFIG_PC104 is not set
# CONFIG_X86_EXTENDED_PLATFORM is not set
# CONFIG_HYPERVISOR_GUEST is not set
# CONFIG_MK8SSE3 is not set
# CONFIG_MK10 is not set
# CONFIG_MBARCELONA is not set
# CONFIG_MBOBCAT is not set
# CONFIG_MJAGUAR is not set
# CONFIG_MBULLDOZER is not set
# CONFIG_MPILEDRIVER is not set
# CONFIG_MSTEAMROLLER is not set
# CONFIG_MEXCAVATOR is not set
CONFIG_MZEN=y
# CONFIG_MCORE2 is not set
# CONFIG_MNEHALEM is not set
# CONFIG_MWESTMERE is not set
# CONFIG_MSILVERMONT is not set
# CONFIG_MSANDYBRIDGE is not set
# CONFIG_MIVYBRIDGE is not set
# CONFIG_MHASWELL is not set
# CONFIG_MBROADWELL is not set
# CONFIG_MSKYLAKE is not set
# CONFIG_MSKYLAKEX is not set
# CONFIG_MCANNONLAKE is not set
# CONFIG_MICELAKE is not set
# CONFIG_GENERIC_CPU is not set
# CONFIG_MNATIVE is not set
# CONFIG_CPU_SUP_INTEL is not set
# CONFIG_CPU_SUP_HYGON is not set
# CONFIG_CPU_SUP_CENTAUR is not set
# CONFIG_GART_IOMMU is not set
# CONFIG_CALGARY_IOMMU is not set
# CONFIG_MAXSMP is not set
CONFIG_NR_CPUS_RANGE_BEGIN=2
CONFIG_NR_CPUS_RANGE_END=512
CONFIG_NR_CPUS_DEFAULT=64
CONFIG_NR_CPUS=4
# CONFIG_X86_MCE_INTEL is not set
# CONFIG_NUMA is not set
# CONFIG_HIBERNATION is not set
CONFIG_PMIC_OPREGION=y
CONFIG_XPOWER_PMIC_OPREGION=y
# CONFIG_BXT_WC_PMIC_OPREGION is not set
# CONFIG_CHT_DC_TI_PMIC_OPREGION is not set
CONFIG_X86_POWERNOW_K8=m
CONFIG_X86_SPEEDSTEP_CENTRINO=m
CONFIG_EDD=m
# CONFIG_AIX_PARTITION is not set
# CONFIG_OSF_PARTITION is not set
# CONFIG_AMIGA_PARTITION is not set
# CONFIG_ATARI_PARTITION is not set
# CONFIG_SGI_PARTITION is not set
# CONFIG_ULTRIX_PARTITION is not set
# CONFIG_SUN_PARTITION is not set
# CONFIG_KARMA_PARTITION is not set
# CONFIG_MEMORY_HOTPLUG is not set
# CONFIG_MEMORY_FAILURE is not set
# CONFIG_DCB is not set
CONFIG_BLK_DEV_LOOP=m
CONFIG_ATA_PIIX=m
CONFIG_ATA_GENERIC=m
CONFIG_BLK_DEV_MD=m
CONFIG_BLK_DEV_DM=m
CONFIG_TUN=m
CONFIG_MDIO_DEVICE=m
CONFIG_MDIO_BUS=m
CONFIG_PHYLIB=m
CONFIG_FIXED_PHY=m
CONFIG_PPP=m
CONFIG_SLHC=m
CONFIG_KEYBOARD_ATKBD=m
CONFIG_SERIO_I8042=m
CONFIG_SERIO_LIBPS2=m
CONFIG_SERIAL_8250=m
CONFIG_SERIAL_8250_PCI=m
# CONFIG_AGP is not set
CONFIG_INTEL_GTT=m
# CONFIG_VGA_SWITCHEROO is not set
CONFIG_USB_EHCI_HCD=m
CONFIG_USB_EHCI_PCI=m
CONFIG_USB_EHCI_HCD_PLATFORM=m
CONFIG_USB_OHCI_HCD=m
CONFIG_USB_OHCI_HCD_PCI=m
# CONFIG_USB_OHCI_HCD_SSB is not set
CONFIG_USB_OHCI_HCD_PLATFORM=m
CONFIG_USB_UHCI_HCD=m
CONFIG_SQUASHFS=m
# CONFIG_SECURITY_SELINUX is not set
# CONFIG_SECURITY_SMACK is not set
# CONFIG_SECURITY_TOMOYO is not set
# CONFIG_IMA is not set
# CONFIG_EVM is not set
CONFIG_ZSTD_DECOMPRESS=m
# CONFIG_EARLY_PRINTK_DBGP is not set
# CONFIG_RD_BZIP2 is not set
# CONFIG_RD_LZMA is not set
# CONFIG_KALLSYMS_ALL is not set
# CONFIG_X86_MPPARSE is not set
# CONFIG_CPU_SUP_HYGON is not set
# CONFIG_X86_INTEL_MPX is not set
# CONFIG_SFI is not set
# CONFIG_HOTPLUG_PCI_CPCI is not set
# CONFIG_HOTPLUG_PCI_SHPC is not set
# CONFIG_PCIE_DW_PLAT_HOST is not set
# CONFIG_PCI_ENDPOINT is not set
# CONFIG_RAPIDIO is not set
# CONFIG_SYSV68_PARTITION is not set
# CONFIG_SRAM is not set
# CONFIG_MEGARAID_NEWGEN is not set
# CONFIG_FDDI is not set
CONFIG_RANDOM_TRUST_CPU=y
CONFIG_EDAC=m
# CONFIG_UNISYSSPAR is not set
# CONFIG_CRC_PMIC_OPREGION is not set
# CONFIG_CHT_WC_PMIC_OPREGION is not set
# CONFIG_X86_CPU_RESCTRL is not set
# CONFIG_NCSI_OEM_CMD_GET_MAC is not set
# CONFIG_EISA is not set
# CONFIG_PCI_MESON is not set
CONFIG_REGMAP_I2C=m
CONFIG_TOUCHSCREEN_ELAN=m
CONFIG_I2C=m
CONFIG_I2C_CHARDEV=m
CONFIG_I2C_DESIGNWARE_CORE=m
CONFIG_I2C_DESIGNWARE_PLATFORM=m
CONFIG_MFD_DA9063=m
CONFIG_MFD_MAX14577=m
CONFIG_MFD_MAX77693=m
CONFIG_MFD_TPS65912_I2C=m
CONFIG_DRM_PANEL_ORIENTATION_QUIRKS=m
CONFIG_FB=m
CONFIG_FB_CFB_FILLRECT=m
CONFIG_FB_CFB_COPYAREA=m
CONFIG_FB_CFB_IMAGEBLIT=m
CONFIG_RTC_I2C_AND_SPI=m
# CONFIG_ANDROID is not set
# CONFIG_FONTS is not set
# CONFIG_RUNTIME_TESTING_MENU is not set
# CONFIG_SAMPLES is not set
# CONFIG_EARLY_PRINTK_USB_XDBC is not set
