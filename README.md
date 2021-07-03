# Force-Windows-11-Install
Uses a Windows 10 and Windows 11 install iso to create a hybrid image that houses the Windows 11 install files in a Windows 10 installer image to bypass the TPM and Secure Boot install-time requirements.

### How it works:
The tool extracts the contents of a Windows 10 iso to a scratch directory. It then extracts the installation contents (install.wim) from a Windows 11 iso to a scratch directory, deletes the install.wim file from the Windows 10 installer, and replaces it with the install.wim file from the Windows 11 iso. Finally, it uses `oscdimg` (from Windows Deployment Tools) to create a new iso from the Windows 10 installer, which now contains the Windows 11 installation contents.

### Why?
The installer for Windows 11 checks for both TPM and Secure Boot, and will not install on "unsupported" processors. However, many of the devices that don't have TPM, Secure Boot, or a compatible processor, are perfectly capable of running Windows 11. This workaround will allow a user to install Windows 11 on these devices by using the Windows 10 installer, which does not have the same restrictions. It has been proven time and time again that it is possible to do this without issue, and this tool was written to simplify the process.

## Usage
NOTE: You will need to allow executing scripts in PowerShell by running `Set-ExecutionPolicy Unrestricted` in an elevated PowerShell window.

- Right-click the script (Win11-ImageBuilder.ps1), and click `Run with PowerShell`.
- You should see something like this:
