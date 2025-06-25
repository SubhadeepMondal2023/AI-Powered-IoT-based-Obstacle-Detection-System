
# AI-Powered IoT-based Obstacle Detection System 🚧📱

## About
A Flutter mobile application that connects to the ThingSpeak IoT platform to monitor and visualize obstacle distance measurements in real-time. The system provides a dashboard for distance monitoring, historical data visualization, and remote data submission.

## Key Features
- **Real-time monitoring** of obstacle distances  
- **Interactive charts** for data visualization  
- **Historical data** tracking with timestamps  
- **Dark/light mode** support  
- **Responsive design** for all screen sizes  
- **Simple data submission** interface  

## Technology Stack
- **IoT Platform**: [ThingSpeak](https://thingspeak.com)  
- **Mobile Framework**: Flutter  
- **State Management**: Provider  
- **HTTP Client**: `http` package  
- **Local Storage**: Shared Preferences  
- **Internationalization**: `intl` package  


## Getting Started

1. **Clone the repository**:
```bash
git clone https://github.com/SubhadeepMondal2023/obstacle-detection.git
cd .\\flutter_app\\iot_obstacle-detection\\
```

2. **Install dependencies**:
```bash
flutter pub get
```

3. **Run the app**:
```bash
flutter run
```

## Configuration

1. Create a ThingSpeak channel at [thingspeak.com](https://thingspeak.com).
2. Update the following fields in `lib/services/thingspeak_service.dart`:

```dart
final String channelId = 'YOUR_CHANNEL_ID';
final String writeApiKey = 'YOUR_WRITE_API_KEY';
```

## API Integration

The app communicates with ThingSpeak using these endpoints:

- **Read Data**  
  ```
  GET https://api.thingspeak.com/channels/{channelId}/fields/1.json
  ```

- **Write Data**  
  ```
  POST https://api.thingspeak.com/update.json
  ```
  **Parameters:**
  - `api_key=YOUR_WRITE_API_KEY`
  - `field1=distance_value`

---

📌 *Feel free to fork or contribute to this project. Designed with ❤️ to help improve accessibility through smart IoT solutions.*
