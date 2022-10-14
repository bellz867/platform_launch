#!/bin/bash
# Grand launcher for demo...

######## INITIALIZATION ########

NAME="Main Terminal"
echo -en "\033]0;$NAME\a"

# Description
echo "This script will launch all specified bebops and turtlebots simultaneously."

# Get master key (password)
echo "Please enter the master password (for connection login):"
read master_key

echo "Master password accepted."

# Set enabled bebops/turtlebots

bebopID_array=("swordfish2" "bebop1" "bebop2" "bebop3" "bebop4")
numBebop=${#bebopID_array[@]}

turtlebotID_array=("turtlebot0" "turtlebot1" "turtlebot3")
numTurtlebot=${#turtlebotID_array[@]}


echo "Targeting ${numBebop} bebop(s): ${bebopID_array[@]}"
echo "Target ${numTurtlebot} turtlebot(s): ${turtlebotID_array[@]}"


######## BEBOP CONNECTION ########

# Generate command to ssh into bebop computers and connect to bebops
for ((i=0; i<$numBebop; i++)); do
  #cmdcon[i]="echo \"$master_key\" | sudo -S service network-manager stop; sudo ifconfig asus1 up; sudo iwconfig asus1 essid ${bebopID_array[i]}_5G; sudo dhclient asus1 -v && exit"
  cmdcon[i]="echo \"$master_key\" | sudo -S service network-manager restart && exit"	  
  cmdsshopt[i]="'${cmdcon[i]}; bash'" # ssh options
  cmdssh[i]="sshpass -p $master_key ssh -o StrictHostKeyChecking=no ${bebopID_array[i]}@${bebopID_array[i]} ${cmdsshopt[i]}; exit 0" # ssh command
  options+=(--tab -e "bash -c \"${cmdssh[i]} ; bash\"") # terminal command
done

# For debug
# echo "${options[@]}"

# Execute command in a new terminal (for bebops)
gnome-terminal "${options[@]}"

# Clear command
unset options


echo "Continue? (Are all bebops connected?):"
read cin

######## ROSCORE ########

# Launch roscore on ncrVision (main workstation)
gnome-terminal --tab -e "bash -c \"roscore; bash\"" --tab 

# Wait for roscore to finish startup
sleep 1.5

######## RVIZ ########

# Launch RVIZ on ncrVision (main workstation)
gnome-terminal --tab -e "bash -c \"rviz; bash\"" --tab

######## Mocap ########

# Launch mocap on ncrVision (main workstation)
gnome-terminal --tab -e "bash -c \"roslaunch mocap_optitrack mocap.launch; bash\"" --tab


######## BEBOP ########
cmdlaunch[0]="roslaunch bebop_driver bebop_node.launch namespace:=/bebop0" # Launch bebops
cmdsshopt[0]="'${cmdlaunch[0]}; bash'" # ssh options
cmdssh[0]="sshpass -p $master_key ssh -o StrictHostKeyChecking=no -t ${bebopID_array[0]}@${bebopID_array[0]} ${cmdsshopt[0]}" # ssh command
options+=(--tab -e "bash -c \"${cmdssh[0]} ; bash\"") # terminal command
# Generate command to ssh into bebop computers and launch the bebops
for ((i=1; i < numBebop; i++)); do
    cmdlaunch[i]="roslaunch bebop_driver bebop_node.launch namespace:=${bebopID_array[i]}" # Launch bebops
    cmdsshopt[i]="'${cmdlaunch[i]}; bash'" # ssh options
    cmdssh[i]="sshpass -p $master_key ssh -o StrictHostKeyChecking=no -t ${bebopID_array[i]}@${bebopID_array[i]} ${cmdsshopt[i]}" # ssh command
    options+=(--tab -e "bash -c \"${cmdssh[i]} ; bash\"") # terminal command
done

# For debug
# echo "${options[@]}"

# Execute command in a new terminal (for bebops)
gnome-terminal "${options[@]}"

# Clear command
unset options

######## TURTLEBOT ########

# Generate command to ssh into turtlebot computers and launch the turtlebots
for ((i=0; i<$numTurtlebot; i++)); do
  cmdsetup[i]="export ROS_NAMESPACE=${turtlebotID_array[i]}" # Set namespace for each turtlebot
  cmdlaunch[i]="roslaunch execTurtle.launch" # Launch turtlebots
  cmdsshopt[i]="'${cmdsetup[i]}; ${cmdlaunch[i]}; bash'" # ssh options
  cmdssh[i]="sshpass -p $master_key ssh -o StrictHostKeyChecking=no -t ${turtlebotID_array[i]}@${turtlebotID_array[i]} ${cmdsshopt[i]}" # ssh command
  options+=(--tab -e "bash -c \"${cmdssh[i]} ; bash\"") # terminal command
done

# For debug
# echo "${options[@]}"

# Execute command in a new terminal (for turtlebots)
gnome-terminal "${options[@]}"

# Clear command
unset options

######## ARBITER ########

# Generate command to launch arbiter

cmdbebops+="\"${bebopID_array[0]}\""

for ((i=1; i<$numBebop; i++)); do

cmdbebops+=",\"${bebopID_array[i]}\""

done


cmdturtlebots+="\"${turtlebotID_array[0]}\""

for ((i=1; i<$numTurtlebot; i++)); do

cmdturtlebots+=",\"${turtlebotID_array[i]}\""

done


echo "Baseline startup has finished cleanly."
echo "Which demo to launch?"
echo "[0] Arbitor (baseline controller only)"
echo "[1] Ballet"
echo "[2] Turtle enclose (aka Vice demo)"
echo "[3] Simple follower (aka Oak Hall demo)"
echo "[4] Turtle swithed vision (trajectory tracking)"
read demo_case

case "$demo_case" in
	"0") echo "Starting Arbitor: [0] Arbitor"; source demo_sh/arbitor.sh $master_key $bebopID_array
	;;
	"1") echo "Starting demo: [1] Ballet"; source demo_sh/bebop_ballet.sh $master_key; echo $?
	;;	
	"2") echo "Starting demo: [2] Turtle enclose"; source demo_sh/turtle_enclose.sh $master_key
	;;	
	"3") echo "Starting demo: [3] Simple follower"; source demo_sh/simple_follower.sh $master_key $bebopID_array
	;;
	"4") echo "Starting demo: [4] Turtle switched vision"; source demo_sh/turtle_sw_vis.sh $master_key $turtlebotID_array
	;;		
esac
