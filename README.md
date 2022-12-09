# OpenComputers-BigReactor-Passive-Monitor
 OpenComputers program to run a PID loop to control a passive BigReactors/ExtremeReactors reactor

## Usage
 Name an OpenComputers hard disk "rc_hdd" (or change the name in `autorun.lua`) then copy the contents of the `src` folder into it. Use in a computer with a tier 2+ graphics card & screen connected to a passive reactor's computer port. The program will show larger graphs with longer histories on larger displays.
 
 To set the target buffer level and PID parameters, edit the `main` function in `monitor.lua`. Left to right, the parameters are the target buffer level (0 - 1), overshoot factor (to avoid topping out), Kp, Ki, and Kd.
