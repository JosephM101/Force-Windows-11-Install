# Force-Windows-11-Install
Creates a hybrid ISO image that houses the Windows 11 install files in a Windows 10 installer image to bypass the TPM and Secure Boot install-time requirements.

### How it works:
The tool extracts the contents of an existing Windows 10 iso to a scratch directory using `7z`. It then extracts the installation contents (install.wim) from a Windows 11 iso, deletes the install.wim file from the Windows 10 installer, and replaces it with the install.wim file from the Windows 11 iso. Finally, it uses `oscdimg` (pulled from Windows Deployment Tools) to create a new iso from the Windows 10 installer, which now contains the Windows 11 installation contents.

### Why?
The installer for Windows 11 checks for both TPM and Secure Boot, and will not install on "unsupported" processors. However, many of the devices that don't have TPM, Secure Boot, or a compatible processor, are perfectly capable of running Windows 11. This workaround will allow a user to install Windows 11 on these devices by using the Windows 10 installer, which does not have the same restrictions. It has been proven time and time again that it is possible to do this without issue, and this tool was written to simplify the process.

### Things to note
This workaround may be borked by a future Windows update where the requirements are baked into the operating system itself, in which case it just wouldn't work.

## Usage
All the tools needed to run the script properly (`7z` and `oscdimg`) are included in this repo. Just clone it, extract it, and follow the instructions below.
NOTE: You will need to allow executing scripts in PowerShell by running `Set-ExecutionPolicy Unrestricted` in an elevated PowerShell window.
It is recommended that you have at least 10-15 GB of disk space free for temporary files.

- Right-click the script (Win11-ImageBuilder.ps1), and click `Run with PowerShell`.
- You should see something like this:
 ![image](https://user-images.githubusercontent.com/28277730/124337360-26e08300-db70-11eb-9f09-6f7ef011810e.png)
- The script will first ask for the paths to the Windows 10 and Windows 11 install ISOs, and will then ask for a target to save the output ISO to. These MUST be absolute paths, and due to some current bugs, none of the paths can be in a directory like `C:\`. For best results, store everything on your Desktop or in your Documents folder.

  NOTE: Instead of typing the paths, you can simply drag and drop the iso files into the PowerShell window, and the path will be automatically inserted.
  ![BeJDoIrEbB](https://user-images.githubusercontent.com/28277730/124337775-47a9d800-db72-11eb-95d8-5bc1e77b1a06.gif)
  https://i.imgur.com/Gfqvit3.gif

For `DestinationImage`, you need to type the path to where you want the image to be saved. Here, you can use this as a start: `C:\Users\[USERNAME]\Desktop\output.iso`
![image](https://user-images.githubusercontent.com/28277730/124338328-2dbdc480-db75-11eb-9232-30893e10e352.png)

- After pressing Enter, the process will start. On an SSD, the process should take no more than 2 - 5 minutes.
![image](https://user-images.githubusercontent.com/28277730/124337849-b4bd6d80-db72-11eb-86dd-077971e8b2f3.png)
- Once the process finishes (if it finished successfully), the ISO will be wherever you saved it. You can test it in a virtual machine, or flash it to a USB drive, and it should just behave like a normal Windows 10 install (except it's Windows 11 😉).

![image](https://user-images.githubusercontent.com/28277730/124337888-e6363900-db72-11eb-9c2e-9903886d9af6.png)

You could also run the script directly from PowerShell without going through File Explorer, which would also give you the option to pass the `-VerboseOutput` switch, which shows the output of the processes that the script executes (7z and OSCDIMG). The command would look something like this:
`.\Win11-ImageBuilder.ps1 -Win10Image [Path] -Win11Image [Path] -DestinationImage [Destination] -VerboseOutput`
