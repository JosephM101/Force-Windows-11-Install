# Force-Windows-11-Install

## Win11-TPM-RegistryBypass
This tool creates a modified Windows 11 installer ISO using an existing one, containing a registry hack that bypasses the setup-time compatibility checks, as well as an experimental patch that forces feature updates installed through Windows Update to install, despite incompatibilities.

**Looking for Windows 11 ISOs? Head over to [UUP Dump](https://uupdump.net/fetchupd.php?arch=amd64&ring=wif&build=latest) to download the latest Dev build of Windows 11, and create a bootable ISO. Need help? [You can start here.](https://github.com/JosephM101/Force-Windows-11-Install/blob/main/docs/UUPDump-Tutorial.md)**

**I am also developing a command-line interface tool for UUP Dump, so that you can download the latest update package for a given channel, and generate an installable ISO for use with this script. Using just a single command. Requires Python 3 and the `requests` module. You can check out the project [here](https://github.com/JosephM101/uupdump_cli#one-line-run).**

### Extras:
Looking for some Windows 11 hacks? I have some scripts uploaded on [another repository](https://github.com/JosephM101/Windows11_Mods).

------

***Please note that this tool does not allow Windows 11 to be installed on 32-bit (x86) platforms. Windows 11 is a 64-bit-only OS, and therefore will not work at all on older architectures such as 32-bit (x86).***

------

### How it works:
This workaround injects three keys into the registry of the Windows Setup environment in the boot.wim file in the Windows 11 ISO that cause the installer to skip TPM, Secure Boot, and memory checks (it seems to also skip CPU compatibility checks), allowing the user to install Windows 11 using the original installer. There are extra switches that can be passed for further patching, such as one that allows for forcing Windows Updates to skip compatibility checks; see [extra switches](#extra-switches) for more. A Windows 10 ISO is not required for this method.

### Why?
The installer for Windows 11 checks for both TPM and Secure Boot, and will not install on "unsupported" processors. However, many of the devices that don't have TPM, Secure Boot, or a compatible processor, are perfectly capable of running Windows 11.

## Usage
#### TIP: It's recommended to copy or move the Windows 11 ISO image to the same directory as the script to make things easy. If you have any issues with the script, please do not hesitate to open an issue.
#### NOTE: There is an issue with reading and writing files on external drives.
- In the repository directory, run `env.bat`. This will open up a new elevated PowerShell window in the repository.
- Type `.\Win11-TPM-RegBypass.ps1` in the PowerShell window, but don't hit Enter just yet.
- Follow up with `-Source`. This is where you're going to define the location of the Windows 11 ISO you want to use.
**TIP: If your Windows 11 ISO is not in the same directory as the script, you can locate the ISO with File Explorer, select it, then click "Copy path" in the File Explorer ribbon, or hold down Shift and right-click the file, the click "Copy as path" in the context menu. (Windows 10)** 

![image](https://user-images.githubusercontent.com/28277730/127249747-aee0fda7-bfaa-450b-b58b-1b3030ba0e56.png)

- Lastly, we need to define `-Destination`; the output ISO. You can make it short and sweet, and it doesn't need to be a full path.
- **Make sure all your file paths are surrounded with quotation marks.** Your final command should look something like this:

`.\Win11-TPM-RegBypass.ps1 -Source "22000.100.210719-2150.CO_RELEASE_SVC_PROD2_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO" -Destination "Win11-New.iso"`
![image](https://user-images.githubusercontent.com/28277730/127249867-bd20873a-8b5d-45fc-bb1d-942a12c8edcc.png)
- Now you can press Enter. The script should start running, and provided everything works correctly, you should now have a new bootable Windows 11 ISO image without the TPM or Secure Boot restrictions.

## Extra switches
**Note that any options that modify install.wim may result in the process taking longer. If the Windows image contains more than one edition, you will be asked to select one or more editions to modify. Any editions not selected will not be included in the final image.**

### Modifications
- `-InjectVMwareTools` - Injects the VMware tools installer into the install.wim image to run when the system boots for the first time. VMware needs to be installed, and the VMware Tools ISO needs to exist in its application folder. The process is modifying install.wim, and may take significantly longer.
- `-InjectPostPatch` - (EXPERIMENTAL) Injects a script into the install.wim image to run when the system boots for the first time. The modifications the script makes are expected to force upgrades done through Windows Update to ignore checking for TPM and CPU compatibility, allowing these upgrade to take place.
- `-PrepareUpgrade` - (EXPERIMENTAL) Modify the current system to bypass compatibility checks to allow in-place upgrades using the modified ISO. Can be called on its own (no other parameters), or otherwise run after generating the ISO.
    ***Note: If doing an in-place upgrade using `setup.exe` from a Windows 11 ISO image, do NOT disable the downloading of updates. This will result in a TPM error. The reason is currently unknown.***
- `-UndoPrepareUpgrade` - (EXPERIMENTAL) Undo the changes made by `-PrepareUpgrade`, if there are any. Can only be called by itself.

### Other switches
- `-VerboseMode` - Enable verbose output, which isn't much
- `-GuiSelectMode` - Shows a GUI for selecting multiple editions to modify as opposed to the CLI-based selection method
- `-HideTimestamps` - Disable printing the amount of time it took to complete a process

### Prepare Upgrade feature

***`.\Win11-TPM-RegBypass.ps1 -PrepareUpgrade` will only perform the modifications to the system.***

***`.\Win11-TPM-RegBypass.ps1 -Source [source] -Destination [destination] <Other parameters> -PrepareUpgrade` will perform modifications after the ISO is generated.***

--------

# Win11-ImageBuilder (Obsolete)
Win11-ImageBuilder has been marked obsolete, and is no longer maintained. For the documentation on the tool, [navigate here](https://github.com/JosephM101/Force-Windows-11-Install/blob/main/docs/Documentation%20for%20Win11-ImageBuilder.md).

--------

## Background
Following the announcement of Windows 11, many users were rather discouraged to discover the new TPM, CPU and Secure Boot restrictions imposed by Microsoft for Windows 11 in an attempt to block devices lacking these features from installing and running it. This has left a lot of otherwise excited users in the dark, with virtually no way to upgrade without buying a new machine sporting a CPU newer than 2018, as well as the aforementioned features. However, it's been proven time and time again that on many devices considered unsupported, the Windows 11 experience was actually not horrible, and in some cases, better than that of Windows 10. Microsoft claims the reasons for enforcing these restrictions have to do with both compatibility and security. They claimed that many of the older devices they tested Windows 11 on encountered Blue Screen of Death errors. However, many people running Windows 11 on their so-called incompatible devices didn’t report any huge issues at the time of writing. While it’s not exactly recommended to run Windows 11 on an incompatible device (especially if it’s a daily driver), it certainly is possible to bypass Microsoft’s restrictions and allow installing or upgrading to Windows 11.
