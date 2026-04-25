profile_rossio() {
	title="Rossio's Alpine"
	desc="A distrobution meant to be a nice nice jumping off point"
	profile_base
	profile_abbrev="rossio"
	hostname="rossio"
	image_ext="iso"
	arch="x86_64"
	output_format="iso"
	boot_addons="amd-ucode intel-ucode"
	initrd_ucode="/boot/amd-ucode.img /boot/intel-ucode.img"
	apks="$apks
		sfdisk
		dosfstools
		e2fsprogs
		grub-efi
		git
		openssh
		abuild
		alpine-conf
		syslinux
		xorriso
		squashfs-tools
		grub
		mtools
		bash
		nano
		cpupower
		python3
		py3-pip
		rustup
	"
	apkovl="genapkovl-rossio.sh"
}

