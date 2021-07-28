# Download Windows 11 from UUP Dump

First, head over to the [UUP Dump homepage.](uupdump.net)

Under "Quick Actions", click the x64 button (conveniently highlighted in blue) for "Latest Dev Channel Build".
![image](https://user-images.githubusercontent.com/28277730/127246119-23fc46df-79da-4dfb-960e-48c4dd841232.png)

That should bring you to a page that looks like the following. Click the link that appears.
![image](https://user-images.githubusercontent.com/28277730/127246192-3a3349ef-b797-41d6-8f5d-0b69b2325070.png)

On this page, click Next.

![image](https://user-images.githubusercontent.com/28277730/127246309-8bbb7c20-82d3-4884-a73e-3497f194194c.png)

You should now see a page that on the left column allows you to choose the editions of Windows you want to integrate. For this tutorial, I'm going to select "Windows Pro", but you should select the edition you have a product key for. Or, if you're devious like me, you could even use the open-source [Microsoft Activation Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts/releases) available on GitHub, and download whatever edition you want. In that case, I suggest Windows Pro, which doesn't require a Microsoft account for setup.

Anyway, choose your edition(s), and click Next.
![image](https://user-images.githubusercontent.com/28277730/127246519-f056a1f6-a677-492b-afd8-39074fe7762c.png)

Now, here is where you want to make sure that "Download and convert to ISO" is selected, and that the "Include updates" option is selected (might save us some time later), as shown here. It should already look like this, in which case you can just click "Create download package".

![image](https://user-images.githubusercontent.com/28277730/127247334-b3c87007-b4f3-432c-8f48-f7b4c4bf6ec7.png)

You should have just gotten a zip package. This contains the components we need to download Windows, and convert it to a bootable ISO.
![image](https://user-images.githubusercontent.com/28277730/127247933-bd28b551-d8e4-4740-8df1-51a646767109.png)

Head over to your `Downloads` folder (or wherever it ended up), and extract the zip file.

The extracted folder should look like the following.
![image](https://user-images.githubusercontent.com/28277730/127248352-e34e7d26-903f-4842-bab1-b39b664b94a5.png)

Double-click `uup_download_windows.cmd`, and a Command Prompt window should appear. The script is now running. The whole process can take quite a bit of time, even on a fast machine with a fast internet connection. So go ahead, grab yourself a coffee or have a snack.
![image](https://user-images.githubusercontent.com/28277730/127248598-48391e3e-1551-44ce-892c-2548b43d6072.png)

Once the process is done, you should end up with a bootable Windows 11 ISO.
![image](https://user-images.githubusercontent.com/28277730/127248859-fa87490d-2a71-40bf-bc64-bc006dbf7657.png)
