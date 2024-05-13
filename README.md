# Motion Tracker

Motion Tracker is a mobile application designed for the simultaneous collection of inertial data from multiple [Movesense HR+](https://www.movesense.com/product/movesense-sensor-hr/) wearable sensors.

## Features

* **Multi-Sensor Data Collection**: Collect inertial data from up to eight Movesense HR+ sensors simultaneously, via Bluetooth Low Energy (BLE) connection.
* **User Configuration**: Insert user information directly within the application.
* **Sensor Positioning**: Automated association of sensors with their respective positions on the user's body.
* **Data Rate Control**: Adjust the data collection rate. The maximum achievable data rate using eight sensors is 13Hz (tested on Onplus 7t).
* **Activity Selection**: Choose from a predefined list of activities for data collection.

## Project Context

Motion Tracker was developed as part of [TEMPO](https://prin-tempo.github.io/), an EU-funded project aimed at monitoring the activities of hemophiliac patients. The application's primary goal is to build a comprehensive dataset of inertial data associated with various activities. This dataset, collected from multiple wearable sensors positioned at different locations on the body, will be used to evaluate the optimal sensor position(s) for activity recognition.
