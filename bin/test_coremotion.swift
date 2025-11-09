#!/usr/bin/swift

import Foundation
import CoreMotion

let motionManager = CMMotionManager()

print("CoreMotion availability:")
print("  Accelerometer available: \(motionManager.isAccelerometerAvailable)")
print("  Gyro available: \(motionManager.isGyroAvailable)")
print("  Magnetometer available: \(motionManager.isMagnetometerAvailable)")
print("  Device motion available: \(motionManager.isDeviceMotionAvailable)")

if motionManager.isAccelerometerAvailable {
    print("\nAttempting to start accelerometer updates...")

    motionManager.accelerometerUpdateInterval = 0.1
    motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (data, error) in
        if let error = error {
            print("ERROR: \(error)")
            exit(1)
        }
        if let data = data {
            print("Acceleration: x=\(data.acceleration.x) y=\(data.acceleration.y) z=\(data.acceleration.z)")
        }
    }

    print("Waiting for data... (Move your Mac)")
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 10))

    motionManager.stopAccelerometerUpdates()
} else {
    print("\nAccelerometer NOT available via CoreMotion")
    print("This API might be iOS/watchOS only, not macOS")
}
