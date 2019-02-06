//
//  ViewController.swift
//  BLETest
//
//  Created by macbook on 06/02/2019.
//  Copyright © 2019 assil. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {

    @IBOutlet weak var loadingView: UILabel!
    @IBOutlet weak var dateAndTime: UILabel!
    @IBOutlet weak var temp: UILabel!
    @IBOutlet weak var macAdress: UILabel!
    @IBOutlet weak var deviceName: UILabel!
    private var services: [CBService] = []
    
    var centralManager: CBCentralManager?
    var peripheral : CBPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)

    }
    private func startScanning() {
        self.peripheral = nil
        self.loadingView.text = "Scanning BLE Devices..."
        self.centralManager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.centralManager!.isScanning {
                strongSelf.centralManager?.stopScan()
                //strongSelf.updateViewForStopScanning()
                strongSelf.loadingView.text = "Scanning stopped"
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if (central.state == .poweredOn){
            startScanning()
        }
        else{
            //updateStatusText("Bluetooth Disabled")
            self.peripheral = nil
            loadingView.text = "Bluetooth Disabled"
            UIAlertController.presentAlert(on: self, title: "Bluetooth Unavailable", message: "Please turn bluetooth on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            //assert(manufacturerData.count >= 7)
            //0d00 - TI manufacturer ID
            //Constructing 2-byte data as little endian (as TI's manufacturer ID is 000D)
            let manufactureID = UInt16(manufacturerData[0]) + UInt16(manufacturerData[1]) << 8
            print(String(format: "%04X", manufactureID)) //->000D
            if String(format: "%04X", manufactureID) == "BEBE"{
                self.centralManager?.stopScan()
                //strongSelf.updateViewForStopScanning()
                self.loadingView.text = "device found"
                if peripheral.state != .connected {
                    self.peripheral = peripheral
                    peripheral.delegate = self
                    centralManager!.connect(peripheral, options: nil)
                }
            }
            //fe - the node ID that I have given
            //let nodeID = manufacturerData[2]
            //print(String(format: "%02X", nodeID)) //->FE
            //05 - state of the node (something that remains constant
            //let state = manufacturerData[3]
            //print(String(format: "%02X", state)) //->05
            //c6f - is the sensor tag battery voltage
            //Constructing 2-byte data as big endian (as shown in the Java code)
            //let batteryVoltage = UInt16(manufacturerData[4]) << 8 + UInt16(manufacturerData[5])
            //print(String(format: "%04X", batteryVoltage)) //->0C6F
            //32- is the BLE packet counter.
            //let packetCounter = manufacturerData[6]
            //print(String(format: "%02X", packetCounter)) //->32
        }

    }
}
extension ViewController: CBPeripheralDelegate {
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMessage = "Could not connect"
        loadingView.text = "Could not connect"
        
        UIAlertController.presentAlert(on: self, title: "Error", message: errorMessage)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Peripheral connected")
        loadingView.text = "Peripheral connected"
        peripheral.discoverServices(nil)
        peripheral.delegate = self
        deviceName.text = peripheral.displayName
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if let error = error {
            print("Error connecting peripheral: \(error.localizedDescription)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
        }
        
        peripheral.services?.forEach({ (service) in

            services.append(service)
            print("service uuid : \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics(nil, for: service)
        })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering service characteristics: \(error.localizedDescription)")
        }
        if service.uuid.uuidString == "E95D6100-251D-470A-A062-FA1922DFA9A8"{
            peripheral.readValue(for: service.characteristics!.first!)
            
        }
        if service.uuid.uuidString == "1805"{
            peripheral.readValue(for: service.characteristics!.first!)
            
        }
        service.characteristics?.forEach({ characteristic in
            if let descriptors = characteristic.descriptors {
                print(descriptors)
            }
            
            print(characteristic.properties)
        })
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid.uuidString == "2A1F"{
            let temperature = UInt16(characteristic.value![0]) + UInt16(characteristic.value![1]) << 8
            print(String(format: "%04X", temperature)) //->000D
            self.temp.text = String(format: "%04X", temperature)
        }
        if characteristic.uuid.uuidString == "Current Time"{
            let temperature = UInt16(characteristic.value![0]) + UInt16(characteristic.value![1]) << 8
            print(String(format: "%04X", temperature)) //->000D
            self.temp.text = String(format: "%04X", temperature)
        }

    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid.uuidString == "2A1F"{
            let temperature = UInt16(characteristic.value![0]) + UInt16(characteristic.value![1]) << 8
            print(String(format: "%04X", temperature)) //->000D
            self.temp.text = String(format: "%04X", temperature)
        }
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        deviceName.text = peripheral.displayName
    }
}

