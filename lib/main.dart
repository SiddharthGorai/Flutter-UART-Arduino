import 'dart:typed_data';
import 'dart:convert';
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
  bool isDeviceConnected = false;

  StringBuffer _dataBuffer = StringBuffer();

  List<String> receivedMessages = ["- Arduino is ready to receive commands."];

  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void getDevices() async {
    List<UsbDevice> availableDevices = await UsbSerial.listDevices();
    setState(() {
      devices = availableDevices;
    });

    if (devices.isEmpty) _showSnackBar("No device found");
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
    listenToPort();
    _showSnackBar("Connected to ${device.deviceName ?? "device"}.");
    setState(() {
      isDeviceConnected = true;
    });
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void sendDataToArduino() {
    String command = _controller.text;
    if (command.isNotEmpty && port != null) {
      port!.write(Uint8List.fromList(command.codeUnits));
      _showSnackBar("Command Sent: $command");
    } else {
      _showSnackBar("Command can't be empty");
    }
  }

  void listenToPort() {
    port!.inputStream?.listen((Uint8List data) {
      String incomingData = String.fromCharCodes(data);
      _dataBuffer.write(incomingData);

      if (_dataBuffer.toString().contains('\n')) {
        String completeMessage = _dataBuffer.toString().trim();

        setState(() {
          receivedMessages.add("- " + completeMessage);
        });

        _dataBuffer.clear();
      }
    }, onError: (error) {
      _showSnackBar("Error reading from port: $error");
    });
  }

  @override
  void dispose() {
    port?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      home: Scaffold(
        appBar: AppBar(title: Text('UART LED Controller')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => getDevices(),
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
                      height: 150,
                      width: 300,
                      child: ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title:
                                  Text(device.deviceName ?? "Unnamed Device"),
                              subtitle: Text(
                                "VID: ${device.vid}, PID: ${device.pid}, Name: ${device.manufacturerName}",
                              ),
                              onTap: () {
                                if (device.vid == 9025) {
                                  connectToDevice(device);
                                } else {
                                  _showSnackBar("Not an Arduino Uno.");
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
              isDeviceConnected
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30.0, vertical: 15.0),
                      child: Column(children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                style: TextStyle(fontSize: 15.0),
                                controller: _controller,
                                decoration: InputDecoration(
                                    labelText: "Enter Command",
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 5.0, horizontal: 15.0)),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: sendDataToArduino,
                              child: Text("Send"),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.0),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.black, // Set border color to black
                              width: 0.5, // Optional: thickness of the border
                            ),
                          ),
                          width: 300,
                          child: Container(
                            height: 200,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Received',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Spacer(),
                                    GestureDetector(
                                        onTap: () => {
                                        setState((){
                                          receivedMessages.clear();
                                          receivedMessages.add("- Arduino is ready to receive commands.");
                                        })

                                        },
                                        child: Text(
                                          "Clear",
                                          style: TextStyle( fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ))
                                  ],
                                ),
                                SizedBox(height: 10),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: receivedMessages.length,
                                    itemBuilder: (context, index) {
                                      return Text(
                                        receivedMessages[index],
                                        style: TextStyle(fontSize: 14),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ]))
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
