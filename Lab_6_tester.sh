#!/usr/bin/env bash

echo "Tester for Lab 6"
echo "NOTE: channels are hard coded into tester. To change channels, update the script"


echo "Current Sensors: "
curl "http://localhost:8080/sky/cloud/9KCftkdBox8Xkgeuf3T95h/manage_sensors/sensors"
echo " ***********************************************"


echo "Testing Create sensors"
echo "Adding Test"
echo "**************************************************"

echo "current sensors"
curl "http://localhost:8080/sky/cloud/9KCftkdBox8Xkgeuf3T95h/manage_sensors/sensors"

echo ""
echo "--------------------------------------------------------"
echo "Adding Bob "

curl -X POST "http://localhost:8080/sky/event/9KCftkdBox8Xkgeuf3T95h/123/sensor/new_sensor" -d "name=Bob" | grep "Bob"

echo ""
echo "-------------------------------------------------------"
echo "Adding Joe "

curl -X POST "http://localhost:8080/sky/event/9KCftkdBox8Xkgeuf3T95h/123/sensor/new_sensor" -d "name=Joe" | grep "Joe"

sleep .5

echo ""
echo "-------------------------------------------------------"
echo "Current Sensors -- Should have Bob and Joe"
curl "http://localhost:8080/sky/cloud/9KCftkdBox8Xkgeuf3T95h/manage_sensors/sensors"
echo " ***********************************************"

sleep 3

echo ""
echo "Adding Temperature Reading over Threshold to Test"

curl -X POST "http://localhost:8080/sky/event/RCrkgymum5FQXs996crBR6/123/wovyn/heartbeat" -d @temp.json -H "Content-Type: application/json" | grep Violation

sleep 3

echo " ***********************************************"
echo ""
echo "Deleting Bob"

curl -X POST "http://localhost:8080/sky/event/9KCftkdBox8Xkgeuf3T95h/123/sensor/unneeded_sensor" -d "name=Bob" | grep "Bob"

echo "----------------------------------------------"
echo " Current Sensors - Should still have Joe"
curl "http://localhost:8080/sky/cloud/9KCftkdBox8Xkgeuf3T95h/manage_sensors/sensors"
echo " ***********************************************"

sleep 3

echo "Testing Sensor Profile"

echo "current profile"
curl "http://localhost:8080/sky/cloud/RCrkgymum5FQXs996crBR6/sensor_profile/get_profile" | grep Timbuktu

echo "-----------------------------------------------"
echo "changing profile"
curl -X POST "http://localhost:8080/sky/event/RCrkgymum5FQXs996crBR6/123/sensor/profile_updated" -d @temp2.json -H "Content-Type: application/json"

echo "--------------------------------------------------"
echo " New current profile"
curl "http://localhost:8080/sky/cloud/RCrkgymum5FQXs996crBR6/sensor_profile/get_profile" | grep Moenchengladbach

echo "  **********************************************"
echo " All Tests completed"
echo "  **********************************************"

echo " Cleaning Up"
curl -X POST "http://localhost:8080/sky/event/9KCftkdBox8Xkgeuf3T95h/123/sensor/unneeded_sensor" -d "name=Joe" 

curl -X POST "http://localhost:8080/sky/event/RCrkgymum5FQXs996crBR6/123/sensor/profile_updated" -d @clean.json -H "Content-Type: application/json"

echo ""
echo "###########################################"
echo "Done"
echo "###########################################"

