import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<UsbDevice> devices = [];
  UsbPort? port;

  void getDevices() async {
    List<UsbDevice> availableDevices = await UsbSerial.listDevices();
    setState(() {
      devices = availableDevices;
    });
    _showSnackBar("Found ${availableDevices.length} device(s).");
  }

  void connectToDevice(UsbDevice device) async {
    port = await device.create();
    if (port == null) {
      _showSnackBar("Failed to create port.");
      return;
    }

    bool opened = await port!.open();
    if (!opened) {
      _showSnackBar("Failed to open port.");
      return;
    }

    await port!.setDTR(true);
    await port!.setRTS(true);
    await port!.setPortParameters(
      9600, // baud rate
      UsbPort.DATABITS_8,
      UsbPort.STOPBITS_1,
      UsbPort.PARITY_NONE,
    );

    _showSnackBar("Connected to ${device.deviceName ?? "device"}.");
  }

  void _showSnackBar(String message) {
    final context = this.context;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    port?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('UART LED Controller')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: getDevices,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  "List USB Devices",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              devices.isEmpty
                  ? Text("No devices found.")
                  : Container(
                height: 200,
                width: 300,
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.deviceName ?? "Unnamed Device"),
                      subtitle: Text(
                          "VID: ${device.vid}, PID: ${device.pid}, Name: ${device.manufacturerName}"),
                      onTap: () {
                        if (device.vid == 9025) {
                          connectToDevice(device);
                        } else {
                          _showSnackBar("Not an Arduino Uno.");
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
