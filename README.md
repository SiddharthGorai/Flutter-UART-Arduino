# Android-Arduino UART Communication App

This project demonstrates **real-time UART serial communication** between an Android application and an Arduino device via USB. It showcases how to establish USB-based serial communication, send commands from Android to Arduino, and receive responses back from the microcontroller.

## 📱 Features

- UART communication over USB at **9600 baud rate**
- Sends a single-character command (`"A"`) from Android to Arduino
- Arduino processes the command and returns a response
- Built-in LED on Arduino turns **ON** only when `"A"` is received
- App displays a **"Communication Successful"** notification upon receiving a valid response
- Automatic navigation back to the home screen after successful communication
