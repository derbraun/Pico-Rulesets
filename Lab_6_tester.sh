#!/usr/bin/env bash

echo "Tester for Lab 6"
echo "NOTE: channels are hard coded into tester. To change channels, update the script"


echo "Current Sensors: "
curl "http://localhost:8080/sky/cloud/9KCftkdBox8Xkgeuf3T95h/manage_sensors/sensors"
echo " ***********************************************"


echo "Testing Create sensors"
echo "Adding Test"

curl "http://localhost:8080/sky/cloud/9KCftkdBox8Xkgeuf3T95h/manage_sensors/sensors"

echo "Adding Bob "

curl -X POST "http://localhost:8080/sky/event/9KCftkdBox8Xkgeuf3T95h/123/sensor/new_sensor" -d "name=Bob" | grep "Bob"


echo "Adding Joe "

curl -X POST "http://localhost:8080/sky/event/9KCftkdBox8Xkgeuf3T95h/123/sensor/new_sensor" -d "name=Joe" | grep "Joe"


curl "http://localhost:8080/sky/cloud/9KCftkdBox8Xkgeuf3T95h/manage_sensors/sensors"
echo " ***********************************************"

echo "Adding Temperature Reading over Threshold to Test"

curl -X POST "http://localhost:8080/sky/event/RCrkgymum5FQXs9BR6/123/wovyn/heartbeat" -d @temp.json -H "Content-Type: application/json" | grep Violation

echo " ***********************************************"

echo "Deleting Bob"

curl -X POST "http://localhost:8080/sky/event/9KCftkdBox8Xkgeuf3T95h/123/sensor/unneeded_sensor" -d "name=Bob" | grep "Bob"

curl "http://localhost:8080/sky/cloud/9KCftkdBox8Xkgeuf3T95h/manage_sensors/sensors"
echo " ***********************************************"

echo "Testing Sensor Profile"

curl "http://localhost:8080/sky/cloud/RCrkgymum5FQXs996crBR6/sensor_profile/get_profile" | grep Timbuktu

curl -X POST "http://localhost:8080/sky/event/RCrkgymum5FQXs9BR6/123/wovyn/heartbeat" -d @temp2.json -H "Content-Type: application/json"


curl "http://localhost:8080/sky/cloud/RCrkgymum5FQXs996crBR6/sensor_profile/get_profile" | grep Moenchengladbach

echo "  **********************************************"
echo " All Tests completed"
echo "  **********************************************"
