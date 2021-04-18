# Actively Used Files

## Current NUC BIOS Revision

BECFL357.86A.0087.2020.1209.1115

## Current Clover Version Installed

These files have been running without issues on the official Clover **r5123.1** release on [GitHub](https://github.com/CloverHackyColor/CloverBootloader/releases). Since Clover **r5129** was released, an updated configuration structure was required as Clover now expects "Quirks" to be defined; the "Quirks" section has been added at the bottom of the Clover configuration file and is _specific_ to the NUC chipset/platform. The best guide for platform "Quirks" is the [Dortania Guide to OpenCore](https://dortania.github.io/OpenCore-Install-Guide/config.plist/coffee-lake.html).

## Generating Personalised SMBIOS

It is important to generate a personalised SMBIOS using `Macmini8,1` as target model. To complete the Clover configuration section for SMBIOS (namely `MLB`, `BoardSerialNumber`, `SerialNumber` and `SmUUID` keys) it is advised to use [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS) scripts and add the generated values in the respective places in `config.plist` file.

**Important Update:** It seems that the firmware of this NUC _cannot_ provide to Clover the MAC address of the embedded network controller, thus rendering **ROM** setting `UseMacAddr0` invalid. This is evident when checking `preboot.log` in Clover via F2 on keyboard. Since a _unique_ number is required for this parameter in **RtVariables** the recommended method is to take the 12 digits from the **en0** network controler (without the colons) and convert them to [Base64](https://cryptii.com/pipes/hex-to-base64) for use as `<data>` under `<key>ROM</key>` in the Clover configuration file. Read more over at [Dortania](https://dortania.github.io/OpenCore-Post-Install/universal/iservices.html#fixing-rom).

To confirm that the injected value works persistently across reboots, one can either run in Terminal [iMessageDebug](https://mac.softpedia.com/get/System-Utilities/iMessageDebug.shtml) or the command:<br/>
`nvram -x 4D1EDE05-38C7-4A6A-9CC6-4BCCA8B38C14:ROM` and verify the output.

## Current Clover Configuration

Most of the configuration keys are set to **false** thus making a minimum needed set of patches, besides device renaming. Most notably, the following keys are used:

**Enabled ACPI/Boot/Kernel/System Options**
* `AddMCHC` (setting now moved across in **SSDT-APPLE.aml** instead)
* `DeleteUnused` (no longer used; it normally deletes legacy devices from ACPI table)
* `FixRegions` (reportedly improves LAN stability)
* `FixHeaders` (sanitizes headers to avoid kernel panics related to unprintable characters)
* `PluginType` (allows native CPU power management)
* `NeverHibernate` (improves overall sleep)
* `NoEarlyProgress` (hides any verbose pre-boot output)
* `HWPEnable` (Intel Speed Shift technology, known as Hardware P-State or Hardware Controlled Performance)
* `KernelPm` (the only patch needed in KernelAndKextPatches category)
* `PanicNoKextDump` (avoids kext-dumping in a panic situation for diagnosing problems)
* `InjectKexts` (needed as all kexts reside in EFI folder)
* `InjectSystemID` (sets the SmUUID as the 'system-id' at boot)

**Note:** User **slice** (one of the Clover developers) confirmed that `DeleteUnused` deletes such legacy devices as `CRT_`, `DVI_`, `SPKR`, `ECP_`, `LPT_`, `FDC_` that _no longer_ exist in modern motherboards, including this NUC.

**Clover Device Properties**
* Define graphics `AAPL,ig-platform-id` for Intel Iris Plus 655
* Define a compatible SATA controller (`pci8086,9d03` as Intel 10 Series Chipset)
* Define a compatible NVMe controller (optional `pci144d,a804` for Samsung NVMe SSD)
* Define audio `layout-id` for Realtek ALC235 Audio Controller
* Define a compatible Thermal Controller device (`pci8086,9d21` for device [[8086:9df9]](https://pci-ids.ucw.cz/read/PC/8086/9df9))

**Renamed Devices**
* `_DSM` to `XDSM`
* `_OSI` to `XOSI` (used in conjunction with **SSDT-XOSI.aml**)
* `_RMV` to `XRMV`
* `GFX0` to `IGPU` (although **WhateverGreen** can do that, too)
* `GLAN` to `GIGE`
* `HDAS` to `HDEF` (although **AppleALC** can do that, too)
* `HECI` to `IMEI` (although **WhateverGreen** can do that, too)
* `SAT0` to `SATA`
* `_STA` to `XSTA` in Device `H_EC` (allows disabling original `H_EC` device)
* `_SB.PCI0.RP05.PXSX` to `UPSB` (the internal USB-C device)
* `_SB.PCI0.RP09.PXSX` to `NVME` (the internal NVMe device)

## Current SSDTs Used

**SSDT-APPLE.aml**<br/>
Adds native vanilla `Device (DMAC)` and `Device (FWHD)` like a real Mac.

**SSDT-AWAC.aml**<br/>
Bypass the newer BIOS real-time clock `Device (AWAC)` that is meant as a replacement of `(RTC)`, by setting **STAS** variable to `One`. This is a much cleaner solution compared to any DSDT "hot-patching" that replaces bytes in a specific sequence.

**SSDT-EC-USBX.aml**<br/>
As this is a desktop computer despite using some mobile components, it is advised to disable device `EC`, `EC0` or `H_EC` instead of renaming it. Via a special DSDT hot-patch that allows for a custon `Method (_STA)`, the original device `(H_EC)` is disabled and a fake, needed `Device (EC)` is injected.

At the same time, needed `Device (USBX)` is injected with USB port(s) power supply and limit values, as found on a real Mac.

**SSDT-HPTE.aml**<br/>
As the presence of High Precision Event Timer `Device (HPET)` may cause performance drop(s) in certain situations, setting **HPTE** variable to `Zero` disables natively `(HPET)` in the firmware.

**SSDT-NAMES.aml**<br/>
This injects device names to otherwise unnamed IORegistry devices, simply because they are not defined in the original DSDT of the BIOS. Although not needed for a functional macOS, these are mainly done for aesthetic reasons.

**SSDT-PMCR.aml**<br/>
Injects the native vanilla `Device (PMCR)` that is accessed by the **AppleIntelPCHPMC** driver and unlocking the use of NVRAM if otherwise not already done by the BIOS.

**SSDT-SBUS.aml**<br/>
To simulate a real Mac, two sub-devices are injected in the existing SMBus device, namely `(BUS0)` and `(BUS1)`. Although these may not appear in IORegistry, they do exist in the original DSDT of a modern Mac.

**SSDT-XOSI.aml**<br/>
Combined with the needed Clover configuration patch (replacing `_OSI` with `XOSI`) this allows to simulate a Windows system running, thus getting increased compatibility in general.

## Note regarding USBPorts.kext generated with Hackintool

This NUC has four visible USB ports and they are all USB 3.1 connectors, except the two *internal* headers that are USB 2.0 connectors (and disabled in BIOS). This is why **USBPorts.kext** contains and defines both **HSxx** and **SS0x** types of ports as being of `UsbConnector` type "3" because it reflects the actual *electrical* connector.

## Update: Added Thunderbold SSDT code

**SSDT-JHL6340.aml**<br/>
Through various posted and studied Thunderbolt SSDTs on-line, this SSDT _disables_ the native `(PXSX)` device and just re-defines very basic devices using native ACPI code from an original, recent Apple computer. A new main `Device (UPSB)` is created, adding three sub-devices `(DSB0)`, `(DSB1)` and `(DSB2)` that are now visible in IORegistry. This `Device (DSB2)` contains a second hardware XHCI controller with seemingly two type "9" `UsbConnector` ports.

This new device structure, including new `(XHC2)` controller name, required a new **USBPorts.kext** to be generated via Hackintool in order to reflect this `(XHC2)` controller and ports change.

In the current configurations, a USB-C to Mini DisplayPort cable is used _without_ any issues or special BIOS tweaks. Many people report that display cables/adapters work perfectly with the single, rear USB-C port (such as USB-C to HDMI or USB-C to DisplayPort etc.).

**Note:** Total vanilla functionality _cannot_ be achieved, as the Thunderbolt firmware is not the same as the one found on Apple computers.
