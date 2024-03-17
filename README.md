# multi_sensor_collector

Flutter app that allows you to connect up to 8 Movesense sensors and retrieve inertial data.

The user has to configure the sensors based on the position in which they are placed on the body.

The allowed positions are:
* chest
* left wrist
* right wrist
* belt
* left pocket
* right pocket
* left ankle
* right ankle

## Animation

To make the application more interactive, an animated model that reflects the movements of the user has bees added. It is implemented in OpenGLES and it makes use of a library modified from [TheThinMatrix's OpenGL-Animation](https://github.com/TheThinMatrix/OpenGL-Animation).

It currently only shows leg movement corresponding to the sensors positioned on the ankles.
