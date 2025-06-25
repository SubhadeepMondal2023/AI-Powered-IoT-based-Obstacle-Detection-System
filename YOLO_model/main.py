import cv2
import numpy as np
from ultralytics import YOLO
import pyttsx3
import time
import json
import threading
import serial
import requests

class SingleSensorObstacleSystem:
    def __init__(self, serial_port='COM3'):
        # Initialize YOLO model
        print("Loading YOLO model...")
        self.model = YOLO('yolov8n.pt')
        print("YOLO model loaded successfully!")

        # Text-to-Speech
        self.tts = pyttsx3.init()
        self.tts.setProperty('rate', 150)
        print("Text-to-Speech initialized.")

        # Webcam
        self.cap = cv2.VideoCapture(0)
        if not self.cap.isOpened():
            print("Error: Could not open camera!")
            return

        # Serial Connection to ESP32
        try:
            self.arduino = serial.Serial(serial_port, 115200, timeout=1)
            time.sleep(2)
            print(f"Serial connection established on {serial_port}")
            self.serial_connected = True
        except:
            print(f"Could not connect to {serial_port}. Running camera-only mode.")
            self.serial_connected = False

        # Sensor variables
        self.sensor_distance = 0
        self.sensor_alert = "CLEAR"

        # Cooldowns
        self.last_alert_time = 0
        self.alert_cooldown = 3  # seconds
        self.last_upload_time = time.time()
        self.upload_interval = 1  # seconds

        # Start reading sensor data
        if self.serial_connected:
            self.sensor_thread = threading.Thread(target=self.read_sensor_data, daemon=True)
            self.sensor_thread.start()

        print("System started successfully!")
        self.speak("Single sensor obstacle alert system activated")

    def read_sensor_data(self):
        """Read JSON sensor data from ESP32 via Serial"""
        while self.serial_connected:
            try:
                if self.arduino.in_waiting:
                    line = self.arduino.readline().decode().strip()
                    if line.startswith('{'):
                        data = json.loads(line)
                        if 'sensor_data' in data:
                            self.sensor_distance = data['sensor_data']['center']
                            self.sensor_alert = data['sensor_data']['alert']

                            # Upload to ThingSpeak
                            now = time.time()
                            if now - self.last_upload_time > self.upload_interval:
                                self.upload_to_thingspeak(self.sensor_distance)
                                self.last_upload_time = now
            except:
                pass
            time.sleep(0.1)

    def upload_to_thingspeak(self, distance):
        """Send distance to ThingSpeak"""
        try:
            api_key = 'YNY5XL7UKY0XJF89'
            url = f'https://api.thingspeak.com/update?api_key={api_key}&field1={distance}'
            response = requests.get(url, timeout=4)
            if response.status_code == 200:
                print(f"ThingSpeak updated: {distance}cm")
            else:
                print(f"ThingSpeak error: {response.status_code}")
        except Exception as e:
            print(f"ThingSpeak upload failed: {e}")

    def speak(self, text):
        try:
            self.tts.say(text)
            self.tts.runAndWait()
        except:
            print(f"TTS Error: {text}")

    def check_sensor_alerts(self):
        current_time = time.time()
        if current_time - self.last_alert_time < self.alert_cooldown:
            return
        if self.serial_connected:
            if self.sensor_alert == "DANGER":
                self.speak("Danger ahead!")
                self.last_alert_time = current_time
            elif self.sensor_alert == "WARNING":
                self.speak("Obstacle detected!")
                self.last_alert_time = current_time

    def process_yolo_detections(self, frame):
        results = self.model(frame, verbose=False)
        height, width = frame.shape[:2]
        left_zone = width // 3
        right_zone = 2 * width // 3
        current_time = time.time()

        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                    confidence = box.conf[0].cpu().numpy()
                    class_id = int(box.cls[0].cpu().numpy())

                    if confidence > 0.5:
                        center_x = (x1 + x2) / 2
                        class_name = self.model.names[class_id]

                        # Determine zone
                        if center_x < left_zone:
                            zone = "left"
                            color = (0, 0, 255)
                        elif center_x > right_zone:
                            zone = "right"
                            color = (255, 0, 0)
                        else:
                            zone = "center"
                            color = (0, 255, 0)

                        cv2.rectangle(frame, (int(x1), int(y1)), (int(x2), int(y2)), color, 2)
                        cv2.putText(frame, f"{class_name} ({confidence:.2f})",
                                    (int(x1), int(y1 - 10)), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

                        if current_time - self.last_alert_time > self.alert_cooldown:
                            if zone == "center" and class_name in ['person', 'car', 'truck', 'bicycle']:
                                if self.sensor_distance > 0 and self.sensor_distance < 100:
                                    self.speak(f"{class_name} detected at {self.sensor_distance} centimeters")
                                else:
                                    self.speak(f"{class_name} detected ahead")
                                self.last_alert_time = current_time
        return frame

    def draw_zones_and_info(self, frame):
        height, width = frame.shape[:2]
        left_zone = width // 3
        right_zone = 2 * width // 3
        cv2.line(frame, (left_zone, 0), (left_zone, height), (255, 255, 255), 2)
        cv2.line(frame, (right_zone, 0), (right_zone, height), (255, 255, 255), 2)
        cv2.putText(frame, "LEFT", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
        cv2.putText(frame, "CENTER", (left_zone + 50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        cv2.putText(frame, "RIGHT", (right_zone + 50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)

        if self.serial_connected:
            sensor_text = f"ESP32 Sensor: {self.sensor_distance}cm - {self.sensor_alert}"
            color = (0, 255, 0)
            if self.sensor_alert == "WARNING":
                color = (0, 255, 255)
            elif self.sensor_alert == "DANGER":
                color = (0, 0, 255)
            cv2.putText(frame, sensor_text, (10, height - 20), cv2.FONT_HERSHEY_SIMPLEX, 0.7, color, 2)
        else:
            cv2.putText(frame, "Camera Only Mode - No ESP32 Connected", (10, height - 20),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (128, 128, 128), 2)
        return frame

    def run(self):
        try:
            while True:
                ret, frame = self.cap.read()
                if not ret:
                    print("Error: Could not read frame!")
                    break
                frame = cv2.flip(frame, 1)
                frame = self.process_yolo_detections(frame)
                frame = self.draw_zones_and_info(frame)
                self.check_sensor_alerts()
                cv2.imshow('Single Sensor Obstacle Alert System', frame)
                if cv2.waitKey(1) & 0xFF == ord('q'):
                    break
        except KeyboardInterrupt:
            print("\nShutting down...")
        finally:
            self.cleanup()

    def cleanup(self):
        self.cap.release()
        cv2.destroyAllWindows()
        if self.serial_connected:
            self.arduino.close()
        print("System shut down successfully!")

if __name__ == "__main__":
    print("=== Single Sensor Obstacle Alert System ===")
    import sys
    port = 'COM3'  # Change this to your actual ESP32 port
    if len(sys.argv) > 1:
        port = sys.argv[1]
    system = SingleSensorObstacleSystem(serial_port=port)
    system.run()
