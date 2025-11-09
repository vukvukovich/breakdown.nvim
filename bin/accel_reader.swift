#!/usr/bin/swift

import Foundation
import IOKit.hid

let kAccelUsagePage: UInt32 = 0xFF00
let kAccelUsage: UInt32 = 0x0001

func main() {
    fputs("Starting accelerometer reader...\n", stderr)

    let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

    fputs("Created HID manager\n", stderr)

    IOHIDManagerSetDeviceMatching(manager, nil)

    guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
        fputs("ERROR: Could not open HID manager\n", stderr)
        exit(1)
    }

    fputs("Opened HID manager\n", stderr)

    guard let allDevices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
        fputs("ERROR: Could not enumerate HID devices\n", stderr)
        exit(1)
    }

    fputs("Found \(allDevices.count) HID devices, searching for accelerometer...\n", stderr)

    var accelDevice: IOHIDDevice? = nil
    for dev in allDevices {
        let usagePage = IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsagePageKey as CFString) as? Int ?? 0
        let usage = IOHIDDeviceGetProperty(dev, kIOHIDPrimaryUsageKey as CFString) as? Int ?? 0

        // Accelerometer: UsagePage 0xFF00 (vendor-defined), Usage 0x03
        // It's part of the keyboard/trackpad composite device
        if usagePage == 0xFF00 && usage == 0x03 {
            accelDevice = dev
            let product = IOHIDDeviceGetProperty(dev, kIOHIDProductKey as CFString) as? String ?? "Unknown"
            fputs("Found accelerometer: \(product)\n", stderr)
            break
        }
    }

    guard let device = accelDevice else {
        fputs("ERROR: No accelerometer device found (FF00:03)\n", stderr)
        exit(1)
    }

    fputs("Opening device...\n", stderr)

    // Open the device
    let openResult = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
    fputs("Open result: \(openResult) (success=\(kIOReturnSuccess))\n", stderr)

    guard openResult == kIOReturnSuccess else {
        fputs("ERROR: Could not open device (error: 0x\(String(openResult, radix: 16)))\n", stderr)
        fputs("Likely needs Input Monitoring permission\n", stderr)
        exit(1)
    }

    fputs("Device opened successfully!\n", stderr)

    var lastReading: (x: Double, y: Double, z: Double) = (0, 0, 0)

    // Schedule device on run loop (required for async callbacks)
    IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    fputs("Scheduled device on run loop\n", stderr)

    fputs("Registering value callback...\n", stderr)

    let callback: IOHIDValueCallback = { context, result, sender, value in
        let element = IOHIDValueGetElement(value)
        let usagePage = IOHIDElementGetUsagePage(element)
        let usage = IOHIDElementGetUsage(element)
        let intValue = IOHIDValueGetIntegerValue(value)

        // Print all values to see what's available
        fputs("Value: usagePage=0x\(String(usagePage, radix: 16)) usage=0x\(String(usage, radix: 16)) value=\(intValue)\n", stderr)
    }

    withUnsafeMutablePointer(to: &lastReading) { ptr in
        IOHIDDeviceRegisterInputValueCallback(device, callback, UnsafeMutableRawPointer(ptr))

        fputs("Value callback registered. Waiting for data...\n", stderr)
        fputs("Try moving or tapping your Mac. Press Ctrl+C to exit.\n", stderr)

        RunLoop.current.run()
    }
}

main()
