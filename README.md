# Force-Windows-11-Install

## Background

**Looking for Windows 11 ISOs? Head over to [UUP Dump](https://uupdump.net/fetchupd.php?arch=amd64&ring=wif&build=latest) to download the latest Dev build of Windows 11, and create a bootable ISO. Need help? [You can start here.](https://github.com/JosephM101/Force-Windows-11-Install/blob/main/docs/UUPDump-Tutorial.md)**

### Why?
The installer for Windows 11 checks for both TPM and Secure Boot, and will not install on "unsupported" processors. However, many of the devices that don't have TPM, Secure Boot, or a compatible processor, are perfectly capable of running Windows 11. 

### Things to note
This workaround may be borked by a future Windows update where the requirements are baked into the operating system itself, in which case it just wouldn't work. Also note that upgrades to newer versions of Windows 11 through Windows Update will not install.

# Win11-TPM-RegistryBypass (Recommended)
### How it works:
This workaround injects three keys into the registry of the Windows Setup environment in the boot.wim file in the Windows 11 ISO that cause the installer to skip TPM, Secure Boot, and memory checks (it seems to also skip CPU compatibility checks), allowing the user to install Windows 11 using the original installer on what is considered incompatible hardware. A Windows 10 ISO is not required for this method.

## Usage
#### NOTE: This tutorial assumes that the Windows 11 ISO you want to use is in the directory of the repository.
- In the repository directory, run `env.bat`. This will open up a new elevated PowerShell window in the repository.
- Type `.\Win11-TPM-RegBypass.ps1` in the PowerShell window, but don't hit Enter just yet.
- Follow up with `-Source`. This is where you're going to define the location of the Windows 11 ISO you want to use. So, copy the full filename of the ISO image you copied to the repository directory, and paste it in the PowerShell window.
**TIP: If your Windows 11 ISO is not in the same directory as the script, you can locate the ISO with File Explorer, select it, then click "Copy path" in the File Explorer ribbon.** 

![image](https://user-images.githubusercontent.com/28277730/127249747-aee0fda7-bfaa-450b-b58b-1b3030ba0e56.png)

- Lastly, we need to define `-Destination`; the output ISO. You can make it short and sweet, and it doesn't need to be a full path.
- **Make sure all your parameters are surrounded with quotation marks.** Your final command should look something like this:

`.\Win11-TPM-RegBypass.ps1 -Source "22000.100.210719-2150.CO_RELEASE_SVC_PROD2_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO" -Destination "Win11-New.iso"`
![image](https://user-images.githubusercontent.com/28277730/127249867-bd20873a-8b5d-45fc-bb1d-942a12c8edcc.png)
- Now you can hit Enter. The script should start running, and provided everything works correctly, you should now have a new bootable Windows 11 ISO image without the TPM or Secure Boot restrictions.

## Extra switches
**Note that any options that modify install.wim may result in the process taking longer.
- `-InjectVMwareTools` - Injects the VMware tools installer into the install.wim image to run when the system boots for the first time. VMware needs to be installed, and the VMware Tools ISO needs to exist in its application folder. The process is modifying install.wim, and may take significantly longer.

- `-InjectPostPatch` - (EXPERIMENTAL) Injects a script into the install.wim image to run when the system boots for the first time. The modifications the script makes are expected to force upgrades done through Windows Update to ignore checking for TPM and CPU compatibility, allowing these upgrade to take place.

--------

# Win11-ImageBuilder (Old)
This tool extracts the contents of an existing Windows 10 iso to a scratch directory using `7z`. It then extracts the installation contents (install.wim) from a Windows 11 iso, deletes the install.wim file from the Windows 10 installer, and replaces it with the install.wim file from the Windows 11 iso. Finally, it uses `oscdimg` (pulled from Windows Deployment Tools) to create a new iso from the Windows 10 installer, which now contains the Windows 11 installation contents.

In other words, it creates a "hybrid" ISO image that houses the Windows 11 install files in a Windows 10 installer image to bypass the TPM and Secure Boot install-time requirements. This workaround will allow a user to install Windows 11 on incompatible devices by using the Windows 10 installer, which does not have the same restrictions. **Requires a Windows 10 ISO.**

## Usage
#### If you're looking to create an image that contains an .ESD instead of a .WIM, use the instructions in [ESD Conversion](#esd-conversion) as well. Note that the source installer (the Windows 10 image) has to already have an ESD file, otherwise the installer won't have been configured for ESD installations, and therefore will not recognize the file.
All the tools needed to run the script properly (`7z` and `oscdimg`) are included in this repo. Just clone it, extract it, and follow the instructions below.
NOTE: You will need to allow executing scripts in PowerShell by running `Set-ExecutionPolicy Unrestricted` in an elevated PowerShell window.
It is recommended that you have at least 10-15 GB of disk space free for temporary files.

- Right-click the script (Win11-ImageBuilder.ps1), and click `Run with PowerShell`.
- You should see something like this:
 ![image](https://user-images.githubusercontent.com/28277730/124337360-26e08300-db70-11eb-9f09-6f7ef011810e.png)
- The script will first ask for the paths to the Windows 10 and Windows 11 install ISOs, and will then ask for a target to save the output ISO to. These MUST be absolute paths, and quotation marks around the paths are recommended to avoid problems. Some good places to save the output image are in your `Desktop`, `Documents`, or even your `Downloads` folder.

  NOTE: Instead of typing the paths, you can simply drag and drop the iso files into the PowerShell window, and the path will be automatically inserted.
  ![BeJDoIrEbB](https://user-images.githubusercontent.com/28277730/124337775-47a9d800-db72-11eb-95d8-5bc1e77b1a06.gif)
  https://i.imgur.com/Gfqvit3.gif

For `DestinationImage`, you need to type the path to where you want the image to be saved. Here, you can use this as a start: `C:\Users\[USERNAME]\Desktop\output.iso`
![image](https://user-images.githubusercontent.com/28277730/124338328-2dbdc480-db75-11eb-9232-30893e10e352.png)

- After pressing Enter, the process will start. On an SSD, the process should take no more than 2 - 5 minutes.
![image](https://user-images.githubusercontent.com/28277730/124337849-b4bd6d80-db72-11eb-86dd-077971e8b2f3.png)
- Once the process finishes (if it finished successfully), the ISO will be wherever you saved it. You can test it in a virtual machine, or flash it to a USB drive, and it should just behave like a normal Windows 10 install (except it's Windows 11 😉).

![image](https://user-images.githubusercontent.com/28277730/124337888-e6363900-db72-11eb-9c2e-9903886d9af6.png)

You could also run the script directly from PowerShell without going through File Explorer, which would also give you the option to pass the `-VerboseOutput` switch, which shows the output of the processes that the script executes (`7z` and `oscdimg`). The command would look something like this:
`.\Win11-ImageBuilder.ps1 -Win10Image [Path] -Win11Image [Path] -DestinationImage [Destination] -VerboseOutput`

### ESD Conversion
If you're looking to create an ESD file to use instead of a WIM, follow these instructions.
In PowerShell, when invoking the script, use `-EditMode`. This will delay the creation of the images until you type 'continue', allowing the image to be modified.

Your command should look like this:
`.\Win11-ImageBuilder.ps1 -Win10Image "[PATH]" -Win11Image "[PATH]" -DestinationImage "[PATH]" -EditMode`

Before the image gets created, the script will pause, allowing you to convert the WIM file to ESD before the ISO gets created. Let's do that here.

When the script pauses, go to `C:\Scratch\W10\sources`, and MOVE the `install.wim` file to the repository directory. Inside the repository is a script from https://github.com/joeldidier/Simple-WIM2ESD---ESD2WIM-Converter that allows for converting WIM to ESD (and vice versa, if you so wished to do so). Run the script, and follow the instructions.
Once complete, move (or copy; your choice) the `install.esd` file from the repository directory back to `C:\Scratch\W10\sources`. Go back to the PowerShell window running this script, type "continue", and press Enter. The script will build the ISO and exit.
