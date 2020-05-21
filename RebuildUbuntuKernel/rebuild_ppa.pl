#!/usr/bin/perl

# rebuild_ppa.pl - rebuild Ubuntu kernel-ppa with custom config
# Copyright (C) 2018 Luke Ross - luke@lukeross.name
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
my $ARCH = "amd64";           # target system architecture
my $NEW_FLAVOUR = "lr";       # what you want your new flavour to be named
my $BASE_FLAVOUR = "generic"; # which flavour to base your new flavour on
my $CUSTOM_PATCH = undef;     # absolute filename of a custom patch to patch
                              # the kernel checkout with, or undef for no patch
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

my $v = shift or die "usage: $0 version directory";
my $dir = shift or die "usage: $0 version directory";

print "Building into $dir...\n";

print "Fetching http://kernel.ubuntu.com/~kernel-ppa/mainline/v$v/SOURCES...\n";
my $build_steps = get("http://kernel.ubuntu.com/~kernel-ppa/mainline/v$v/SOURCES") or die $!;

# Get the PPA build steps
my @steps = split /\n/, $build_steps;
my @git_steps = split /\s+/, shift(@steps);

# Check out the version
if (not -e "$dir/.git") {
	print "Git-cloning ", $git_steps[0], " ", $git_steps[-1], "...\n";
	die "Wrong $dir/.git";
	system("git", "clone", $git_steps[0], $dir);
}

my $prevdir = getcwd();
chdir($dir);

system("git", "checkout", $git_steps[-1]);

# Add the patches
foreach my $step (@steps) {
	print "Patching $step...\n";
	die "Invalid filename: $step" if $step =~ m#/#;
	apply_patch(get("http://kernel.ubuntu.com/~kernel-ppa/mainline/v$v/$step") or die $!);
}

if ($CUSTOM_PATCH) {
	print "Applying custom patch file $CUSTOM_PATCH...\n";
	open(my $fh, "<", $CUSTOM_PATCH) or die $!;
	my $custom = join("", <$fh>);
	close $fh;
	apply_patch($custom);
}

print "Updating files...\n";
# Mash the relevant files
perl_i("debian.master/rules.d/$ARCH.mk", sub { $_ = shift; m/flavours\s*=.*$BASE_FLAVOUR/ and $_ .= " $NEW_FLAVOUR"; });
perl_i("debian.master/etc/getabis", sub { $_ = shift; m/getall\s+$ARCH\s+.*$BASE_FLAVOUR/ and $_ .= " $NEW_FLAVOUR"; });

# Create the vars file
open(my $in, "<", "debian.master/control.d/vars.$BASE_FLAVOUR") or die $!;
open(my $out, ">", "debian.master/control.d/vars.$NEW_FLAVOUR") or die $!;
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
open($in, "<", "debian.master/config/$ARCH/config.flavour.$BASE_FLAVOUR") or die $!;
open($out, ">", "debian.master/config/$ARCH/config.flavour.$NEW_FLAVOUR") or die $!;
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
# CONFIG_CPU_SUP_CENTAUR is not set
# CONFIG_GART_IOMMU is not set
# CONFIG_CALGARY_IOMMU is not set
# CONFIG_MAXSMP is not set
CONFIG_NR_CPUS_RANGE_BEGIN=2
CONFIG_NR_CPUS_RANGE_END=512
CONFIG_NR_CPUS_DEFAULT=64
CONFIG_NR_CPUS=4
# CONFIG_SCHED_SMT is not set
# CONFIG_NUMA is not set
# CONFIG_HIBERNATION is not set
CONFIG_PMIC_OPREGION=y
# CONFIG_CRC_PMIC_OPREGION is not set
CONFIG_XPOWER_PMIC_OPREGION=y
# CONFIG_BXT_WC_PMIC_OPREGION is not set
# CONFIG_CHT_WC_PMIC_OPREGION is not set
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
CONFIG_XXHASH=m
CONFIG_ZSTD_DECOMPRESS=m
# CONFIG_EARLY_PRINTK_DBGP is not set
