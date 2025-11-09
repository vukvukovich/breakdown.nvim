#!/usr/bin/swift

import Foundation
import IOKit.hid

let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerSetDeviceMatching(manager, nil)

guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
    print("Error: Could not open HID manager (need Input Monitoring permission)")
    print("System Settings → Privacy & Security → Input Monitoring → Add your terminal")
    exit(1)
}

guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
    print("Error: Could not enumerate devices")
    exit(1)
}

print("Found \(devices.count) HID devices:")
print()

for device in devices {
    if let product = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String {
        let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? Int ?? 0
        let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? Int ?? 0
        let usagePage = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsagePageKey as CFString) as? Int ?? 0
        let usage = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsageKey as CFString) as? Int ?? 0

        print("Product: \(product)")
        print("  VendorID: 0x\(String(vendorID, radix: 16))")
        print("  ProductID: 0x\(String(productID, radix: 16))")
        print("  UsagePage: 0x\(String(usagePage, radix: 16)) Usage: 0x\(String(usage, radix: 16))")

        if product.lowercased().contains("accel") {
            print("  ⭐️ ACCELEROMETER CANDIDATE")
        }
        print()
    }
}
