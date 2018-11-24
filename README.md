# Java version manager for Windows

Sometimes you have to switch between different JVM versions or different JVM implementations. Sometimes you have to do it several times a day. Doing this manually is pretty boring and cumbersome.

Linux users have a bunch of helper scripts. Windows users have none. This script is my attempt to cope with this situation.

# How it works

The script sets up `PATH` and `JAVA_HOME` environment variables. Actual JVM switching is done using directory junctions. Directory junction in Windows is a concept similar to symbolic link in Linux.

Since there is no changes in environment variables after swithing, you are not forced to relaunch all your prograns that use java.

# Usage

## javalist.txt

First things first, you have to list your JVMs in the `javalist.txt` file using simple format:
```
jvm_alias_0   path_to_jvm_0
jvm_alias_1   path_to_jvm_1
...
jvm_alias_n   path_to_jvm_n
```

 - `jvm_alias_*` - just an identifier that you should use to select JVM.
 - `path_to_jvm_*` - pointer to JVM installation directory. Executable `path_to_jvm_*\bin\java.exe` must exist.

## javaman.bat

The `javaman.bat` script accepts these arguments:

 - `/S` - sets up user environment variables: `PATH` and `JAVA_HOME`. If you have system environment variables which point to JVM then you will have to remove such entries manually. During this step you will be prompted to modify registry entry if you want to launch java application from the explorer. After this step you should close all windows that use java and reopen them so they could use new environment variables.
 - `/L` - prints entries from `javalist.txt`.
 - `/A [alias name or index]` - prints active alias or sets a new one. You can specify alias by its name from `javalist.txt` or by its index (starting from zero) from the same file.

The script does not work in Windows XP. It works in Windows 7 and newer.

Please do not run this script with administrative privileges - this can do harm to your system.

## Example

```bat
"javaman.bat" /S
"javaman.bat" /A 0
```
