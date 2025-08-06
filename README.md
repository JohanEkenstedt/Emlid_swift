This is a simple project that reads data from an external Emlid Reach RX GNSS unit.

In the infoPlist you need the following:
1. Privacy - Bluetooth Always Usage Description (with a string description)
2. Supported external accessory protocols (with the string "com.emlid.nmea")

To make it work you need to.
1. Download and open the iOS app Emlid Flow from App store
2. Connect to the RX device in that app
3. Open settings and choose Bluetooth and connect to the RX-unit (There is two devices called RC, one should alreade be connected).
4. Run the Emlid_Swift app and connect to the Emlid device
![image](https://github.com/user-attachments/assets/22d26eb1-2979-4d64-ace2-7555e6d0d7f9)
