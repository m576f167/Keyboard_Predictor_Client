/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Import libraries
 */
import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Global Variables
 */
Context context;
SensorManager manager;
Sensor sensor_accelerometer;
Sensor sensor_gyroscope;
AccelerometerListener listener_accelerometer;
GyroscopeListener listener_gyroscope;

float ax, ay, az;
float gx, gy, gz;
long at, gt;
boolean keyboard = false;

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Setup method
 */
void setup() {
	fullScreen();
	textFont(createFont("SansSerif", 40 * displayDensity));
	fill(0);

	context = getActivity();
	manager = (SensorManager)context.getSystemService(Context.SENSOR_SERVICE);

	// Create and register Accelerometer Listener
	sensor_accelerometer = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
	listener_accelerometer = new AccelerometerListener();
	manager.registerListener(listener_accelerometer,
				 sensor_accelerometer,
				 SensorManager.SENSOR_DELAY_FASTEST);

	// Create and register Gyroscope Listener
	sensor_gyroscope = manager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
	listener_gyroscope = new GyroscopeListener();
	manager.registerListener(listener_gyroscope,
				 sensor_gyroscope,
				 SensorManager.SENSOR_DELAY_FASTEST);
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Draw method
 */
void draw() {
	background(255);
//	text(key, width/2, height/2);
	text("aX: " + ax + "\naY: " + ay + "\naZ: " + az + "\naT: " + at + "\n\ngX: " + gx + "\ngY: " + gy + "\ngZ: " + gz + "\ngT: " + gt, 0, 0, width, height);
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Custom Classes
 */
class AccelerometerListener implements SensorEventListener {
	public void onSensorChanged(SensorEvent event) {
		ax = event.values[0];
		ay = event.values[1];
		az = event.values[2];

		at = event.timestamp;
	}
	public void onAccuracyChanged(Sensor sensor, int accuracy) {
	}
}

class GyroscopeListener implements SensorEventListener {
	public void onSensorChanged(SensorEvent event) {
		gx = event.values[0];
		gy = event.values[1];
		gz = event.values[2];

		gt = event.timestamp;
	}
	public void onAccuracyChanged(Sensor sensor, int accuracy) {
	}
}

/****************************************************/
// ================================================ //
/****************************************************/
/*
 * Interrupt Event Driven Methods
 */
void keyPressed() {
	background(200, 50, 30);  
}

void keyReleased() {
	
}

void mousePressed() {
	if (!keyboard) {
		openKeyboard();
		keyboard = true;
	} else {
		closeKeyboard();
		keyboard = false;
	}
}

public void onResume() {
	super.onResume();
	if (manager != null) {
		manager.registerListener(listener_accelerometer, sensor_accelerometer, SensorManager.SENSOR_DELAY_FASTEST);
		manager.registerListener(listener_gyroscope, sensor_gyroscope, SensorManager.SENSOR_DELAY_FASTEST);
	}
}

public void onPause() {
	super.onPause();
	if (manager != null) {
		manager.unregisterListener(listener_accelerometer);
		manager.unregisterListener(listener_gyroscope);
	}
}

/****************************************************/
// ================================================ //
/****************************************************/
