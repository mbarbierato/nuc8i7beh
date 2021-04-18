/*
 * Intel ACPI Name Space Architecture for NUC8i7BEH2 device
 *
 * NOTES:
 * Added new (LPCB) sub-system (EC) device for improved Catalina detection while disabling native (H_EC) device.
 *
 * KEXT REFERENCES:
 * /System/Library/Extensions/AppleBusPowerController.kext/Contents/Info.plist
 * /System/Library/Extensions/IOUSBHostFamily.kext/Contents/Info.plist
 *
 * DefinitionBlock (AMLFileName, TableSignature, ComplianceRevision, OEMID, TableID, OEMRevision)
 *
 *    AMLFileName = Name of the AML file (string); can be a null string too;
 *    TableSignature = Signature of the AML file (DSDT or SSDT) (4-character string);
 *    ComplianceRevision = 1 or less for 32-bit arithmetic; 2 or greater for 64-bit arithmetic (8-bit unsigned integer);
 *    OEMID = ID of the Original Equipment Manufacturer of this ACPI table (6-character string);
 *    TableID = A specific identifier for the table (8-character string);
 *    OEMRevision = A revision number set by the OEM (32-bit number).
 */

DefinitionBlock ("SSDT-EC.aml", "SSDT", 2, "Clover", "FakeEC", 0x00000000)
{
    External (_SB_.PCI0.LPCB, DeviceObj)
    External (_SB_.PCI0.LPCB.H_EC, DeviceObj)

    Scope (\_SB.PCI0.LPCB)  // Intel Corporation Coffee Lake LPC Controller [8086:9d84]
    {
        Device (EC)
        {
            Name (_HID, "EC000000")

            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }

    // Do not rename EC0, H_EC, etc. to EC as these devices are incompatible with macOS
    // and may break at any time; AppleACPIEC kext must NOT load. If your motherboard
    // has an existing Embedded Controller of PNP0C09 type, use the code below to disable.

    Scope (\_SB.PCI0.LPCB.H_EC)
    {
        Method (_STA, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                Return (Zero)
            }
            Else
            {
                Return (0x0F)
            }
        }
    }

    Scope (\_SB)
    {
        Device (USBX)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                If (LEqual (Arg2, Zero))
                {
                    Return (Buffer (One) {0x03})
                }

                // The following power values are copied from the Macmini7,1 platform as defined
                // in /System/Library/Extensions/IOUSBHostFamily.kext/Contents/Info.plist

                Return (Package (0x08)
                {
                    "kUSBSleepPortCurrentLimit", 0x0834,  // 2100mA
                    "kUSBSleepPowerSupply",      0x0E10,  // 3600mA
                    "kUSBWakePortCurrentLimit",  0x0834,  // 2100mA
                    "kUSBWakePowerSupply",       0x13EC   // 5100mA
                })
            }

            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}

